describe GradingSetStudentList do
  let(:student) { create(:student) }
  let(:activity) { create(:activity) }
  let(:section) { create(:section) }
  let(:other_student) { create(:student) }

  let(:score) do
    build_stubbed(
      :gb_score_action,
      activity_id: activity.id,
      section_id: section.id,
      user_id: student.id
    )
  end

  let(:other_score) do
    build_stubbed(
      :gb_score_action,
      activity_id: activity.id,
      section_id: section.id,
      user_id: other_student.id
    )
  end

  describe '#user_ids' do
    before do
      create(:active_enrollment, section_id: section.id, user: student)
    end

    it 'returns an empty array when there are no submitted scores for the ' \
      'specified activity, sections, and students' do
      allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
        .and_return([])

      results = described_class.new(
        activity_id: activity.id,
        section_ids: [section.id],
        students: [student],
        unassigned: false
      ).user_ids

      expect(results).to eq([])
    end

    context 'when there are submitted scores for the specified activity, ' \
            'sections, and students,' do
      before do
        allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
          .and_return([score])
        create(:assignment, assignable: activity, section_id: section.id)
      end

      it 'returns an empty array if there are no attempts' do
        results = described_class.new(
          activity_id: activity.id,
          section_ids: [section.id],
          students: [student],
          unassigned: false
        ).user_ids

        expect(results).to eq([])
      end

      it 'returns an empty array if there are no attempts that are' \
         'submitted or completed' do
        create(
          :attempt_opened,
          activity_id: activity.id,
          section_id: section.id,
          user_id: student.id
        )
        create(
          :attempt_reset,
          activity_id: activity.id,
          section_id: section.id,
          user_id: student.id
        )

        results = described_class.new(
          activity_id: activity.id,
          section_ids: [section.id],
          students: [student],
          unassigned: false
        ).user_ids

        expect(results).to eq([])
      end

      it 'returns an empty array if there are attempts that are submitted' \
         'or completed, but the attempts are from different sections than ' \
         'those of the score records' do
        other_section = build_stubbed(:section)
        create(
          :attempt_submitted,
          activity_id: activity.id,
          section_id: other_section.id,
          user_id: student.id
        )
        create(
          :attempt_completed,
          activity_id: activity.id,
          section_id: other_section.id,
          user_id: student.id
        )

        results = described_class.new(
          activity_id: activity.id,
          section_ids: [section.id, other_section.id],
          students: [student],
          unassigned: false
        ).user_ids

        expect(results).to eq([])
      end

      it 'returns an array of student user ids when there are submitted ' \
         'or completed attempts from the same sections as the score records' do
        create(
          :attempt_submitted,
          activity_id: activity.id,
          section_id: section.id,
          user_id: student.id
        )
        create(
          :attempt_completed,
          activity_id: activity.id,
          section_id: section.id,
          user_id: other_student.id
        )
        create(:completed_enrollment, section_id: section.id, user: other_student)

        allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
          .and_return([score, other_score])

        results = described_class.new(
          activity_id: activity.id,
          section_ids: [section.id],
          students: [student, other_student],
          unassigned: false
        ).user_ids

        expect(results).to match_array([student.id, other_student.id])
      end
    end

    context 'when some activities are individually-assignable,' do
      before do
        create(:active_enrollment, section_id: section.id, user: other_student)
        create(
          :assignment,
          assignable: activity,
          individually_assignable: true,
          section_id: section.id
        )
        IndividualAssignment.create!(
          activity_id: activity.id,
          section_id: section.id,
          user_id: student.id
        )
        allow(GradebookEngine::GradebookAPI).to receive(:find_submitted)
          .and_return([score, other_score])
      end

      context 'with an assigned work grading set,' do
        it 'filters out students for whom the activity is not ' \
           'individually-assigned' do
          described_class.new(
            activity_id: activity.id,
            section_ids: [section.id],
            students: [student, other_student],
            unassigned: false
          ).user_ids

          expect(GradebookEngine::GradebookAPI).to have_received(:find_submitted)
            .with(
              activity_id: activity.id,
              section_id: [section.id],
              user_id: [student]
            )
        end
      end

      context 'with an unassigned work grading set,' do
        it 'includes only students for whom the activity is not ' \
           'individually-assigned' do
          described_class.new(
            activity_id: activity.id,
            section_ids: [section.id],
            students: [student, other_student],
            unassigned: true
          ).user_ids

          expect(GradebookEngine::GradebookAPI).to have_received(:find_submitted)
            .with(
              activity_id: activity.id,
              section_id: [section.id],
              user_id: [other_student]
            )
        end
      end
    end
  end
end
