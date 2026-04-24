class ActivityLinkPresenter
  include ApplicationHelper
  include AudienceLabeling
  include ActionView::Helpers::SanitizeHelper
  include Music::ApplicationHelper

  attr_accessor :view

  delegate :content_tag, :inline_svg_tag, to: :view

  def initialize(view)
    self.view = view
  end

  def instructor_toc_link(activity, toc_presenter, svg_format = false)
    output = ''
    output << popup_link(activity, activity_path(activity), toc_presenter)

    output << activity_icon(activity, svg_format) if activity.icon.present?
    output << instructor_icon(:graded, svg_format, activity.program) if activity.instructor_graded?
    output << instructor_icon(:note, svg_format) if toc_presenter.has_note?(activity)
    output << GearMenu.new(view, activity, toc_presenter).render(:link)
    output.html_safe
  end

  private def activity_icon(activity, svg_format)
    view.content_tag(
      :span,
      format_activity_icon(activity.icon, svg_format),
      id: "icon_#{activity.id}",
      class: 'icon  c-embedded-icon--md-lg'
    )
  end

  private def instructor_icon(icon_type = :graded, svg_format = false, program = nil)
    icon_filename = icon_type == :graded ? 'icon_person' : 'instructor_note_icon_rounded'
    button_opts = {
      lang: 'en',
      class: 'icon  u-bord-none  u-bg-transparent  u-pad-0  u-mar-lt-5  u-cursor-default  js-tooltip-auto',
      id: "instructor_#{icon_type}",
      type: 'button',
      aria: {
        label: icon_type == :graded ? 'Grading information' : "instructor #{icon_type}"
      }
    }.tap do |memo|
      memo[:title] = if icon_type == :graded
                       audience_label(program&.audience, :Instructor_graded)
                     else
                       "instructor #{icon_type}"
                     end
    end

    view.content_tag(:button, button_opts) do
      if svg_format
        feature_icon("music/toc/#{icon_filename}", ['c-embedded-icon--md-lg'])
      else
        view.image_tag("#{icon_filename}.png")
      end
    end
  end

  private def popup_link(activity, path, toc_presenter)
    view.content_tag(
      :a,
      sanitize(activity.title, tags: %w[span], attributes: %w[lang]),
      {
        id: view.dom_id(activity),
        href: path,
        onclick: popup_onclick(activity),
        target: '_blank',
        class: 'instructor activity_link  u-txt-under',
        aria: {
          describedby: "icon_#{activity.id} " \
          "#{'instructor_graded' if activity.instructor_graded?}" \
          "#{'instructor_note' if toc_presenter.has_note?(activity)}"
        }
      }
    )
  end

  private def popup_onclick(activity)
    format_popup_onclick(
      window_name: "activity_#{activity.id}",
      height: 600,
      width: 1000
    )
  end

  private def activity_path(activity)
    path_method = view.spr? ? :spr_section_activity_path : :section_activity_path
    rails_url_helpers.public_send(
      path_method,
      id: activity.id,
      popup: 1,
      section_id: 0
    )
  end

  private def rails_url_helpers
    Rails.application.routes.url_helpers
  end

  class GearMenu
    include AssignmentHelper

    attr_accessor :view

    def initialize(view, activity, toc_presenter, in_institution_admin = nil)
      self.view = view
      # super(
      #   ActionView::LookupContext.new(ActionController::Base.view_paths),
      #   {},
      #   nil
      # )

      @gear_html = ''
      @activity = activity
      @toc_presenter = toc_presenter
      @in_institution_admin = in_institution_admin
      @rubric_link_text = 'View Rubric'
    end

    def render(link_type = :menu)
      if @toc_presenter.course && @activity.instructor_created? && !@activity.is_shared_copy?
        if link_type == :menu
          build_gear_menu
        else
          @gear_html = instructor_created_activity_links
        end
      elsif @toc_presenter.course && !@activity.is_shared_copy?
        if @activity.assessment? && @activity.exam?
          @gear_html = copy_assessment_link
        elsif @activity.has_rubric? && should_show_copy_rubric_link?
          # Rubric Editing is not available for JSON content
          @gear_html = copy_rubric_link
        end
      end
      @gear_html
    end

    private def instructor_created_activity_links
      "#{copy_assessment_link} #{copy_rubric_link} #{remove_activity_link} #{edit_activity_link} #{assigned_activity_tag}"
    end

    private def assigned_activity_tag
      view.hidden_field_tag(
        "activity_assignment_#{@activity.id}",
        @toc_presenter.activity_assignments(@activity.id).present?
      )
    end

    private def can_edit_activity?
      @toc_presenter.can_edit_activity?(@activity) && !@in_institution_admin
    end

    private def can_remove_activity?
      @toc_presenter.can_remove_activity?(@activity) && !@in_institution_admin
    end

    private def edit_activity_link
      return unless can_edit_activity?

      label = @activity.has_rubric? ? 'Edit rubric' : 'Edit activity'

      view.link_to(
        instructor_edit_created_activity_path,
        id: "edit_activity_link_#{@activity.id}",
        class: 'control-icon  absolute  absolute--third  edit-created-activity ' \
               'control-icon--edit  u-float-rt  test-icon-edit  js-tooltip-auto',
        title: label,
        aria: { label: label }
      ) do
        Music::Components.icon(variant: 'edit', size: 'md', text: '')
      end
    end

    private def remove_activity_link
      return unless can_edit_activity?

      view.link_to(
        remove_created_activity_path,
        remote: true,
        id: "remove_activity_link_#{@activity.id}",
        class: 'control-icon  absolute  absolute--first ' \
               'u-float-rt  test-icon-remove  control-icon--trash-can  js-tooltip-auto',
        title: 'Remove activity',
        aria: { label: 'Remove activity' }
      ) do
        Music::Components.icon(variant: 'delete', size: 'md', text: '')
      end
    end

    private def remove_created_activity_path
      rails_url_helpers.confirm_destroy_instructor_my_content_path(
        id: @activity.id, program_id: @activity.program.id
      )
    end

    private def can_copy_assessment?
      @toc_presenter.can_edit_course_library? && @activity.exam?
    end

    private def can_copy_rubric?
      @toc_presenter.can_edit_course_library? && @activity.has_rubric?
    end

    private def should_show_copy_rubric_link?
      if @activity.content_json.nil?
        @activity.parse_content
      end

      @activity.content_json.nil?
    end

    private def copy_assessment_link
      if can_copy_assessment? && !@in_institution_admin
        view.link_to(
          instructor_created_activities_create_from_assessment_path,
          id: "copy_assessment_link_#{@activity.id}",
          class: 'control-icon  absolute  absolute--second  test-icon-copy  ' \
                 'control-icon--copy  u-float-rt  js-copy-created-activity  js-tooltip-auto',
          title: 'Create a copy to customize',
          aria: { label: 'Create a copy to customize' }
        ) do
          Music::Components.icon(variant: 'copy', size: 'md', text: '')
        end
      else
        ''
      end
    end

    private def copy_rubric_link
      if can_copy_rubric? && !@in_institution_admin && !is_a_custom_rubric?
        icon_component
      else
        ''
      end
    end

    private def build_gear_menu
      @gear_html = view.content_tag(:div, class: 'toc_gear') do
        view.content_tag(
          :a, 'Gear', href: '#', class: 'gear'
        ) + view.content_tag(
          :div, class: 'gear_menu'
        ) do
          menu_options
        end
      end
    end

    private def menu_options
      options_html = ''
      view.content_tag(:ul) do
        options_html << view.content_tag(:li, instructor_created_activity_links)
        options_html.html_safe
      end
    end

    private def instructor_created_activities_create_from_activity_path
      rails_url_helpers.instructor_created_activities_create_from_activity_path(
        instructor_created_activity_link_params
      )
    end

    private def instructor_created_activities_create_from_assessment_path
      rails_url_helpers.instructor_created_activities_create_from_assessment_path(
        instructor_created_activity_link_params
      )
    end

    private def instructor_edit_created_activity_path
      rails_url_helpers.edit_instructor_created_activity_path(
        instructor_created_activity_link_params
      )
    end

    private def instructor_created_activity_link_params
      {
        lesson_id: @activity.lesson_id,
        toc_entry_id: @activity.toc_location,
        program_id: @activity.program.id,
        id: @activity,
        in_institution_admin: @in_institution_admin
      }
    end

    private def rails_url_helpers
      Rails.application.routes.url_helpers
    end

    private def icon_component
      label = copy_icon_label
      music_component = Music::Components.icon(variant: 'copy', size: 'md', text: '')
      content_opts = {
        id: "copy_rubric_link_#{@activity.id}",
        class: 'control-icon  absolute  absolute--second  test-icon-copy  ' \
               "control-icon--copy  u-float-rt  js-tooltip-auto",
        title: label,
        aria: { label: label }
      }

      if has_existing_copy?
        view.content_tag(:span, content_opts) do
         music_component
        end
      else
        view.link_to(
          copy_icon_path,
          content_opts
        ) do
          music_component
        end
      end
    end

    private def copy_icon_label
      if has_existing_copy?
        'You may not make more than one copy'
      else
        'Create a copy to edit the rubric'
      end
    end

    private def copy_icon_path
      if has_existing_copy?
        'javascript://'
      else
        instructor_created_activities_create_from_activity_path
      end
    end

    private def has_existing_copy?
      return @has_existing_copy if defined?(@has_existing_copy)

      @has_existing_copy = CustomRubric.exists?(
        source_activity_id: @activity.id,
        course_id: @toc_presenter.course.id,
        instructor_id: @toc_presenter.current_user.id
      )
    end

    private def is_a_custom_rubric?
      CustomRubric.exists?(
        activity_id: @activity.id,
        course_id: @toc_presenter.course.id,
        instructor_id: @toc_presenter.current_user.id
      )
    end
  end
end
