describe IndividualAssignmentUpdater do
  let(:course) do
    create(
      :course,
      start_date: Date.parse('2022-05-01'),
      end_date: Date.parse('2022-07-31'),
      allow_past_end_date: true
    )
  end

  let(:section) { create(:section, course: course) }
  let(:student) { create(:student) }
  let(:activity_1) { create(:activity) }
  let(:activity_2) { create(:activity) }

  def assign(activity, target_section, user)
    IndividualAssignment.create!(
      activity_id: activity.id, section_id: target_section.id, user_id: user.id
    )
  end

  describe '#update' do
    it 'removes existing individual assignments for the specified section ' \
       'and for the specified activity ids that have no user id params ' \
       'with a value of 1' do
      assign(activity_1, section, student)
      other_activity_assignment = assign(activity_2, section, student)
      other_section_assignment = assign(activity_1, create(:section), student)

      params = {
        "activity_#{activity_1.id}" => {
          "user_#{student.id}" => {
            'assigned' => 0
          }
        }
      }

      described_class.new(params, section.id).update

      expect(IndividualAssignment.all.map(&:id)).to contain_exactly(
        other_activity_assignment.id, other_section_assignment.id
      )
    end

    it 'ignores params with keys that do not start with activity_' do
      assign(activity_1, section, student)

      params = { 'program_id' => 123 }

      expect do
        described_class.new(params, section.id).update
      end.not_to change(IndividualAssignment, :count)
    end

    it 'creates individual assignments for the specified section ' \
       'and for the specified activity ids that have a user id param ' \
       'with a value of 1' do
      params = {
        "activity_#{activity_1.id}" => {
          "user_#{student.id}" => {
            'assigned' => 0
          }
        },
        "activity_#{activity_2.id}" => {
          "user_#{student.id}" => {
            'assigned' => 1
          }
        }
      }

      described_class.new(params, section.id).update

      expect(
        IndividualAssignment.where(
          section_id: section.id, user_id: student.id
        ).map(&:activity_id)
      ).to contain_exactly(activity_2.id)
    end

    it 'creates individual assignments for the specified section ' \
       'and for the specified activity ids for multiple users that have ' \
       'user id -> "assigned" params with a value of 1' do
      other_student = create(:student)

      params = {
        "activity_#{activity_1.id}" => {
          "user_#{student.id}" => {
            'assigned' => 1
          },
          "user_#{other_student.id}" => {
            'assigned' => 1
          }
        }
      }

      described_class.new(params, section.id).update

      expect(
        IndividualAssignment.where(
          activity_id: activity_1.id, section_id: section.id
        ).map(&:user_id)
      ).to contain_exactly(student.id, other_student.id)
    end

    it 'creates individual assignments, ' \
       'each with a due date if given, or `nil` if not, ' \
       'for the specified section ' \
       'and for the specified activity ids for multiple users that have ' \
       'user id -> "assigned" params with a value of 1' do
      other_student = create(:student)
      and_yet_another_student = create(:student)

      params = {
        "activity_#{activity_1.id}" => {
          "user_#{student.id}" => {
            'assigned' => 1,
            'due_date' => '2022-06-16'
          },
          "user_#{other_student.id}" => {
            'assigned' => 1,
            'due_date' => ''
          },
          "user_#{and_yet_another_student.id}" => {
            'assigned' => 1,
            'due_date' => '2022-06-18'
          }
        },
        "activity_#{activity_2.id}" => {
          "user_#{student.id}" => {
            'assigned' => 0,
            'due_date' => ''
          },
          "user_#{other_student.id}" => {
            'assigned' => 1,
            'due_date' => '2022-06-15'
          },
          "user_#{and_yet_another_student.id}" => {
            'assigned' => 1,
            'due_date' => '2022-06-17'
          }
        }
      }

      described_class.new(params, section.id).update

      expect(
        IndividualAssignment.where(
          section_id: section.id
        ).pluck(:activity_id, :user_id, :due_date)
      ).to match_array(
        [
          [activity_1.id, student.id, Date.new(2022, 6, 16)],
          [activity_1.id, other_student.id, nil],
          [activity_1.id, and_yet_another_student.id, Date.new(2022, 6, 18)],
          [activity_2.id, other_student.id, Date.new(2022, 6, 15)],
          [activity_2.id, and_yet_another_student.id, Date.new(2022, 6, 17)]
        ]
      )
    end
  end
end
