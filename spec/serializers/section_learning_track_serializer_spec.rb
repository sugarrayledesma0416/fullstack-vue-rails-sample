describe SectionLearningTrackSerializer do
  let(:section) { build_stubbed(:section) }
  let(:category) { build_stubbed(:category) }
  let(:course_package) { double('Maestro::CoursePackage', id: 1) }
  let(:track) { SectionLearningTrack.new(section, [course_package], nil) }

  it 'renders the correct JSON' do
    allow(track).to receive(:activities).and_return(['activity'])
    allow(track).to receive(:description).and_return('Description')
    allow(track).to receive(:strands).and_return(['strand'])
    allow(track).to receive(:first_unit_id).and_return(2)
    allow(track).to receive(:last_unit_id).and_return(3)
    allow(track).to receive(:units).and_return(['Lesson 1'])
    allow(track).to receive(:categories).and_return({ 'Learn' => category })
    allow(track).to receive(:insufficient_license_groups).and_return(true)
    expected_category_json = CategorySerializer.new(category).as_json
    expected_category_json.delete(:current_scoring_ruleset)
    expected = {
      activities: ['activity'],
      course_package_ids: [1],
      description: 'Description',
      strands: ['strand'],
      first_unit_id: 2,
      last_unit_id: 3,
      units: ['Lesson 1'],
      categories: { 'Learn' => expected_category_json },
      insufficient_license_groups: true
    }
    expect(SectionLearningTrackSerializer.new(track).as_json).to eq(expected)
  end
end
