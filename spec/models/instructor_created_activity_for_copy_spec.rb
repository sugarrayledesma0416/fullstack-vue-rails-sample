describe InstructorCreatedActivityForCopy do
  let(:content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::CompositionContent,
      activity_type: 'composition',
      content_summary: { question_1: 1 },
      grading_method: 'instructor_graded',
      max_attempts: 2,
      points_possible: 10,
      submittable?: true,
      randomizable?: true
    )
  end

  let(:strand) { create(:toc_entry) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
  let(:instructor) { create(:instructor) }

  let(:instructor_created_activity) do
    create(
      :instructor_created_activity,
      title: 'Title example',
      lesson: lesson,
      toc_entry_id: strand.location
    )
  end

  before do
    create(:concept, lesson: lesson, program: program, id: strand.location)
    allow(Maestro::User).to receive(:accessible_programs).with(instructor.guid).and_return([program])
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    document = Nokogiri::XML::Document.new
    direction_line = Nokogiri::XML::Node.new('dl', document)
    bold_text = Nokogiri::XML::Node.new('b', document)
    bold_text.content = 'direction line'
    direction_line.add_child(bold_text)

    allow(content_object).to receive(:dl).and_return(direction_line)
    allow(content_object).to receive(:title).and_return('Title example')
    allow_any_instance_of(described_class).to receive(:content_object).and_return(content_object)
  end

  describe '#copy' do

    it 'creates a new instructor created activity record' do
      instructor_created_activity
      expect do
        described_class.copy(instructor.id, instructor_created_activity)
      end.to change(InstructorCreatedActivity, :count).by(1)
    end
  end
end
