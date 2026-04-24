module ApplicationHelper
  include ::DateTimeHelper
  include ::PopupHelper
  include ::GradebookV2Helper
  include ::PageTitleHelper
  include GradebookEngine::AssignmentDetailHelper
  include GradebookEngine::ApplicationHelper
  include MaestroActivityEngine::BrowserHelper

  def disabled_individual_assigning_reason(course, presenter = nil)
    if assistant_role_policy.is_assistant?
      'Individual Assigning is not available to Assistants'
    elsif course.nil? && has_no_open_courses?(presenter)
      "You currently don't have a course for this program"
    elsif course && !course.allow_individual_assign?
      'You have not enabled Individual Assigning for this course'
    end
  end

  def disabled_assignment_reorder_reason(course, presenter = nil)
    if assistant_role_policy.is_assistant?
      'Assignment Reordering is not available to Assistants'
    elsif course.nil? && has_no_open_courses?(presenter)
      "You currently don't have a course for this program"
    elsif course && course.sections_by_instructor(current_user).empty?
      "You currently don't have any sections for this course"
    end
  end

  # called from nav menu to disable the Standards-based Assigning menu item
  # and provide a reason to display on a hover
  def disabled_standards_based_assigning_reason(course)
    standards_based_assigning_unauthorized_access_check(course)
  end

  # called from both the nav menu (see disabled_standards_based_assigning_reason above)
  # and the StandardsAssigningController to prevent direct access
  # in case someone uses the route URL directly.
  # Filters out Assistants as they do not have access to this functionality.
  # If there is no course in focus, it checks if the user has any courses
  # in the program. Lastly it checks if there are any open sections in the
  # course, for which the user is either an instructor and co-instructor.
  def standards_based_assigning_unauthorized_access_check(course)
    if assistant_role_policy.is_assistant?
      'Standards-based Assigning is not available to Assistants'
    elsif course.nil? &&
      !(current_user.has_any_course_for?(current_program))
      "You currently don't have a course for this program"
    elsif current_user.sections_of_open_courses_by_program(current_program).empty?
      "You currently don't have any open sections for this course"
    end
  end

  def hoverize(string, hover)
    string != hover ? content_tag(:span, string, :title => html_strip_and_decode(hover)) : string.html_safe
  end

  def possessive(str)
    str += "'"
    str += 's'  unless %r{(s'|se'|z'|ze'|ce'|x'|xe')$}i.match(str)
    str
  end

  def html_string_shorten(str, len, trailing_char = "&hellip;")
    str.extend(HTMLStringShortener).shorten(len, trailing_char).html_safe
  end

  def html_strip_and_decode(string)
    return nil unless string
    ActionController::Base.helpers.strip_tags(string.html_decode)
  end

  def strip_html_tags(string)
    HTMLEntities.new.decode(
      ActionController::Base.helpers.strip_tags(string.gsub(%r{<br */?>}, ' '))
    )
  end

  def id_string(str)
    html_strip_and_decode(str).gsub(/\s/, '_').remove_accents.downcase.gsub(/[\W]/, '')
  end

  def current_url_contains?(options)
    url_string = CGI.unescapeHTML(url_for(options))
    request_uri = @controller.request.request_uri
    regex = ::Regexp.new('^'+url_string)
    !request_uri.scan(regex).empty?
  end

  def format_sample_answer(sample_answer)
    sanitize_options = { tags: %w[span strong em], attributes: %w[lang class] }

    if sample_answer.is_a?(Array)
      formatted_answers = sample_answer.map { |answer| %Q("#{sanitize(answer, sanitize_options)}") }
      raw "[#{formatted_answers.join(', ')}]"
    else
      sanitize(sample_answer, sanitize_options)
    end
  end

  def format_element_with_disabled_explanation(element_id, is_disabled = false, message = '', add_overlay_div = true, &block)
    raise "element_id cannot be blank" if element_id.blank?
    message = "This item is currently disabled." if message.blank?

    contents = raw(capture(&block)) # using raw instead of html_safe because it handles nil better
    wrapper_class = 'enabled_element_wrapper'
    if is_disabled
      wrapper_class = 'disabled_element_wrapper'
      contents << content_tag(:div, message, :style => 'display: none;', :id => "#{element_id}_explanation").html_safe
      contents << '<div style="position: absolute; left: 0; right: 0; top: 0; bottom: 0;"></div>'.html_safe if add_overlay_div
    end
    output = content_tag(:div, contents, :class => wrapper_class, :rel => '#' + element_id + '_explanation', :id => element_id)

    concat(output.html_safe)
  end

  def format_due_date(datetime, url = nil)
    if url
      "Due #{link_to(format_date_time(datetime, format = :weekday_month_ordinal), url)}"
    else
      "Due #{format_date_time(datetime, format = :weekday_month_ordinal)}"
    end
  end

  def format_last_login_date(user)
    last_date = nil

    last_date = format_date_time(user.current_login_at, :standard) if user.current_login_at
    last_date ||= format_date_time(user.last_login_at, :standard) if user.last_login_at
    last_date ||= 'Never'

    last_date
  end

  def error_class
    'fieldWithErrors'
  end

  def format_error_class(model, field_name, default_class = '')
    if model.errors[field_name]
      if default_class.blank?
        'fieldWithErrors'
      else
        "fieldWithErrors #{default_class}"
      end
    else
      default_class
    end
  end

  def format_program_logo_link(program, current_user, section, short = false)
    if current_user && program&.logo_media
      link = program_logo_link(program, current_user, section)
      link_to_unless_current(
        format_program_logo(program, short), link,
        {
          id: "#{program.title.parameterize}_logo",
          class: 'u-dis-inline-block', title: 'Back to Dashboard'
        }
      )
    else
      link_to(image_tag('vista_logo.png', alt: 'Vista Higher Learning'), '/', id: 'vista_logo')
    end
  end

  def display_linked_media_item(link, opts={})
    raise "invalid MediaLink, should be class MediaLink but is #{link.class}" unless link.is_a?(MediaLink)
    if link.open?
      (
        '<span class="media_item"><span class="error">' +
        "Missing media, id(#{link.media_item_id})</span></span>" +
        opts[:broken_image_tag].to_s
      ).html_safe
    else
      display_media_item(link.media_item, opts)
    end
  end

  def pluralize_without_count(number, word)
    return word if number.to_s == '1'
    word.pluralize
  end

  def format_hours_minutes(minutes, format = :long)
    hours = (minutes / 60).floor
    minutes = (minutes % 60).floor
    rval = ''

    if format == :short
      rval += "#{hours}h" unless hours.zero?
      rval += ' ' unless hours.zero? || minutes.zero?
      rval += "#{minutes}m" unless minutes.zero?
    else
      rval += pluralize(hours, 'hour') unless hours.zero?
      rval += ', ' unless hours.zero? || minutes.zero?
      rval += pluralize(minutes, 'minute') unless minutes.zero?
    end
    rval
  end

  # Emit a string only if 'value' is different than the last time it was called with 'category'.
  # Optional block allows arbitrary ERB to be evaluated.
  # e.g.:
  #   <% when_unique(:category, item.category) do |category| -%>
  #      <h1><%= category %></h1>
  #   <% end %>
  def when_unique(category, value, &block)
    @unique_categories ||= {}
    @unique_categories[category] ||= nil
    if value != @unique_categories[category]
      @unique_categories[category] = value
      if block_given?
        block.call(value)
      else
        value
      end
    else
      nil
    end
  end

  def enable_unsaved_changes_protection
    content_for(:js_head, javascript_include_tag('protect_unsaved_changes'))
  end

  def show_disabled_element_explanations
    content_for(:js_head, javascript_include_tag('explain_disabled_elements'))
  end

  def format_to_yes_no(val)
    return 'No' unless val
    return 'Yes'
  end

  def ua_host_url(route_name, url_params = {})
    "//#{ua_host}#{ua_paths(route_name, url_params)}"
  end

  def screencasts_link(html_class='')
    link_to 'How-to videos',
            screencast_url,
            class: html_class,
            onclick: format_popup_onclick(width: 755, height: 675),
            'role':'menuitem'
  end

  def screencast_url
    destination = current_user && current_user.instructor? ? :instructor_screencasts : :student_screencasts

    ua_host_url(destination)
  end

  def format_screencast_context_link(topic_or_screencast_id, title = nil)
    if topic_or_screencast_id.is_a?(String)
      destination = :screencast_topic
    else
      destination = :screencast
    end
    link_url = ua_host_url(destination, { :screencast_topic_or_id => topic_or_screencast_id })
    on_click = format_popup_onclick(:width => 755, :height => 675)
    title = title unless title.nil?
    content_tag(:span, class: test_class('screencast-icon')) do
      link_to(Music::Components.icon(variant: 'screen', size: 'lg'), link_url,:class => "ns-music-v1", :onclick => on_click, :title => title)
    end
  end

  private def program_settings
    @program_settings ||= ProgramSettings.new(current_program)
  end

  def program_has_assessment?
    program_settings.has_assessment?
  end

  def program_has_activities?
    program_settings.has_activities?
  end

  def program_has_my_content?
    program_settings.has_my_content?
  end

  def program_has_audio_transcripts?
    program_settings.has_audio_transcripts?
  end

  def show_standards_assigning_link?
    current_program&.supports_standards? && !assistant_role_policy.is_assistant?
  end

  def ebook_label
    program_settings.ebook_label
  end

  def display_demo_warning?
    current_user && current_user.instructor? && current_program &&
      access_guardian.has_unexpired_demo_access?
  end

  def display_demo_access_information
    if display_demo_warning?
      message = demo_access_expiration_message
      # this link is disabled until videos are updated.
      message += demo_video_link if false && !current_program.vista_online_learning
      content_tag(:div, message.html_safe,
                  :class => 'temp-demo-banner')
    end
  end

  def current_user_is_fake_student?
    current_user.student? && current_user.fake?
  end
  private :current_user_is_fake_student?


  def in_demo_course?
    !current_section.zero? && current_section.course && current_section.course.is_demo?
  end
  private :in_demo_course?

  def demo_video_link
    demo_video_url = ua_host_url(:introductory_video,
                                 { program_id: current_program.id })
    link_to('Replay Intro Video', demo_video_url, class: "demo_video")
  end

  def demo_access_expiration_message
    formatter = Formatters::AccessOptions
      .new(access_guardian.ever_had_demo_access?,
           access_guardian.demo_access_expiration_date.to_date)
    formatter.time_remaining_message
  end

  def program_logo_link(program, current_user, section)
    if current_user.instructor?
      main_app.instructor_dashboard_path(program)
    elsif section&.non_zero?
      student_dashboard_path(program, section)
    else
      toc_path(program)
    end
  end

  def format_program_logo(program, short)
    options = {class: "c-logo__image #{test_class('program-logo')}"}
    options[:height] = '50%' if short
    if program&.logo_media
      options[:alt] = program.title
      display_media_item(program.logo_media, options)
    else
      content_tag(:a, id: 'vista_logo', name: 'vista_logo') do
        image_tag("vista_logo.png", alt: 'Vista Higher Learning')
      end
    end
  end

  def is_partial?(str)
    str.to_s=~/^.*partial$/
  end

  def get_flash_type(str)
    raise "invalid key passed to flash " unless str.to_s=~/^.*partial$/
    str.to_s.gsub('_partial','')
  end

  def get_partial_locals(value)
    raise "partial locals missing" unless value
    return value['locals'].symbolize_keys if value.has_key?('locals')
    {}
  end

  def get_partial_name(value)
    raise "partial name missing" unless value && value.has_key?('partial')
    value['partial']
  end

  def has_html_tags?(str)
    str=~/^<div.*/
  end

  def ua_host
    # UA_URL should be defined in unversioned local file:
    # /config/initializers/local_config.rb
    URI.parse(UA_URL).host
  end

  def format_icon_title(icon)
    icon.sub(/^vol_/, '').titleize
  end
  private :format_icon_title

  def format_activity_icon(icon_str, svg_format = false)
    return ''.html_safe if icon_str.blank?

    icon_str.split(',').map do |icon|
      if svg_format
        format_svg_tooltip(icon)
      else
        image_tag(
          "#{icon}.png",
          title: format_icon_title(icon).to_s,
          lang: 'en',
          class: 'js-tooltip-auto',
          aria: {
            label: format_icon_title(icon).to_s
          }
        )
      end
    end.join(' ').html_safe
  end

  private def format_svg_tooltip(icon)
    content_tag(
      :span,
      feature_icon("music/toc/#{icon}"),
      class: 'js-tooltip-auto',
      title: format_icon_title(icon).to_s,
      role: 'img',
      aria: {
        label: format_icon_title(icon).to_s
      }
    )
  end

  def short_month(date)
    Date::MONTHNAMES[date.month][0..2]
  end

  def ua_paths(route_name, url_params = {})
    case route_name
    when :root
      '/'
    when :support_tools
      '/support/'
    when :home
      '/'
    when :logout
      '/logout'
    when :my_account
      '/user'
    when :site_licenses
      '/site_licenses'
    when :manage_site_license
      '/site_license/admin'
    when :add_school
      '/school/add'
    when :student_instructions
      "/section/#{url_params[:section_guid]}/student_instructions?instructor=1"
    when :login_as
      "/instructor/login_as/#{url_params[:section].guid}"
    when :login_as_with_redirect
      "/instructor/login_as/#{url_params[:section].guid}?course_id=#{url_params[:section].course.id}&section_id=#{url_params[:section].id}&return_to=#{url_params[:return_to]}"
    when :instructor_log_back_in
      "/instructor/log_back_in"
    when :instructor_screencasts
      "/screencasts/instructor?source=m3"
    when :student_screencasts
      "/screencasts/student?source=m3"
    when :edit_profile
      "/avatar/edit"
    when :screencast
         "/screencasts/#{url_params[:screencast_topic_or_id]}"
    when :screencast_topic
      "/screencasts/topic/#{url_params[:screencast_topic_or_id]}"
    when :m2_program
      "/m2_program/#{url_params[:program_id]}"
    when :introductory_video
      "/trial_introduction_video/#{url_params[:program_id]}"
    when :grace_periods
      '/grace_periods'
    when :new_partner_integration_partner_context_link
      "/partner_integration/partner_context_link/new?context_id=#{url_params[:context_id]}"
    when :partner_integration_section_link_manager
      "/partner_integration/clever/section_link/#{url_params[:section_guid]}/manage"
    else
       '/'
    end
  end

  def teacher_vtext_menu_link(html_class='')
    vtext_linker = TeacherVtextLinker.new(current_program, current_user)
    if vtext_linker.menu_linkable?
      # program-nav-v2 is an identifier to reveal new program menu
      if html_class.include? 'program-nav-v2'
        html_item = render(
                      'app_shell/menu_item',
                      item_icon: 'instructors_manual',
                      item_name: vtext_linker.link_label,
                      item_description: 'Annotated textbook for educators'
                    )
        vtext_link(html_item, vtext_linker.link, html_class)
      else
        vtext_link(vtext_linker.link_label, vtext_linker.link, html_class)
      end
    end
  end

  def vtext_menu_link(html_class='')
    vtext_linker = VtextLinker.new(current_program, current_user, nil, session:)
    if vtext_linker.menu_linkable?
      # program-nav-v2 is an identifier to reveal new program menu
      if html_class.include? 'program-nav-v2'
        html_item = render(
                      'app_shell/menu_item',
                      item_icon: vtext_linker.vtext_icon,
                      item_name: vtext_linker.link_label,
                      item_description: vtext_linker.vtext_description
                    )
        vtext_link(html_item, vtext_linker.link, html_class, {'role': 'menuitem'})
      else
        vtext_link(vtext_linker.link_label, vtext_linker.link, html_class, {'role': 'menuitem'})
      end
    end
  end

  def vtext_link(link_text, link, html_class='', attributes = {}) # attributes - Option json argument to be passed to as html_options to link_to function
    # Appending Predefined options to html_options json
    attributes[:'data-link-type'] = 'vtext';
    attributes["class"] = html_class;
    attributes[:target] = '_blank'

    link_to(link_text, link, attributes)
  end
  private :vtext_link

  def main_nav_active(menu)
    if @menu_location == menu
      'is-active'
    end
  end

  def masthead_css_class
    if current_user
      if @fall_back_user
        "logged_in_as"
      elsif current_user.instructor?
        "instructor"
      else
        "student"
      end
    else
     "off"
    end
  end

  def is_dev?
    # Checks that user is a developer.
    #
    # The user is considered a developer if and only if
    #   * the "enable_gradebook_dev_features" config option is set to true, OR
    #   * a "dev" cookie is set
    #
    # Thus, the user is a developer in all non-live environments, because
    #   enable_gradebook_dev_features is `true` by default.
    #
    # If the environment is live, the config option is `false`; if the user
    #   has set the dev cookie, however, the user is a developer. Note that
    #   QA can simulate this case in a non-live environment by setting the
    #   config option to `false`.

    Rails.application.config.enable_gradebook_dev_features || cookies[:dev]
  end

  def chat_feature_ui?
    # We need to know if the chat feature is ON or it's OFF.
    # In the latter case, we check the presence of the dev cookie,
    # ignoring the rails environment, so we can have an easier chat feature toggle for devs/QA.
    Rails.application.config.chat_feature_ui || cookies[:dev]
  end

  def enable_analytics?
    # Checks that user is a developer or permitted to access Analytics
    # All users in dev and QA envs are developers, so they will have access
    # If env is live, a user with a dev cookie is considered a developer
    Rails.application.config.enable_analytics || cookies[:dev]
  end

  def enable_high_contrast?
    Rails.application.config.enable_high_contrast && !supersite_junior?
  end

  def sanitize_with_data_remote(content)
    allowed_tags = Rails::Html::SafeListSanitizer.allowed_tags
    allowed_attributes = Rails::Html::SafeListSanitizer.allowed_attributes + ['data-remote']
    sanitize(content, tags: allowed_tags, attributes: allowed_attributes)
  end

  def head_title
    title = @page_title || @page_header || controller.controller_name.humanize.to_s
    create_page_title(title, format: @page_title_format || PAGE_TITLE_FORMAT[:as_suffix])
  end

  def test_attr(attr_name, attr_value)
    if Rails.env.live?
      ''
    else
      %(data-test-#{attr_name}="#{attr_value}").html_safe
    end
  end

  def tour_guide_eligible?
    current_user.present? &&
      current_user.base_account_type == 'Instructor' &&
      current_program.present?
  end

  def analytics_enabled?
    Rails.env.live? || ENV.fetch('ENABLE_ANALYTICS', false) == 'true'
  end

  def portfolio_redirect_url
    root_url = UA_URL.chomp('/')
    domain_url = if %w[live staging qa].include?(Rails.env)
                   ENV.fetch('PORTFOLIO_DOMAIN_URL')
                 else
                   Rails.configuration.portfolio[:domain_url]
                 end
    student_with_section = current_user.student? && current_section.non_zero?
    section_query = student_with_section ? "&section_id=#{current_section.guid}" : ''
    "#{domain_url}/auth/saml/index.php" \
      "?idpentityid=#{root_url}/saml&username=#{current_user.username}#{section_query}"
  end

  def appcues_id(id)
    "appcues-#{id}"
  end

  private def student_dashboard_path(program, section)
    path_args = { course_id: section.course_id, section_id: section.id }
    if program.supersite_junior?
      main_app.jr_course_section_path(path_args)
    else
      main_app.course_section_path(path_args)
    end
  end

  private def toc_path(program)
    if program.supersite_junior?
      jr_section_program_content_path(section_id: 0, program_id: program.id)
    else
      section_toc_path('0', program)
    end
  end

  private def has_no_open_courses?(presenter)
    presenter.nil? ||
    !presenter.respond_to?(:open_courses_by_program) ||
    presenter.open_courses_by_program.empty?
  end

end
