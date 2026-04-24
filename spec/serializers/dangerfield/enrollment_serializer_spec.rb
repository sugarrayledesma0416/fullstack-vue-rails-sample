describe 'EnrollmentSerializer' do
  let (:dangerfield_serializer) { EnrollmentSerializer.new(Enrollment) }
  let(:section) { create(:section) }
  let(:student) { create(:student) }
  let(:archived_student) { create(:student, :archived =>true) }
  let(:archived_instructor) { create(:instructor, :archived =>true) }
  let(:instructor) { create(:instructor) }
  let(:enrollment) { create(:enrollment, :user => student, :section => section, :added_by_id =>instructor.id, :transferred_from =>transferred_from_section.id, :section_transferred_to =>transferred_to_section.id) }
  let(:transferred_to_section) { create(:section) }
  let(:transferred_from_section) { create(:section) }
  let (:enrollment_json) { JSON.parse(enrollment.dangerfield_serializer.to_json)}
  let(:archived_section) { create(:section, :is_archived => true) }
  let(:enrollment2) { create(:enrollment, :user => student, :section => section, :transferred_from =>archived_section.id) }
  let (:enrollment2_json) { JSON.parse(enrollment2.dangerfield_serializer.to_json)}
  let(:enrollment3) { create(:enrollment, :user => student, :section => section, :section_transferred_to =>archived_section.id) }
  let (:enrollment3_json) { JSON.parse(enrollment3.dangerfield_serializer.to_json)}

  let(:archived_dropped_by_enrollment) { create(:enrollment, :user => student, :section => section, :dropped_by_id => archived_instructor.id) }
  let (:archived_dropped_by_enrollment_json) { JSON.parse(archived_dropped_by_enrollment.dangerfield_serializer.to_json)}

  let(:archived_added_by_enrollment) { create(:enrollment, :user => student, :section => section, :added_by_id => archived_instructor.id) }
  let (:archived_added_by_enrollment_json) { JSON.parse(archived_added_by_enrollment.dangerfield_serializer.to_json)}

  describe "dangerfield serializer" do

    it "validates that user_guid is injected into serialized object" do
      expect(enrollment_json["user_guid"]).to eql(student.guid)
    end
    it "validates that section_guid is injected into serialized object" do
      expect(enrollment_json["section_guid"]).to eql(section.guid)
    end

    it "validates that added_by_guid is injected into serialized object" do
      expect(enrollment_json["added_by_guid"]).to eql(instructor.guid)
    end

    it "validates that transferred_from_guid is injected into serialized object" do
      expect(enrollment_json["transferred_from_guid"]).to eql(transferred_from_section.guid)
    end

    it "validates that section_transferred_to_guid is injected into serialized object" do
      expect(enrollment_json["section_transferred_to_guid"]).to eql(transferred_to_section.guid)
    end

    context 'archived objects ' do
      it "validates that archived section transferred_from_guid is injected into serialized object" do
        expect(enrollment2_json["transferred_from_guid"]).to eql(archived_section.guid)
      end

      it "validates that archived section_transferred_to_guid is injected into serialized object" do
        expect(enrollment3_json["section_transferred_to_guid"]).to eql(archived_section.guid)
      end

      it "validates that archived dropped_by_guid is injected into serialized object" do
        expect(archived_dropped_by_enrollment_json["dropped_by_guid"]).to eql(archived_instructor.guid)
      end

      it "validates that archived added_by_guid is injected into serialized object" do
        expect(archived_added_by_enrollment_json["added_by_guid"]).to eql(archived_instructor.guid)
      end


    end

  end
end
