#  encoding: utf-8
require 'activity_time_estimate_setter'
require 'study_plan_concepts_creator'

class ActivityPublishProcessor
  include BasePublishProcessor

  attr_accessor :posted_activity_content, :action

  VALID_ATTRIBUTES = %i[
    activity_type
    assignment_group
    cdn
    cms_activity_id
    cms_revision_id
    component_name
    component_language
    concept_id
    concept_rank
    content
    icon
    lesson_id
    license_group_id
    page
    points_possible
    title
    toc_location
    toc_location_rank
  ].freeze

  REQUIRED_ATTRIBUTES = %i[
    cms_activity_id
    cms_revision_id
    lesson_rank
    program_id
    toc_location
    unit_rank
  ].freeze

  def initialize(params)
    super(Activity, params)
    self.posted_activity_content = request.delete('content')
    self.action = request.delete('perform').to_sym if request['perform'].present?
  end

  def object_to_publish
    return @object_to_publish if defined?(@object_to_publish)

    @object_to_publish = Activity.find_by(
      cms_activity_id: request['cms_activity_id'],
      lesson_id: request['lesson_id']
    )
  end

  private def perform
    request['lesson_id'] = retrieve_lesson_id
    super
  end

  private def create_or_update_publishable
    if object_to_publish.present?
      if action == :remove
        perform_remove
      else
        perform_update
      end
    else
      perform_create
    end
    StandardAsset.update_published_status(object_to_publish.cms_activity_id)
    object_to_publish
  end

  private def perform_remove
    object_to_publish.update(:toc_location => nil, :toc_location_rank => nil)
  end

  private def perform_create
    self.object_to_publish = model_to_publish.new(filtered_params)

    # In a non-live environment, we are not sending activity xml to the cdn.
    # Instead, the publish process sends the xml here to be written to disk
    # Setting content here creates the xml activity revision file. See
    # content=() in ActivityContent.
    object_to_publish.content = posted_activity_content  unless Rails.env.live?

    # Updates cms_revision_id in related activities
    revision_updater = CmsRevisionUpdater.new(object_to_publish,
                                              request['cms_revision_id'],
                                              filtered_params['cdn'],
                                              filtered_params['icon']).update_revision_ids_and_cdn
    object_to_publish.save!
    create_study_plan_concepts(revision_updater.updated_activities)
  end

  private def perform_update
    new_revision_id = request.delete('cms_revision_id')
    revision_updater = CmsRevisionUpdater.new(
      object_to_publish,
      new_revision_id,
      filtered_params['cdn'],
      filtered_params['icon']
    )
    # set the revision id so the new content will be saved properly
    object_to_publish.cms_revision_id = new_revision_id

    unless revision_updater.current_version_has_already_been_published?
      # In a non-live environment, we are not sending activity xml to the cdn.
      # Instead, the publish process sends the xml here to be written to disk
      # Setting content here creates the xml activity revision file. See
      # content=() in ActivityContent.
      object_to_publish.content = posted_activity_content unless Rails.env.live?
    end

    # update the revision ids on activities in other books
    revision_updater.update_revision_ids_and_cdn
    # update the publish object
    object_to_publish.update!(filtered_params)
    create_study_plan_concepts(revision_updater.updated_activities)
  end

  private def create_study_plan_concepts(updated_activities)
    activities = (updated_activities + [object_to_publish]).select(&:has_study_plan?)

    return if activities.empty?

    StudyPlanConceptsCreator.batch_create(activities, request['program_id'].to_i)
  rescue Exception => e
    # Temporary logging: attempting to pinpoint the error that is causing activities with
    # same cms_activity_id in different program to fail to update with changes to the published activity;
    Rails.logger.error "Error creating StudyPlanConcepts during publish process for Activity #{object_to_publish.id}: #{e.message}"
  end

  private def retrieve_lesson_id
    unit = Unit.find_by_program_id_and_rank(request['program_id'], request['unit_rank'])
    raise "No unit found with program_id '#{request['program_id']}' and unit rank #{request['unit_rank']}" if unit.nil?
    lesson = Lesson.find_by_unit_id_and_rank(unit.id, request['lesson_rank'])
    raise "No lesson found with unit_id '#{unit.id}' and lesson rank #{request['lesson_rank']}" if lesson.nil?
    lesson.id
  end

  class CmsRevisionUpdater
    attr_accessor :object_to_publish, :new_revision_id, :cdn, :icon

    def initialize(object_to_publish, new_revision_id, cdn, icon)
      self.object_to_publish = object_to_publish
      self.new_revision_id = new_revision_id.to_i
      self.cdn = cdn
      self.icon = icon
    end

    # Verifies whether a revision has already been published by checking if any existing_activity
    # (activities sharing cms_activity_id) has the posted (new) cms_revision_id
    def current_version_has_already_been_published?
      (existing_activities - activities_needing_update).any?
    end

    def updated_activities
      (activities_needing_update - [object_to_publish])
    end

    def update_revision_ids_and_cdn
      object_to_publish.cms_revision_id = new_revision_id

      # updated_activities does not contain object to publish which
      # will be saved later by ActivityPublishProcessor, updating its
      # cms_revision_id and cdn state.
      # This process ensures that activities in other books will also
      # load the updated activity revision from the proper location.
      updated_activities.each do |activity|
        # The 'textbook' value of the icon, varies from program to program
        # so we want to only update the icons, preserving the 'textbook' one
        # if it was already present in the activity and ignoring it otherwise.
        # We also access the icon via the attribute, to avoid getting the
        # processed value returned by the 'icon' method of the Activity model.
        current_icons = activity.attributes['icon']&.split(',') || []
        new_icons = icon.to_s.split(',') - ['textbook']
        new_icons.push('textbook') if current_icons.include?('textbook')
        # cdn state will only change on a non-live server and must be
        # synchronized when a new version is published locally and written to disk.
        activity.update!(cms_revision_id: new_revision_id, cdn: cdn, icon: new_icons.join(','))
      rescue Exception=> e
        # Temporary logging: attempting to pinpoint the error that is causing activities with
        # same cms_activity_id in different program to fail to update with changes to the
        # published activity; this is a temporary fix to log the error and also allow the
        # publish to continue and the rest of the activities to be updated
        Rails.logger.error "Error updating Activity #{activity.id} new revision id #{new_revision_id} publishing Activity: #{object_to_publish.id}: #{e.message}"
      end
      self
    end

    private def existing_activities
      @existing_activities ||= Activity.where(cms_activity_id: object_to_publish.cms_activity_id)
    end

    private def activities_needing_update
      @activities_needing_update ||= existing_activities.joins(:concept).select do |activity|
        activity.cms_revision_id != new_revision_id || activity.cdn != cdn
      end
    end
  end
end
