# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'section_header'
class ApplicationController < ActionController::Base
  include AudienceLabeling
  include FocusAssignment
  include MostRecentSectionHandling
  include ::GradebookV2Helper

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # The current version of JWPlayer sends a request when the play action is finished
  # generating multiple silent errors in M3
  # (i.e. The error is neither visible nor blocker for the user).
  before_action :ignore_requests_with_busted_in_params
  before_action :set_time_zone
  before_action :set_fall_back_user

  before_action :handle_feature_toggle

  helper_method :current_user
  helper_method :any_courses_in_current_program?
  helper_method :chat_presenter
  helper_method :return_bar_presenter

  PRIVACY_POLICY_URL = 'https://vistahigherlearning.com/privacy-policy'.freeze

  def privacy_policy_url
    PRIVACY_POLICY_URL
  end
  helper_method :privacy_policy_url

  def chat_presenter
    @chat_presenter ||= ChatPresenter.new(permit)
  end

  def return_bar_presenter
    @return_bar_presenter ||= ReturnBarPresenter.new(current_user, current_focus, current_program)
  end

  def instructor_label
    @instructor_label ||= audience_label(current_program&.audience, :instructor)
  end
  helper_method :instructor_label

  # When a Rack::Timeout occurs in the middle of a database query, it can
  # leave the db connection in a broken state. Subsequent requests handled
  # by the same process attempt to use this connection and get error messages
  # like: Mysql2::Error: This connection is still waiting for a result, try
  # again once you have the result.
  # Reference: https://github.com/brianmario/mysql2/issues/99
  # Versions of mysql2 gem higher than current 0.3.19 may fix this. See:
  # https://github.com/brianmario/mysql2/pull/592
  # https://github.com/brianmario/mysql2/pull/751
  # https://github.com/brianmario/mysql2/pull/811
  rescue_from(Rack::Timeout::RequestTimeoutException, with: :reset_db_connection)

  BLOCKED_SUPERSITE_JUNIOR_MESSAGE = 'This feature is not available for your program.'.freeze

  # Threshold used to check if it's necessary to increase the TTL of a pubnub auth token.
  CHECK_THRESHOLD = 3.hours.to_i.freeze

  SAFE_SCHEMES = [nil, 'http', 'https'].freeze
  INVALID_SCHEME_ERROR = 'URL cannot have a protocol other than http or https'.freeze
  protected def reset_db_connection(exception)
    ActiveRecord::Base.connection.reset!
    raise(exception)
  end

  # Rails url helper methods require a hash with symbol keys. When passing an
  # instance of ActionController::Parameters that's not permitted, an error is
  # raised: Attempting to generate a URL from non-sanitized request parameters!
  # With permitted params, the string keys can cause unexpected results.
  def helper_params
    @helper_params ||= params.permit(
      :activities_strand_or_day,
      :activity_id,
      :all_lesson_or_week,
      :category_id,
      :course_id,
      :id,
      :lesson_or_due_date,
      :program_id,
      :section_id
    ).to_h.symbolize_keys
  end
  helper_method :helper_params

  def safe_local_uri(url)
    safe_uri = URI.parse(url)
    safe_uri.try(:request_uri) || safe_uri.to_s
  end
  helper_method :safe_local_uri

  def pubnub_token
    (pubnub_token_from_cache || {}).to_json
  end
  helper_method :pubnub_token

  def chat_client_roster
    courses = if current_user
                current_user.pubnub_client_roster[:roster][:groups]
              end

    { courses: courses }.to_json
  end
  helper_method :chat_client_roster

  def chat_grants_roster
    current_user.pubnub_grants_roster.to_json
  end
  helper_method :chat_grants_roster

  def supersite_junior?
    current_program&.supersite_junior? ||
      (params && params[:preview_theme] == 'junior')
  end
  helper_method :supersite_junior?

  def student_active_sections_for_program
    return [] unless current_user&.is_student?

    current_user.active_sections
                .select { |section| section.program == current_program }
                .sort_by { |section| [section.course, section.name] }
                .map { |section| { course: section.course, section: } }
  end
  helper_method :student_active_sections_for_program

  def spr?
    current_program&.spr? ||
      (params && params[:preview_theme] == 'spr')
  end
  helper_method :spr?

  def ssjr_student?
    supersite_junior? && current_user_is_student?
  end
  helper_method :ssjr_student?

  def ssjr_instructor?
    supersite_junior? && current_user_is_instructor?
  end
  helper_method :ssjr_instructor?

  private def pubnub_token_from_cache
    # If we remove pubnub_auth_keepalive permanently, delete the pending spec
    # in spec/controllers/application_controller_spec.rb
    # pubnub_auth_keepalive
    pubnub_auth_cache.get_auth(group_membership_key) if chat_enabled? || svr_activity_page?
  end

  private def svr_activity_page?
    return false unless defined?(@activity)

    @activity.solo_video_recording_or_included_in_multipart_activity?
  end

  private def pubnub_auth_cache
    @pubnub_auth_cache ||= VhlChat::AuthCache.new(M3::Application.config.chat_auth_cache)
  end

  def pubnub_auth_keepalive
    auth_ttl = pubnub_auth_cache.ttl(group_membership_key)

    # We check if auth_ttl is greater than 0 because it can be -1 if the key does not have a TTL
    # or it can be -2 if the key does not have a value in redis.
    if auth_ttl > 0 && auth_ttl <= CHECK_THRESHOLD
      pubnub_auth_cache.extend_auth(
        group_membership_key,
        VhlChat::AuthCache::DEFAULT_EXPIRATION
      )
    end
  end

  def assign_lossless_auth_token
    return unless current_user

    policy = Lossless::Policy.new(group_membership_key, current_user)
    if policy.token
      @lossless_auth_token = policy.token
    else
      flash.now[:error] = 'An error occurred, preventing audio recordings ' \
                          'from being saved or played.'
    end
  end

  # GroupMembershipKey generates a sha256-based key which is used as the
  # key for the chat auth cache data and for lossless audio-recording
  # auth policies. This key will change for an instructor any time their
  # section_instructor records change. For a student, the key changes when
  # there is a change in enrollments. When the key changes, chat cache
  # retrieval will miss and new grants will need to be fetched from pubnub.
  # The old key will expire on its own so there is no cleanup needed.
  private def group_membership_key
    @group_membership_key ||= GroupMembershipKey.new(current_user).key
  end

  private def chat_enabled?
    return @chat_enabled if defined?(@chat_enabled)
    @chat_enabled = current_user && (current_user.instructor? || chat_enabled_for_student?)
  end

  private def chat_enabled_for_student?
    current_section.non_zero? && current_section.course.chat_enabled?
  end

  private def permit
    @permit ||= VhlChat::Permission.new(current_user,
                                        current_program,
                                        access_guardian,
                                        current_section)
  end

  # These two types could be hiding timeout exceptions because in some places
  # Rails rescues from any exception and raises a new instance of one of these
  # expection classes, with the original exception class prepended to the message.
  # See lib/active_record/connection_adapters/abstract_adapter.rb line 274
  rescue_from(ActiveRecord::StatementInvalid,
              ActionView::Template::Error,
              with: :maybe_reset_db_connection)

  protected def maybe_reset_db_connection(exception)
    if exception.message.start_with?('Rack::Timeout')
      reset_db_connection(exception)
    else
      raise(exception)
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to "/403"
  end

  private def ignore_requests_with_busted_in_params
    head :not_found if params.key?(:busted)
  end

  def initialize
    super
    @show_tech_support_link = true
  end

  def get_from_session_and_delete(key)
    value = session[key]
    session.delete(key) if value
    return value
  end

  require 'ipaddr'

  def handle_unverified_request
    super
    csrf_params = {
      parameters: {
        method: request.method,
        submitted_auth_token: submitted_auth_token,
        current_user_id: current_user&.id,
        expected_auth_token: form_authenticity_token
      }.merge(params.to_unsafe_hash),
      cgi_data: ENV.to_hash
    }
    Rails.logger.debug("CSRF_PARAMS: #{csrf_params}")
  end

  def submitted_auth_token
    params[request_forgery_protection_token] || request.headers['X-CSRF-Token']
  end
  private :submitted_auth_token

  def recording_configuration_instance
    # We want to use a RecordingConfiguration instance per request in order to
    # prevent creation of arc instances with different server_host values.
    # (that will cause priming connection code to fail)
    @recording_configuration ||= RecordingConfiguration.new
  end
  helper_method :recording_configuration_instance

  def error_messages_for_modal(object, options = {})
    return '' if object.errors.empty?

    error_tag = options[:error_tag] || 'p'
    error_class = options[:error_class] || 'error_for_modal'
    block_tag = options[:block_tag] || 'div'
    block_class = options[:block_class] || 'modal_errors'
    fields_id_prefix = object.class.to_s.underscore
    fields_with_errors = []
    wrapped_messages = []
    error_template =
      '<%<error_tag>s class="%<error_class>s  %<error_js_class>s">%<error_message>s</%<error_tag>s>'

    object.errors.each do |error|
      field_with_error = map_error_attr_to_form_field("#{fields_id_prefix}_#{error.attribute}")
      error_message = error.message
      fields_with_errors << field_with_error
      error_js_class = "js-error-#{field_with_error}"
      wrapped_messages << format(
        error_template, { error_tag:, error_class:, error_js_class:, error_message: }
      )
    end

    errors_message_block = "<#{block_tag} class=\"#{block_class}\">#{wrapped_messages.join}</#{block_tag}>"
    { fields_with_errors:, errors_message_block: }.to_json.to_s
  end

  private def map_error_attr_to_form_field(field_with_error)
    case field_with_error
    when 'activity_assignment_base'
      'category'
    when 'activity_assignment_due_date'
      'due_date'
    when 'activity_assignment_assigned_assessment_detail.time_limit'
      'custom_time_limit_errors'
    when 'activity_assignment_show_at'
      'assessment_availability_errors'
    else
      field_with_error
    end
  end

  def assistant_role_policy
    return @assistant_role_policy if defined?(@assistant_role_policy)

    focus = current_focus || Focus.new(current_user, current_program, session[:focus])
    @assistant_role_policy = AssistantRolePolicy.new(focus, current_user)
  end
  helper_method :assistant_role_policy

  def course_create_edit_policy
    @course_create_edit_policy ||= Policy::Course::CreateEdit.new(current_user)
  end
  helper_method :course_create_edit_policy

  def ensure_safe_protocol(url)
    uri = URI(url)
    raise ArgumentError, INVALID_SCHEME_ERROR unless uri.scheme.in?(SAFE_SCHEMES)
    url
  end
  helper_method :ensure_safe_protocol

  def script_tag_sanitizer(content)
    # remove all script tags and content within
    content.gsub(%r{<script[\d\D]*?>[\d\D]*?<\/script>}, '')
  end
  helper_method :script_tag_sanitizer

  private

  def block_demo_users
    if current_user && current_user.demo_only?
      render 'home/not_available_in_demo'
      return false
    end
  end

  def block_clever_rostering_users
    if current_user.rostering?
      # Return to the roster page,
      #   which now should not include the add/drop-student controls.
      redirect_to(roster_link)
    end
  end

  def require_program_access
    if current_user.student? && archived_section?
      set_ua_home_warning('The section you are trying to view is no longer available.')
      redirect_to(ua_home_path)
    elsif current_user.student? && current_program.nil?
      if current_user.cartridge?
        redirect_to_access_denied_activity_view
      else
        raise ::ActionController::RoutingError, 'No valid program specified.'
      end
    elsif current_program && !current_user.has_current_access_to?(current_program)
      if current_user.cartridge?
        redirect_to_access_denied_activity_view
      else
        redirect_to "#{UA_URL}/access_problem/#{current_program.id}"
      end
    end
  end

  private def set_ua_home_warning(message)
    cookies[:ua_home_warning] = M3CookieConfig.options.merge(
      expires: 10.seconds.from_now,
      value: message
    )
  end

  private def archived_section?
    Section.unscoped.where(id: current_section_id, is_archived: true).exists?
  end

  def current_protocol
    request.ssl? ? 'https' : 'http'
  end

  def warn_insufficient_course_access
    if current_user.student? &&
       current_section &&
       !current_section.zero? &&
       !current_user.sufficient_access_for_course?(current_section)
      flash.now[:warning] = "You don't have all the required access to complete this course."
    end
  end

  def current_section_id
    return @current_section_id if defined?(@current_section_id) && @current_section_id.present?

    if params[:section_id].blank?
      if current_focus
        if current_focus.sections.empty?
          @current_section_id = '0'
        else
          @current_section_id = current_focus.section.id
        end
      else
        # note: method reference to current_program might invoke current_program in an infinite
        # recursive loop, so we're checking the params instead.
        if current_user && current_user.student? && params[:program_id].present?
          @current_section_id = (
            most_recent_section_id ||
            current_user.current_section_in_program(current_program).try(:id) ||
            '0'
          )
        else
          @current_section_id = '0'
        end
      end
    else
      @current_section_id = params[:section_id]
    end

    return @current_section_id
  end
  helper_method :current_section_id

  def current_section
    @current_section ||= begin
      if current_section_id == '0'
        Section.section_zero
      elsif @in_institution_admin
        Section.including_enterprise.find_by(id: current_section_id)
      else
        Section.find_by(id: current_section_id)
      end
    end
  end
  helper_method :current_section

  def current_program
    @current_program ||= if (params[:program_id].blank? && current_section)
      current_section.program
    else
      Program.find_by_id(params[:program_id])
    end
  end
  helper_method :current_program

  def accent_bar_enabled?
    if current_program.nil?
      return false
    end
    AccentBar.characters(current_program.language_code).present?
  end
  helper_method :accent_bar_enabled?

  def vista_online_learning?
    !!current_program&.vista_online_learning?
  end
  helper_method :vista_online_learning?

  def theme_classes
    if ssjr_student?
      ' t-supersites-jr  t-supersites-jr--student'
    elsif ssjr_instructor?
      ' t-supersites  t-supersites-jr  t-supersites-jr--instructor'
    elsif spr?
      ' t-espirales'
    elsif vista_online_learning?
      ' vol  t-vol'
    else
      ' t-supersites'
    end
  end
  helper_method :theme_classes

  def theme_root
    if ssjr_student? || ssjr_instructor?
      'supersite-jr'
    elsif vista_online_learning?
      'vol'
    else
      'supersite'
    end
  end
  helper_method :theme_root

  def block_maestro_2(section = nil, program = nil)
    is_maestro2_section = ( section && section.program && section.program.maestro2? )
    is_maestro2_program = ( program && program.maestro2? )

    if is_maestro2_section || is_maestro2_program
      raise ::ActionController::RoutingError.new("The page you are trying to access is not valid for your course or program.")
    end
  end

  def compare_redemption_dates(a, b)
    (a and b) ? b <=> a : (a ? -1 : 1)
  end

  def logout(user)
    reset_session
  end

  def current_user_session
    session
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.where(username: session[:cas_user]).first
  end

  private def current_user_with_schools
    return @current_user_with_schools if defined?(@current_user_with_schools)

    @current_user_with_schools = current_user&.tap do |user|
      schools = user.schools
      schools.load unless schools.loaded?
    end
  end
  helper_method :current_user_with_schools

  def has_grace_period?
    access_guardian.has_grace_period?
  end

  def access_guardian
    @access_guardian ||= AccessGuardian.new(current_user, current_program)
  end
  helper_method :access_guardian

  def current_user_is_institution_admin?
    current_user.institution_admin?
  end

  def current_user_is_instructor?
    current_user.instructor?
  end

  def current_user_is_student?
    current_user.student?
  end

  def inactivity_timeout
    @inactivity_timeout ||= InactivityTimeout.new(
      session: persistent_session,
      user: current_user,
      school: current_section&.course&.school || current_focus&.course&.school
    )
  end
  helper_method :inactivity_timeout

  def persistent_session
    return @persistent_session if defined?(@persistent_session)
    @persistent_session = (session && session[:session_id] && Session.where(session_id: session[:session_id]).first)
  end
  private :persistent_session

  def require_user
    if restrict_cartridge_user?
      if persistent_session && persistent_session.valid?
        store_most_recent_section
        persistent_session.lazy_touch
        return true
      else
        flash[:notice] = LOGIN_REQUIRED_MESSAGE
        persistent_session.delete if persistent_session
        reset_session
        redirect_to "#{ defined?(UA_URL) ? UA_URL : 'https://www.vhlcentral.com' }/logout"
      end
    else
      return unless CASClient::Frameworks::Rails::Filter.filter(self) # we either render or redirect here, so bail out!
      @current_user = User.find_by_username(session[:cas_user])

      if restrict_cartridge_user?
        store_most_recent_section
        Session.log(current_user, session, request)
        set_fall_back_user
      elsif current_user&.cartridge?
        redirect_to '/403'
      else
        store_location
        flash[:notice] = LOGIN_REQUIRED_MESSAGE
        redirect_to ua_home_path
      end
    end
  end

  private def restrict_cartridge_user?
    current_user && !current_user.cartridge?
  end

  INSTRUCTOR_ACCESS_REQUIRED_MESSAGE = 'You must have Instructor access to ' \
                                       'view the requested page.'.freeze

  def require_instructor
    unless current_user.instructor?
      if request.xhr? || request.format.json?
        render plain: 'User must have Instructor access.', status: 401
      else
        flash[:error] = INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
        redirect_to_best_default_path
      end
    end
  end

  def require_institution_admin
    return true if current_user.institution_admin?

    if request.xhr?
      render :text => 'User must have Instituion Admin access.', :status => 401
    else
      flash[:error] = 'You must have Institution Admin access to view the requested page.'
      redirect_to_warning_message
    end
  end

  def require_data_admin
    return true if current_user.data_admin?

    if request.xhr?
      render :text => 'You must have Data Admin access.', :status => 401
    else
      flash[:error] = 'You must have Data Admin access to view the requested page.'
      redirect_to_warning_message
    end
  end

  def require_enterprise_admin
    return true if current_user.enterprise_admin?

    if request.xhr?
      render :text => 'User must have Enterprise Admin access.', :status => 401
    else
      flash[:error] = 'You must have Enterprise Admin access to view the requested page.'
      redirect_to_warning_message
    end
  end

  def require_student
    return require_user unless current_user
    unless current_user.student?
      if request.xhr?
        render plain: "User must have Student access.", status: 401
      else
        flash[:error] = 'You must have Student access to view the requested page.'
        redirect_to_best_default_path
      end
    end
  end

  def require_developer
    current_user&.developer?
  end

  def require_lti_rostering_user
    current_user&.lti_rostering?
  end

  def redirect_if_assistant
    redirect_to_instructor_dashboard if assistant_role_policy.is_assistant?
  end

  private def redirect_to_warning_message
    render(
      file: Rails.root.join('public', '401.html.erb'),
      layout: 'music_v1/default',
      status: 401,
      formats: [:html]
    )
  end

  def redirect_to_instructor_dashboard
    if request.xhr?
      render :json => {fields_with_errors: [], errors_message_block: 'User must have Instructor access.'}, :status => 401
    else
      flash[:error] = INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
      redirect_to instructor_dashboard_path(current_program)
    end
  end
  private :redirect_to_instructor_dashboard


  def require_instructor_or_grader
    unless current_user.instructor? || current_user.grader?
      if request.xhr?
        render plain: "User must have Instructor or Grader access.", status: 401
      else
        flash[:error] = INSTRUCTOR_ACCESS_REQUIRED_MESSAGE
        redirect_to ua_home_path
      end
    end
  end

  def ajax_only
    unless request.xhr?
      flash[:error] = 'You initiated an ajax only feature.'
      redirect_to '/'
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to '/'
      return false
    end
  end

  def require_open_registration_window
    unless current_user && current_user.is_registration_window_open
      flash[:notice] = "Please use the links in the my programs menu to redeem a new code or to add a school/course."
      redirect_to '/'
      return false
    end
    return true
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    unless session[:return_to].nil?
      target = session[:return_to]
      session[:return_to] = nil
    end
    redirect_to(target || default)
  end

  def create_session_tag
    seed = "#{request.env['HTTP_USER_AGENT']}#{request.env['REMOTE_ADDR']}#{Time.zone.now.to_f}"
    Digest::MD5.hexdigest(seed)
  end

  def set_time_zone
    Time.zone = current_user_time_zone || 'Eastern Time (US & Canada)'
  end
  private :set_time_zone

  def current_user_time_zone
    # unfortunately, we have records with empty string in the time_zone field
    # so we can't just say current_user && current_user.time_zone
    current_user && current_user.time_zone.present? && current_user.time_zone
  end
  private :current_user_time_zone

  def translate_params_to_utf_8
    params.each do |key, value|
      if value.class == String
        params[key] = value.encode('UTF-8', 'iso-8859-1')
      end
    end
  end

  def render_xml_message(status, message, requested_id=nil)
    xml = Builder::XmlMarkup.new
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.response(:status => status ) do |x|
      x.message(message)
      x.requested_id(requested_id) if requested_id
    end
    render :xml => (xml.to_xml)
  end

  IN_DEV_OR_TEST_ENV = Rails.env.in?(%w[development test])

  # Predicate method servers as a wrapper for the constant for compatibility.
  private def is_dev_or_test_env?
    IN_DEV_OR_TEST_ENV
  end

  private

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def set_fall_back_user
    # NOTE: UA is now setting a cookie containing fallback user's guid instead of an id for M3 to read;
    return if cookies[M3::Application.config.fall_back_user_guid_key].blank?
    if cookies[M3::Application.config.fall_back_user_guid_key].present? && current_user && cookies[M3::Application.config.fall_back_user_guid_key] != current_user.guid
      @fall_back_user ||= User.where(guid:cookies[M3::Application.config.fall_back_user_guid_key]).first
    end
  end

  def any_courses_in_current_program?
    current_user && current_user.instructor? && current_program && current_user.has_any_course_for?(current_program)
  end

  def append_info_to_payload(payload)
    super
    begin
      if current_user
        # TODO: To reduce payload size, consider removing user_id and keeping
        # just guid once rostering has been battle-tested for a while.
        payload['user_id'] = current_user.id
        payload['user_guid'] = current_user.guid
      end
      payload['session_id'] = cookies[M3::Application.config.m3_session_key]
      payload['_csrf_token'] = session['_csrf_token'] if session
      payload['ip'] = request.remote_ip
      payload['params'] = request.filtered_parameters.except('controller', 'action', 'format')
    rescue
      # Don't lose logs if something fails here
    end
  end

  def vhl_return_to_sanitizer(url)
    # Avoid URI::InvalidURIError: URI must be ascii only
    # when the url contains the rails enforce_utf8 char. e.g.
    # "https://www.vhlcentral.com/?utf8=\u2713&other=2"
    clean_url = url.gsub("utf8=\u2713", '')
                   .gsub('utf8=%E2%9C%93', '')
                   .gsub('?&', '?')
                   .gsub('&&', '&')
    uri = URI.parse(clean_url)
    if uri.host.present? && !valid_return_to_host?(uri.host)
      ua_home_path
    else
      CGI.unescape(clean_url)
    end
  end
  helper_method :vhl_return_to_sanitizer

  VALID_RETURN_TO_HOSTS = %w[vhlcentral.com vistahigherlearning.com m3a.vhlcentral.com].concat(
    (defined?(STAGING_RETURN_TO_HOSTS) && STAGING_RETURN_TO_HOSTS) || []
  ).freeze

  private def valid_return_to_host?(host)
    VALID_RETURN_TO_HOSTS.any? { |valid_host| host =~ /#{valid_host}$/ } ||
      (is_dev_or_test_env? && host =~ /\.example\.com/)
  end

  def require_section_instructor_or_same_student
    # Check whether current user is an instructor in the section
    #   or the same student as the student whose grades are to
    #   be viewed.
    #
    # This is for use in GradebookEngine::StudentGradesController.
    redirect_paths = { 'Instructor' => main_app.instructor_dashboard_path(current_program),
                       'Student' => main_app.ua_home_path }

    # Test that current user is either the student with grades to be viewed
    #   or an instructor in the section.

    user = User.find(params[:user_id])
    section = Section.find(params[:section_id])
    if current_user.id != user.id && !section.has_instructor?(current_user)
      # If not, assign error to flash and redirect to dashboard

      flash[:error] = %(This page requires that the user be either the student with grades to be viewed OR an instructor with access to the section.)
      redirect_to redirect_paths[current_user.base_account_type]
    end
  end

  private def prevent_supersite_junior_access
    return unless supersite_junior?

    flash[:error] = BLOCKED_SUPERSITE_JUNIOR_MESSAGE
    redirect_to_best_default_path
  end

  private def redirect_to_best_default_path
    redirect_to(best_default_path)
  end

  private def best_default_path
    BestDefaultPath.best_default_path(
      current_user, current_program, current_section, session
    )
  end

  private def archived_program_redirect
    return if !current_program&.is_archived

    redirect_to "#{UA_URL}/archived/#{current_program.id}"
  end

  private def redirect_to_access_denied_activity_view
    flash[:error] =
      'You do not have a site license to access this activity. Please, contact VHL.'
    redirect_to cartridge_access_denied_path(params[:id])
  end

  private def handle_feature_toggle
    return unless params['toggle-program-nav']

    # Strip the feature toggle query parameter out of the URL before
    # storing it as the return_to, to avoid an infinite loop of toggling
    # and redirecting.
    uri = URI.parse(request.fullpath)
    query_params = Rack::Utils.parse_nested_query(uri.query || '')
    query_params.delete('toggle-program-nav')
    uri.query = URI.encode_www_form(query_params)
    session[:return_to] = uri.to_s

    redirect_to '/toggle-program-nav'
  end
end
