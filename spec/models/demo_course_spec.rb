describe DemoCourse do
  describe '#demo_section' do
    it 'returns the first section' do
      sections = Array.new(3) { create(:section) }
      demo_course = described_class.new(sections: sections)
      expect(demo_course.demo_section).to eq(sections.first)
    end

    it 'returns nil when there is no section' do
      demo_course = described_class.new(sections: [])
      expect(demo_course.demo_section).to be_nil
    end
  end
end
