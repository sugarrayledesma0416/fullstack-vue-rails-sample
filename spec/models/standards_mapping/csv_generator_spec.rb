module StandardsMapping
  describe CsvGenerator do
    describe '#generate' do
      before do
        program = instance_double(Program, id: 1, title: 'Program 1')
        activity_set = instance_double(StandardsMapping::ActivitySet)
        allow(activity_set).to receive(:each).and_yield(%w[foo bar]).and_yield(%w[biz baz])
        allow(StandardsMapping::ActivitySet)
          .to receive(:new).with(1, 'Activity').and_return(activity_set)
        allow(Program).to receive(:find).with(1).and_return(program)
      end

      after do
        File.delete('/tmp/program_1-activities.csv')
      end

      it 'writes a csv containing data from the list' do
        described_class.new(1, 'Activity').generate!
        parsed_csv = CSV.read('/tmp/program_1-activities.csv')
        header_row = described_class::ACTIVITY_HEADERS
        expect(parsed_csv).to eq([header_row, %w[foo bar], %w[biz baz]])
      end
    end
  end
end
