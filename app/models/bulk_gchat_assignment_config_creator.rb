# Creates group chat assignment configs for assignments

class BulkGchatAssignmentConfigCreator

  GCHAT_CONFIG_COLUMN_NAMES = %i[
    assignment_id
    group_maximum
    group_minimum
  ].freeze

  def initialize(original_assignments, destination_section_id)
    @original_assignments = original_assignments
    @destination_section_id = destination_section_id
  end

  def create
    lookup = get_gchat_assignments_lookup
    @original_assignments.each do |original_assignment|
      new_assignment_id = lookup[original_assignment.assignable_id]
      bulk_gchat_assignment_configs << gchat_column_values(
        original_assignment, new_assignment_id
      )
    end
    GroupChatAssignmentConfig.import(
      GCHAT_CONFIG_COLUMN_NAMES,
      bulk_gchat_assignment_configs
    )
  end

  private def bulk_gchat_assignment_configs
    @bulk_gchat_assignment_configs ||= []
  end

  private def gchat_column_values(original_assignment, new_assignment_id)
    [
      new_assignment_id,
      original_assignment.group_maximum,
      original_assignment.group_minimum
    ]
  end

  private def get_gchat_assignments_lookup
    Assignment
      .where(section_id: @destination_section_id)
      .pluck(:assignable_id, :id)
      .to_h
  end
end
