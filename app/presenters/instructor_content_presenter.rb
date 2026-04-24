class InstructorContentPresenter < ActionView::Base
  include ApplicationHelper
  include ActivitiesHelper
  # "Common" means shared between Supersite Junior and non-Supersite Junior
  include TocPresenterCommon
  # "Standard" means "not Supersite Junior"
  include StandardTocPresentation
  include LessonAndStrandsPresenter
  include InstructorTocPresentation
  include Music::ApplicationHelper
  include Sortable
  include SharedContent::RedirectionLinkHelper

  attr_accessor :current_user, :current_program, :current_focus, :lesson, :program

  SHARED_CONTENT_COLSPAN = 7
  MY_CONTEN_COLSPAN = 6

  def initialize(program, user, current_focus, req_params, saved_location)
    raise "not all parameters are valid" if (!program || !user || !req_params)

    self.current_user = user
    self.current_focus = current_focus
    self.course = current_focus.course if current_focus
    self.program = program
    @req_params = req_params
    @saved_location = saved_location
  end

  def is_shared_activity?(source_activity_id)
    SharedLibraryActivity.where(source_activity_id:, is_shared: true).exists?
  end

  def lesson_activities(filters = {})
    filter_instructor_activities(
      filters[:lesson_ids],
      filters[:strands],
      filters[:types],
      filters[:shared_activity_creator_ids],
      fetch_activities
    ).order("#{sort_column} #{sort_direction}").paginate(page: search_page, per_page: 10)
  end

  def search_page
    @req_params.fetch('page', 1).to_i
  end

  def lessons_by_units
    program.units.map do |unit|
      { id: unit.id, label: unit.name, lesson_ids: unit.lessons.pluck(:id) }
    end
  end

  def filter_instructor_activities(selected_lesson_ids,
                                   selected_strands,
                                   selected_types,
                                   selected_shared_activity_creator_ids,
                                   activities)
    if selected_types.present? && activities.present?
      activities = activities.where(activity_type: selected_types)
    end

    if selected_lesson_ids.present? && activities.present?
      activities = activities.includes(:lesson).where(lesson_id: selected_lesson_ids)

      if selected_strands.present? && activities.present?
        # It is necessary to retrieve the activity IDs when filtering by strands and then use
        # the resulting IDs with `activities.where(id: activity_ids)`. This ensures that we
        # keep the `activities` object as an ActiveRecord::Relation, which is crucial for
        # avoiding conflicts with pagination methods that rely on ActiveRecord::Relation.
        activity_ids = activities.filter_map do |activity|
          activity.id if selected_strands.include?(activity.strand&.title)
        end

        activities = activities.where(id: activity_ids)
      end
    end

    if selected_shared_activity_creator_ids.present? && activities.present?
      activities =
        activities.joins(:instructor)
                  .where(users: { id: selected_shared_activity_creator_ids })
    end

    activities
  end

  def activities_by_toc_location
    @activities_by_toc_location ||= lesson_activities.group_by(&:toc_location)
  end

  def colspan(content)
    # As shared_content needs an extra column for
    # Created By we need the colspan to be dynamic

    if content == 'shared_content'
      SHARED_CONTENT_COLSPAN
    else
      MY_CONTEN_COLSPAN
    end
  end

  def shared_activity_creator(activity)
    return unless SharedLibraryActivity.find_by(activity_id: activity.id).source_activity.instructor_id

    creator_id = SharedLibraryActivity.find_by(activity_id: activity.id)
                                      .source_activity
                                      .instructor_id

    User.unscoped.find(creator_id).username
  end

  def strands(toc_entry = nil)
    if toc_entry.nil?
      display_lesson.strands(show_assessment_strands = true)
    else
      substrands_with_background(toc_entry.children, toc_entry.background_color)
    end
  end

  def base_url(options={})
    Rails.application.routes.url_helpers.instructor_mycontent_path(program.id, options)
  end

  def toc_path(*args)
    Rails.application.routes.url_helpers.instructor_mycontent_path(program.id, *args)
  end

  def activities_by_toc_entry(toc_entry)
    activities_by_toc_location[toc_entry.location.to_i] || []
  end

  def format_activity_icons(activity)
    format_activity_label_with_icons(
      dom_id(activity),
      activity,
      nil,
      nil,
      false,
      true,
      false
    )
  end

  def remove_activity_link(activity)
    title = 'Delete this content'
    msg = "Deleted content will not be available for use in any course. #{title}?"
    link_params = {
      id: "remove_activity_link_#{activity.id}",
    }

    link_to_if(
      linked_to_an_open_course?(activity),
      Music::Components.icon(variant: 'delete'),
      'javascript://',
      link_params.merge(
        class: 'is-disabled',
        title: 'Content in active courses may not be deleted'
      )
    ) do
      link_to(
        Music::Components.icon(variant: 'delete'),
        remove_activity_url(activity),
        link_params.merge(
          data: { confirm: msg }, method: :put, title: 'Delete this content'
        )
      )
    end
  end

  def confirm_remove_activity_link(activity)
    link_to 'Delete', confirm_remove_activity_url(activity), remote: true, class: 'menu__link'
  end

  def confirm_copy_previous_edition_igcs_link
    redirection_link(
      text: 'Copy to my content',
      path: confirm_copy_previous_edition_igcs_url,
      remote: true
    )
  end

  def edit_activity_link(activity)
    if activity.is_owner?(current_user)
      link_to 'Edit', edit_created_activity_url(activity), class: 'menu__link'
    end
  end

  def convert_to_shared_activity_link(activity)
    if activity.is_owner?(current_user)
      msg = "Do you want to request to share this activity with other instructors?"

      link_to_unless(
        activity.is_shared_source? || !activity.is_pending_share?,
        Music::Components.icon(variant: 'cancel'),
        remove_as_shared_url(activity),
        method: :delete,
        title: 'Delete Request to Share'
      ) do
        link_to_unless(
          activity.draft?,
          feature_icon('music/gradebook/icon-gb-export'),
          shared_created_activity_url(activity),
          data: { confirm: msg },
          method: :put,
          title: 'Request to Share'
        ) do
          link_to(
            feature_icon('music/gradebook/icon-gb-export-disabled'),
            '#',
            class: 'is-disabled',
            title: 'This is a draft. Drafts cannot be shared.'
          )
        end
      end
    end
  end

  # This method determines whether to show the IGC-copy UI.
  def uncopied_igc?
    current_user.has_uncopied_igc_for_source_program?(program)
  end

  def uncopied_igc_count
    # Method call is invalid if there is no uncopied IGC.
    unless uncopied_igc?
      raise 'uncopied_igc_count should not be called if there is no uncopied IGC.'
    end

    current_user.uncopied_igc_count(igc_source_program, program)
  end

  def igc_source_program
    # Test for presence of a source program. Method should not be called unless we are sure
    #   a source program exists.
    source_program = ProgramToProgramMapping.source_program(program)

    unless source_program
      raise 'igc_source_program_title should be called only if a source program exists.'
    end

    source_program
  end

  def unshow_activities_approved(content, activity_id, user_id)
    content == 'my_content' and !institution_admin_approver?(activity_id, user_id) ? true : false
  end

  def new_activity_link_presenter(view)
    Instructor::CreatedActivity::NewActivityLinkContentPresenter.new(view, self)
  end

  private def filter_params
    @req_params.slice(:selected_lesson_ids, :selected_strands, :selected_types, :filtered)
  end

  private def pagination_params
    @req_params.slice(:page)
  end

  private def sort_columns
    @sort_columns ||= {
      last_modified: 'activities.updated_at'
    }.freeze
  end

  private def default_sort_column
    'activities.created_at'
  end

  private def sort_link_options(column)
    filter_params.merge(pagination_params).merge(sort_link_params(column))
  end

  private def default_sort_direction
    sort_directions.last
  end

  # Fetches the program edition and returns the previous edition's program, if exists.
  def previous_program_edition
    @previous_program_edition ||= begin
      program_edition = ProgramEdition.find_by(program_id: program.id)

      if program_edition&.previous_edition_program_id.present?
        Program.find_by(id: program_edition.previous_edition_program_id)
      end
    end
  end

  # Fetches activities for the previous program edition, if exists.
  def fetch_previous_edition_activities
    return @fetch_previous_edition_activities if defined? @fetch_previous_edition_activities

    previous_program = previous_program_edition
    @fetch_previous_edition_activities = previous_program ? fetch_activities(previous_program) : []
  end

  def previous_edition_activities_count
    @fetch_previous_edition_activities_count ||= fetch_previous_edition_activities.count
  end

  def fetch_activity_count_message
    noun = 'activity'.pluralize(previous_edition_activities_count)
    "#{previous_edition_activities_count} #{noun}"
  end

  def has_copied_previous_edition_igcs?
    return false unless previous_program_edition.present?

    IgcCopyJob.where(
      instructor_id: current_user.id,
      dest_program_id: program.id,
      src_program_id: previous_program_edition.id
    ).present?
  end

  def has_uncopied_igcs_from_previous_edition?
    !has_copied_previous_edition_igcs? && previous_edition_activities_count > 0
  end

  def uncopied_igcs_from_previous_edition_message
    "#{fetch_activity_count_message} available from a previous edition. #{confirm_copy_previous_edition_igcs_link}"
  end

  def assigned_courses_title(activity)
    activity.assignment_courses.map(&:name).sort.join('<br>')
  end

  private def fetch_activities(program_to_use = self.program)
    InstructorCreatedActivity.where(
      lesson_id: program_to_use.lessons,
      hide_from_my_content: false,
      instructor_id: current_user
    )
  end

  private def url_helpers
    Rails.application.routes.url_helpers
  end

  private def institution_admin_approver?(activity_id, user_id)
    SharedLibraryActivity.where(activity_id: activity_id, institution_admin_approver_id: user_id).exists?
  end

  def remove_activity_url(activity)
    params = { activity_type: activity.activity_type, instructor_created_activity: {hide_from_my_content: true} }.merge(instructor_created_activity_link_params(activity))
    Rails.application.routes.url_helpers.instructor_created_activity_path(params)
  end
  private :remove_activity_url

  private def confirm_remove_activity_url(activity)
    url_helpers.confirm_destroy_instructor_my_content_path(
      id: activity.id,
      program_id: activity.program.id,
      from_my_content: true
    )
  end

  private def confirm_copy_previous_edition_igcs_url
    url_helpers.confirm_copy_previous_edition_igcs_instructor_my_content_index_path(
      program_id: program.id
    )
  end

  def edit_created_activity_url(activity)
    Rails.application.routes.url_helpers.edit_instructor_created_activity_path(
      instructor_created_activity_link_params(activity)
      .merge(toc_location_params(activity))
      .merge(page: search_page)
    )
  end
  private :edit_created_activity_url

  private def shared_created_activity_url(activity)
    Rails.application.routes.url_helpers
         .instructor_created_activities_convert_to_shared_path(
           instructor_created_activity_link_params(activity).merge(toc_location_params(activity))
         )
  end

  def toc_location_params(activity)
    { display_lesson: activity.lesson.id,
      toc_location: activity.toc_location,
      from_my_content: true,
      return_to: toc_path
    }
  end
  private :toc_location_params

  def activity_path(activity, section_id = 0)
    url_params = {:id => activity.id, :section_id => section_id}.merge(toc_location_params(activity))
    Rails.application.routes.url_helpers.section_activity_path(url_params)
  end
  private :activity_path

  private def remove_as_shared_url(activity)
    Rails.application.routes.url_helpers
         .instructor_created_activities_remove_as_shared_path(
           instructor_created_activity_link_params(activity).merge(toc_location_params(activity))
         )
  end

  private def share_activity_url(activity)
    Rails.application.routes.url_helpers.instructor_share_activity_path(
      id: activity.id,
      program_id: activity.program.id
    )
  end

  private def set_private_activity_url(activity)
    Rails.application.routes.url_helpers.instructor_set_private_path(
      id: activity.id, program_id: activity.program.id
    )
  end

  def activity_link(activity)
    link_to(activity.title, activity_path(activity))
  end

  def clickable_activity_link(activity)
    classes = 'menu__link'
    classes += '  u-txt-ital' if activity.draft?

    link_to(
      activity.title,
      "#{activity_path(activity)}?popup=1",
      class: classes,
      target: "_blank",
      onclick: <<-JS.squish
        if (!this.hasAttribute('disabled')) {
          var w = window.open(
            this.href, 'activity_#{activity.id}',
            'directories=no,height=600,location=no,menubar=no,resizable=yes,scrollbars=yes,' +
            'status=yes,toolbar=no,width=1000'
          );
          w.focus();
        }
        return false;
      JS
    )
  end

  private def current_school
    @current_school ||= course&.school || current_user.schools.first
  end

  private def instructor_created_activity_link_params(activity)
    { program_id: activity.program.id, lesson_id: activity.lesson_id, toc_entry_id: activity.toc_location, id: activity.id, return_to: toc_path }
  end

  def linked_to_an_open_course?(activity)
    CourseLibraryActivity
      .where(:activity_id => activity.id)
      .map(&:course)
      .compact
      .any?(&:open?)
  end
  private :linked_to_an_open_course?

  def substrands_with_background(substrands, color)
    return [] if !substrands || !color
    substrands = substrands.each do |substrand|
      substrand.background_color = color
    end
  end
  private :substrands_with_background

  def activity_background_color(activity)
    return '#dddddd' if activity.strand.nil?

    activity.strand.background_color
  end
end
