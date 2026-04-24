describe IndividualAssignment do
  let(:activities) { create_list(:activity, 2) }
  let(:section) { create(:section) }
  let(:user) { create(:user) }

  let(:assignment_1) do
    create(:assignment,
           assignable: activities[0],
           section_id: section.id)
  end

  let(:individual_assignment_1) do
    create(:individual_assignment,
           activity_id: activities[0].id,
           due_date: nil,
           section_id: section.id,
           user_id: user.id)
  end

  let(:assignment_2) do
    create(:assignment,
           assignable: activities[1],
           section_id: section.id)
  end

  let(:individual_assignment_2) do
    create(:individual_assignment,
           activity_id: activities[1].id,
           due_date: assignment_2.due_date + 2.days,
           section_id: section.id,
           user_id: user.id)
  end

  describe '#effective_due_date' do
    context 'when no due date is set' do
      it 'uses the due date of the parent assignment' do
        assignment_1
        expect(individual_assignment_1.effective_due_date).to eq(assignment_1.due_date)
      end
    end

    context 'when due date is set' do
      it 'uses the due date' do
        expect(individual_assignment_2.effective_due_date).to eq(individual_assignment_2.due_date)
      end
    end
  end
end
