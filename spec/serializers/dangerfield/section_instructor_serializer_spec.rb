describe Dangerfield::SectionInstructorSerializer do
  let(:instructor) { create(:instructor) }
  let(:section) { create(:section) }

  let(:dangerfield_serializer) do
    SectionInstructorSerializer.new(SectionInstructor)
  end

  let(:section_instructor) do
    create(:section_instructor, section: section, instructor: instructor)
  end

  let(:section_instructor_json) do
    JSON.parse(section_instructor.dangerfield_serializer.to_json)
  end

  it 'adds the user_guid attribute' do
    expect(section_instructor_json['user_guid']).to eq(instructor.guid)
  end

  it 'adds the section_guid attribute' do
    expect(section_instructor_json['section_guid']).to eq(section.guid)
  end

  it 'excludes the allowed_to_edit_content attribute' do
    expect(section_instructor_json).not_to have_key('allowed_to_edit_content')
  end

  it 'excludes the id attribute' do
    expect(section_instructor_json).not_to have_key('id')
  end

  it 'excludes the role attribute' do
    expect(section_instructor_json).not_to have_key('role')
  end

  it 'excludes the section_id attribute' do
    expect(section_instructor_json).not_to have_key('section_id')
  end

  it 'excludes the user_id attribute' do
    expect(section_instructor_json).not_to have_key('user_id')
  end
end
