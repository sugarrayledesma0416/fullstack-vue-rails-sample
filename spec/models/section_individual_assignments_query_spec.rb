describe SectionIndividualAssignmentsQuery do
  let(:enrolled_student) { create(:student) }
  let(:section) { create(:section) }
  let(:other_section) { create(:section) }

  describe '.assignments' do
    let(:results) { described_class.assignments(section.id) }

    it 'returns an empty collection when there are no students actively ' \
       'enrolled or marked complete in the specified section' do
      create(:dropped_enrollment, section: section)
      create(:transferred_enrollment, section: section)
      create(:active_enrollment, section: other_section)
      create(:completed_enrollment, section: other_section)

      expect(results).to eq([])
    end

    context 'when there students actively enrolled in the specified section,' do
      before do
        create(:active_enrollment, section: section, user: enrolled_student)
      end

      it 'returns an empty collection when there are no assignments' do
        expect(results).to eq([])
      end

      context 'when there is at least 1 assignment in the specified section, ' do
        let!(:assignment) { create(:assignment, section: section) }

        it 'returns assignment records even when there are no individual ' \
          'assignment records for those assignments' do

          expect(results.map(&:assignable_id)).to eq([assignment.assignable_id])
        end

        it 'returns only assignments assigned in the specified section' do
          create(:assignment, section: other_section)

          expect(results.map(&:assignable_id)).to eq([assignment.assignable_id])
        end

        it 'returns student data only for students actively enrolled in or ' \
          'marked complete in the specified section' do
          completed_student = create(:student)
          create(:completed_enrollment, section: section, user: completed_student)

          expect(results.map(&:user_id)).to contain_exactly(
            enrolled_student.id, completed_student.id
          )
        end

        it 'returns an individually_assigned attribute set to nil if there ' \
           'is no individual assignment for a given student' do
          expect(results.first.individually_assigned).to be_nil
        end

        it 'returns a non-nil individually_assigned attribute if there ' \
          'is an individual assignment for a given student' do
          IndividualAssignment.create!(
            activity_id: assignment.assignable_id,
            section_id: section.id,
            user_id: enrolled_student.id
          )
          expect(results.first.individually_assigned).to be_truthy
        end
      end
    end
  end
end
