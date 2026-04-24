describe 'SectionSerializer' do
  let (:dangerfield_serializer) { SectionSerializer.new(Section) }
  let(:course) { create(:course) }
  let(:instructor) { create(:instructor) }
  let(:assistant) { create(:instructor) }
  let(:co_instructor) { create(:instructor) }
  let(:section) do
    section_instructors_attrs = {
        0 => { :user_id => instructor.id, :role => 'Instructor', :skip_section_id_validation => true },
        1 => { :user_id => assistant.id, :role => 'Assistant', :skip_section_id_validation => true }
    }
    new_section = Section.new( name: 'test section', instructor: instructor, section_instructors_attributes: section_instructors_attrs, course: course )
    new_section.save!
    new_section
  end

  describe "dangerfield serializer" do
    it "validates that instructor_guid is injected into serialized object" do
      section_json = JSON.parse(section.dangerfield_serializer.to_json)
      expect(section_json["instructor_guid"]).to eql(instructor.guid)
    end
    it "validates that course_guid is injected into serialized object" do
      section_json = JSON.parse(section.dangerfield_serializer.to_json)
      expect(section_json["course_guid"]).to eql(course.guid)
    end
  end
end
