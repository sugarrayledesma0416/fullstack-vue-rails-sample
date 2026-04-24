describe SectionAssignmentCopier do
  let(:course) { create(:course) }
  let(:original_section) { create(:section) }
  let(:copy_to_section) { create(:section) }
  let(:activity) { create(:activity) }

  describe '#copy_assignments' do
    it 'returns if there are no assignments to copy' do
      copier = described_class.new(original_section.id, copy_to_section.id)
      expect(copier.copy_assignments).to be_nil
    end

    context 'with an assignment with no details,' do
      let!(:assignment) do
        create(
          :assignment,
          assignable: activity,
          assignable_type: 'Activity',
          individually_assignable: true,
          section: original_section
        )
      end

      it 'copies the assignment to the other section' do
        assignment.update!(individually_assignable: true)
        copier = described_class.new(original_section.id, copy_to_section.id)
        copier.copy_assignments
        expect(
          Assignment.find_by(section_id: copy_to_section.id)
        ).to have_attributes(
          assignable_id: assignment.assignable_id,
          category_id: assignment.category_id,
          due_date: assignment.due_date,
          individually_assignable: false,
          rank: assignment.rank,
          track_group_id: assignment.track_group_id
        )
      end

      it 'copies the assignment to the gradbebook of the other section' do
        assignment.update!(individually_assignable: false)
        copier = described_class.new(original_section.id, copy_to_section.id)
        copier.copy_assignments
        expect(
          GradebookEngine::Assignment.find_by(section_id: copy_to_section.id)
        ).to have_attributes(
          activity_id: activity.id,
          category_id: assignment.category_id,
          day_id: assignment.due_date,
          individually_assignable: false,
          lesson_id: activity.lesson_id,
          strand_id: activity.concept_id
        )
      end
    end

    context 'when an assignment has group chat assignment config' do
      let(:gchat_activity) { create(:activity, activity_type: 'group_chat') }
      let(:gchat_assignment) do
        create(
          :assignment,
          assignable: gchat_activity,
          section: original_section
        )
      end

      before do
        create(
          :group_chat_assignment_config,
          assignment: gchat_assignment,
          group_minimum: 3,
          group_maximum: 4
        )
        copier = described_class.new(original_section.id, copy_to_section.id)
        copier.copy_assignments
      end

      it 'copies group chat assessment config' do
        assignment = Assignment.find_by(section_id: copy_to_section.id)
        expect(
          GroupChatAssignmentConfig.where(
            assignment_id: assignment.id,
            group_minimum: 3,
            group_maximum: 4
          )
        ).to exist
      end
    end

    it 'copies an assessment with details' do
      details = {
        number_of_attempts: 1,
        time_limit: 0,
        password: 'password'
      }
      create(
        :assignment,
        section: original_section,
        assigned_assessment_detail_attributes: details
      )
      copier = described_class.new(original_section.id, copy_to_section.id)
      copier.copy_assignments
      assignment = Assignment.where(section_id: copy_to_section.id)[0]
      assessment_detail = AssignedAssessmentDetail.where(assignment_id: assignment.id)[0]
      expect(assessment_detail.number_of_attempts).to eq(details[:number_of_attempts])
      expect(assessment_detail.time_limit).to eq(details[:time_limit])
      expect(assessment_detail.password).to eq(details[:password])
    end
  end
end
