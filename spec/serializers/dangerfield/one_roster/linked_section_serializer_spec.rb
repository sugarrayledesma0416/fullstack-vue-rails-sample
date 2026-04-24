describe Dangerfield::OneRoster::LinkedSectionSerializer do
  let(:dangerfield_serializer) { described_class.new(OneRoster::LinkedSection) }
  let(:section) { create(:section) }
  let(:school) { create(:school) }
  let(:one_roster_linked_section) do
    create(:one_roster_linked_section, section: section, school: school)
  end
  let(:one_roster_linked_section_json) do
    JSON.parse(one_roster_linked_section.dangerfield_serializer.to_json)
  end

  describe 'dangerfield serializer' do
    it 'validates that section_guid is injected into the serialized object' do
      expect(one_roster_linked_section_json['section_guid']).to eql(section.guid)
    end

    it 'validates that section_id is not in the serialized object' do
      expect(one_roster_linked_section_json).not_to have_key('section_id')
    end

    it 'validates that school_guid is injected into the serialized object' do
      expect(one_roster_linked_section_json['school_guid']).to eql(school.guid)
    end

    it 'validates that school_id is not in the serialized object' do
      expect(one_roster_linked_section_json).not_to have_key('school_id')
    end

    it 'validates that object id is not in the serialized object' do
      expect(one_roster_linked_section_json).not_to have_key('id')
    end
  end
end
