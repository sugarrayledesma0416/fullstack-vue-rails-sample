describe LessonPublishProcessor do

  let(:params){ {  'unit_toc_location' => 1, 'rank' => 1, 'name' => 'Lesson 1', 'toc_entries_xml' => 'some_file' } }
  let!(:processor) { LessonPublishProcessor.new(params)}

  it 'includes BasePublishProcessor' do
    expect(processor).to be_a BasePublishProcessor
  end

  describe '#process_request' do
    let(:unit) { build_stubbed(:unit) }

    before do
      allow(Unit).to receive(:find_by_toc_location).with(params['unit_toc_location']).and_return(unit)
    end

    it 'finds a unit by the given toc location param' do
      expect(Unit).to receive(:find_by_toc_location).and_return(unit)
      processor.process_request
    end

    it 'sets unit id value in the processor request params when a unit is found' do
      processor.process_request
      expect(processor.request['unit_id']).to eq(unit.id)
    end

    it 'finds lesson to be published using given unit id and rank' do
      expect(Lesson).to receive(:find_by_unit_id_and_rank).with(unit.id, params['rank'])
      processor.process_request
    end
  end
end
