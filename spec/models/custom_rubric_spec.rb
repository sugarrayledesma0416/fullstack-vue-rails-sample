describe CustomRubric do
  let(:source_activity) { create(:activity) }
  let(:strand) { create(:toc_entry) }
  let(:concept) { create(:concept, id: strand.location.to_i, lesson: lesson) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }

  let(:instructor_activity) do
    create(
      :instructor_created_activity,
      concept: concept,
      lesson: lesson,
      toc_entry_id: strand.location
    )
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )
  end

  it 'has a source activity' do
    custom_rubric = described_class.create!(
      activity_id: instructor_activity.id,
      source_activity_id: source_activity.id
    )

    expect(custom_rubric.source_activity).to eq(source_activity)
  end

  it 'has an instructor_created_activity' do
    custom_rubric = described_class.create!(
      activity_id: instructor_activity.id,
      source_activity_id: source_activity.id
    )

    expect(custom_rubric.instructor_created_activity).to eq(instructor_activity)
  end
end
