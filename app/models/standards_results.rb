class StandardsResults < ApplicationRecord
  store :results_data, coder: JSON

  validates :cms_activity_id, :section_id, :user_id, :results_data, presence: true

  scope :by_student, ->(student) { where(user_id: student.id) }
  scope :by_section, ->(section) { where(section_id: section.id) }
  scope :by_activity, ->(activity) { where(cms_activity_id: activity.cms_activity_id) }
  scope :by_component_activties, ->(cms_activity_ids) { where(cms_activity_id: cms_activity_ids) }

  def self.current_record(opts)
    where(opts).first
  end

  def self.count_by_activity_and_section(activity, section)
    by_activity(activity).by_section(section).count
  end

  def self.count_by_activities_and_section(cms_activity_ids, section)
    by_component_activties(cms_activity_ids).by_section(section).count
  end

  def self.create_or_update(opts)
    standards_results = current_record(opts.slice(:user_id, :section_id, :cms_activity_id))

    if standards_results
      standards_results.update!(opts.slice(:results_data))
    else
      StandardsResults.create!(opts)
    end
  end

  def points_earned_for_guids(guids)
    guids = [guids] unless guids.is_a?(Array)

    guids.sum do |guid|
      points_earned_for_guid(guid) || 0
    end
  end

  private def points_earned_for_guid(guid)
    results_data[guid.to_s]['points_earned']
  end

  def points_possible_for_guids(guids)
    guids = [guids] unless guids.is_a?(Array)

    guids.sum do |guid|
      points_possible_for_guid(guid) || 0
    end
  end

  private def points_possible_for_guid(guid)
    results_data[guid.to_s]['points_possible']
  end
end
