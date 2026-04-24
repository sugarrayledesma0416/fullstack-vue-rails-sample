describe Instructor::CommunicationHelper do
  include Instructor::CommunicationHelper
  let(:course) { build_stubbed(:course)}
  let!(:section) { build_stubbed(:section)}
  let!(:communication_item) { double('communication_item', :section => section, :course => course) }
  let(:current_focus) { double('current_focus') }

  describe "#format_communication_section_name" do
    context "when communication item is a new record" do
      before do
        allow(communication_item).to receive(:new_record?).and_return(true)
      end

      context "when the section focus is set to a specific section" do
        it "returns the current section name" do
          allow(current_focus).to receive(:focused_on_only_one_section?).and_return(true)
          allow(current_focus).to receive(:section).and_return(section)
          expect(format_communication_section_name(communication_item)).to eql section.name
        end
      end

      context "when the section focus is set to 'All sections'" do
        it "returns the 'All sections' string" do
          allow(current_focus).to receive(:focused_on_only_one_section?).and_return(false)
          allow(communication_item).to receive(:section).and_return(nil)
          expect(format_communication_section_name(communication_item)).to eql "All sections"
        end
      end
    end

    context "when communication item is an existing record" do
      before do
        allow(communication_item).to receive(:new_record?).and_return(false)
      end

      context "when the communication item has been associated to a section" do
        it "returns the communication item's section name" do
          expect(format_communication_section_name(communication_item)).to eql section.name
        end
      end

      context "when the communication item has no section association" do
        it "returns the 'All sections' string" do
          allow(communication_item).to receive(:section).and_return(nil)
          expect(format_communication_section_name(communication_item)).to eql "All sections"
        end
      end
    end
  end

  describe "#format_communication_course_name" do
    context "when communication item is a new record" do
      it "returns the current course name" do
        allow(communication_item).to receive(:new_record?).and_return(true)
        allow(current_focus).to receive(:course).and_return(course)
        expect(format_communication_course_name(communication_item)).to eql course.name
      end
    end

    context "when communication item is an existing record" do
      it "returns the communication item's course name" do
        allow(communication_item).to receive(:new_record?).and_return(false)
        expect(format_communication_course_name(communication_item)).to eql course.name
      end
    end
  end
end
