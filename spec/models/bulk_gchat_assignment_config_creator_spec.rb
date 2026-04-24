describe BulkGchatAssignmentConfigCreator do
  let(:course) { create(:course) }
  let!(:activity_1) { create(:activity, activity_type: 'group_chat') }
  let!(:activity_2) { create(:activity, activity_type: 'group_chat') }
  let(:section_1) { create(:section) }
  let(:section_2) { create(:section) }

  # Source section assignments
  let!(:assignment_1) { create(:assignment, assignable: activity_1, section: section_1) }

  let!(:assignment_2) { create(:assignment, assignable: activity_2, section: section_1) }

  # Destination section assignments
  let!(:assignment_3) { create(:assignment, assignable: activity_1, section: section_2) }

  let!(:assignment_4) { create(:assignment, assignable: activity_2, section: section_2) }

  let(:gchat_assignments) do
    Assignment
      .where(assignable_id: [activity_1.id, activity_2.id])
      .select(
        'assignments.*, gcac.group_maximum, gcac.group_minimum'
      ).joins(
        'INNER JOIN group_chat_assignment_configs ' \
        'gcac ON gcac.assignment_id = assignments.id'
      )
  end

  let(:creator) { described_class.new(gchat_assignments, section_2) }

  describe '#create' do
    before do
      # Source section group chat assignment configs
      create(
        :group_chat_assignment_config,
        assignment: assignment_1,
        group_minimum: 3,
        group_maximum: 4
      )

      create(
        :group_chat_assignment_config,
        assignment: assignment_2,
        group_minimum: 2,
        group_maximum: 5
      )

      creator.create
    end

    it 'increases group chat assignment configs count to 4' do
      expect(GroupChatAssignmentConfig.count).to eq(4)
    end

    it 'creates a group chat assignment config for assignment_3' do
      expect(
        GroupChatAssignmentConfig.where(
          assignment_id: assignment_3.id,
          group_minimum: 3,
          group_maximum: 4
        )
      ).to exist
    end

    it 'creates a group chat assignment config for assignment_4' do
      expect(
        GroupChatAssignmentConfig.where(
          assignment_id: assignment_4.id,
          group_minimum: 2,
          group_maximum: 5
        )
      ).to exist
    end
  end
end
