describe ConceptPublishProcessor do
  let(:params) { { 'id' => 1,
                   'unit_toc_location' => 10,
                   'program_id' => 1,
                   'unit_rank' => 1,
                   'lesson_rank' => 1,
                   'name' => 'Concept 1',
                   'base_name' => 'Concept',
                   'rank' => 100,
                   'singular_label' => 'quiz',
                   'background_color' => 'blue',
                   'breadcrumb_string' => 'concept',
                   'assessment' => 1} }

  let!(:processor) { ConceptPublishProcessor.new(params)}

  it 'includes BasePublishProcessor' do
    expect(ConceptPublishProcessor.new(params)).to be_a BasePublishProcessor
  end

  describe "#process_request" do
    let(:unit) { build_stubbed(:unit) }
    let(:lesson) { build_stubbed(:lesson) }

    before do
      allow(Unit).to receive(:find_by_toc_location).with(params['unit_toc_location']).and_return(unit)
      allow(Lesson).to receive(:find_by_unit_id_and_rank).with(unit.id, params['lesson_rank']).and_return(lesson)
    end

    it "finds a unit by the given toc location param" do
      expect(Unit).to receive(:find_by_toc_location).and_return(unit)
      processor.process_request
    end

    it "finds lesson to be published using given unit id and rank" do
      expect(Lesson).to receive(:find_by_unit_id_and_rank).with(unit.id, params['lesson_rank'])
      processor.process_request
    end

    it "sets lesson id value in the processor request params when a unit and lesson is found" do
      processor.process_request
      expect(processor.request['lesson_id']).to eq(lesson.id)
    end

    it "returns an error condition if the unit is not found" do
      allow(Unit).to receive(:find_by_toc_location).and_return(nil)
      results = processor.process_request
      expect(results.status).to eq(:unprocessable_entity)
      expect(results.message['message_text']).to include "No unit found with toc_location '10'"
    end

    it "returns an error condition if the lesson is not found" do
      allow(Lesson).to receive(:find_by_unit_id_and_rank).and_return(nil)
      results = processor.process_request
      expect(results.status).to eq(:unprocessable_entity)
      expect(results.message['message_text']).to include "No lesson found with unit_id '#{unit.id}' and lesson_rank '#{params['lesson_rank']}'"
    end

  end
end

