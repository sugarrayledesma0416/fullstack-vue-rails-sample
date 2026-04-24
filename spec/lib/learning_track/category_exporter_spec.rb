describe LearningTrack::CategoryExporter do
  let(:program) { build_stubbed(:program) }
  let(:exporter) { LearningTrack::CategoryExporter.new(program) }
  let(:s3_bucket) { double(Radner::S3Storage) }
  let(:xlsx) { double(Roo::Excelx) }

  let(:parsed_data) { CSV.parse(file_data) }
  let(:file_data) do
    "Category Set,Name,Percent,Graded,Attempts,Late_work,Penalty_type,Penalty
Base Categories,Credit,20,N,Unlimited,Y,percent per day,50
,Graded,40,Y,2,Y,flat  percent,20"
  end

  let(:category_map) do
    {
      'Base Categories' => {
        'Credit' => {
          name: 'Credit',
          rank: 1,
          max_attempts: -1,
          credit_only: true,
          weighting_percent: 20,
          accept_late_work: 1,
          penalty_percent: 50,
          late_work_penalty: 'percent_per_day'
        },
        'Graded' => {
          name: 'Graded',
          rank: 2,
          max_attempts: 2,
          credit_only: false,
          weighting_percent: 40,
          accept_late_work: 1,
          penalty_percent: 20,
          late_work_penalty: 'flat_percent'
        }
      }
    }
  end

  before do
    allow(Roo::Spreadsheet).to receive(:open).and_return(xlsx)
    allow(xlsx).to receive(:parse).with({}).and_return(parsed_data.drop(1))
    allow(xlsx).to receive(:row).with(1).and_return(parsed_data.first)
  end

  describe 'json' do
    describe '#write_categories_json' do
      it 'returns a JSON encoded string of map and activity data' do
        allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
        allow(s3_bucket).to receive(:fetch)
        allow(s3_bucket).to receive(:directory_files).and_return([])
        expect(s3_bucket).to receive(:store_file_contents!).with("#{exporter.file_path('categories.json')}", JSON.generate(categories: category_map))
        exporter.write_categories_json('categories.xlsx')
      end
    end
  end
end
