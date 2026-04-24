describe GbIndividualAssignmentMigrator, new_gb_sync: true do
  let(:section) { create(:section) }
  let(:lesson) { create(:lesson) }
  let(:concept) { create(:concept, lesson: lesson) }
  let(:activity) { create(:activity, concept: concept, lesson: lesson) }
  let(:user) { create(:student) }

  it 'creates a new gradebook individual assignment record if one ' \
     'does not exist' do
    IndividualAssignment.create!(
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    )

    results = GradebookEngine::IndividualAssignment.where(
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    )
    expect(results.size).to eq(1)
  end

  it 'deletes an existing gradebook individual assignment record when the ' \
     'm3 individual assignment record is deleted' do
    m3_record = IndividualAssignment.create!(
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    )

    expect { m3_record.destroy }.to change(
      GradebookEngine::IndividualAssignment, :count
    ).from(1).to(0)
  end
end
