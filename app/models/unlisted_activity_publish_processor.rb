#  encoding: utf-8

class UnlistedActivityPublishProcessor < ActivityPublishProcessor
  # required attributes: all keys used in publish process logic.
  # valid attributes: all keys used *to create* the published element.
  VALID_ATTRIBUTES = %i[
    activity_type
    assignment_group
    cdn content
    cms_activity_id
    cms_revision_id
    component_name
    concept_id
    concept_rank
    icon
    lesson_id
    license_group_id
    page
    points_possible
    title
    toc_location
  ].freeze

  REQUIRED_ATTRIBUTES = %i[
    cms_activity_id
    cms_revision_id
    lesson_rank
    program_id
    unit_rank
  ].freeze

  def perform
    request['lesson_id'] = retrieve_lesson_id
    request['toc_location'] = nil
    unless errors.present?
      create_or_update_publishable
      set_status_and_errors
    end
  end
  private :perform
end
