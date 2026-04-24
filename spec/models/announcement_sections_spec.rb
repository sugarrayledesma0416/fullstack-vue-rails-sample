describe AnnouncementSection do
  describe AnnouncementSection::AnnouncementSectionsAttributesBuilder do
    let(:announcement) { create(:announcement) }
    let(:focus) { double('focus') }
    let(:user) { create(:user) }
    let(:section) { create(:section) }
    let(:announcement_section) { create(:announcement_section, :section => section) }
    let(:params) { {} }
    let(:builder) { AnnouncementSection::AnnouncementSectionsAttributesBuilder.new(focus, user, announcement)}

    describe "#build" do
      it "adds attributes for focused sections" do
        allow(focus).to receive(:sections).and_return([section])
        attributes = builder.build[0]
        expect(attributes[:section_id]).to eql(section.id)
      end

      it "adds existing announcment_sections with destroy flag" do
        allow(focus).to receive(:sections).and_return([])
        allow(announcement).to receive(:announcement_sections).and_return([announcement_section])
        attributes = builder.build[0]
        expect(attributes[:id]).to eql(announcement_section.id)
        expect(attributes['_destroy']).to eql(true)
      end
    end
  end
end
