describe StandardsReports::SingleStudentDetailReportRow do
  MockArel = Struct.new(:cms_activity_id, :results_data, :user_id)

  let(:standards_results) do
    json = File.read('spec/fixtures/json/standards_results.json')
    records = JSON.parse(json).map(&:symbolize_keys)
    records.map do |record|
      MockArel.new(
        record[:cms_activity_id],
        record[:results_data],
        record[:user_id]
      )
    end
  end

  let(:assessment) { create(:activity, cms_activity_id: standards_results[0].cms_activity_id) }
  let(:user) { build_stubbed(:student) }
  let(:guids) do
    standards_results.first[:results_data].keys.last(4)
  end

  let(:standard_info) do
    StandardsReports::SectionReportCollection::StandardInfo.new(
      label: 'CCSS.ELA-Literacy.L.7.1', guids:
    )
  end

  let(:report_row) do
    described_class.new(guid: guids[3], record: standards_results[0], activity: assessment, standard: standard_info)
  end

  describe '#percent_correct' do
    it 'returns a floating point number' do
      # allow(report_row).to receive(:points_earned).and_return(2.5)
      expect(report_row.percent_correct).to eq(70.0)
    end

    it 'returns a whole number for a perfect score' do
      allow(report_row).to receive(:points_earned).and_return(4)

      expect(report_row.percent_correct).to eq(100)
    end
  end

  describe '#points_possible' do
    it 'returns the points_possible for the assessment item represented by the guid in the row' do
      expect(report_row.points_possible).to eq(4)
    end
  end

  describe '#points_earned' do
    it 'returns the points_earned for the assessment item represented by the guid in the row' do
      expect(report_row.points_earned).to eq(2.8)
    end
  end

  describe '#percent_correct_within_range?' do
    it 'returns false for percent correct <= 59' do
      expect(report_row.percent_correct_within_range?(0, 59)).to be_falsey
    end

    it 'returns false for percent correct >= 60 and < 70' do
      expect(report_row.percent_correct_within_range?(60, 69)).to be_falsey
    end

    it 'returns true for for percent correct >= 70 and < 80' do
      expect(report_row.percent_correct_within_range?(70, 79)).to be_truthy
    end

    it 'returns false for percent correct >= 80 and < 90' do
      expect(report_row.percent_correct_within_range?(80, 89)).to be_falsey
    end

    it 'returns false for percent correct >= 90' do
      expect(report_row.percent_correct_within_range?(90, 100)).to be_falsey
    end
  end

  describe '#add_data' do
    let(:activity) { build_stubbed(:activity) }
    let(:user) { build_stubbed(:student) }
    let(:guid) { SecureRandom.uuid }

    let(:standard_info) do
      StandardsReports::SectionReportCollection::StandardInfo.new(
        label: 'CCSS.ELA-Literacy.L.7.1', guids: [guid]
      )
    end

    let(:standards_results) do
      build_stubbed(
        :standards_results,
        cms_activity_id: activity.cms_activity_id,
        results_data: {
          guid => {
            'question_label' => 'question_06',
            'points_earned' => 3.5,
            'points_possible' => 4
          }
        },
        user_id: user.id
      )
    end

    let(:row) { described_class.new(guid:, record: standards_results , activity:, standard: standard_info) }

    it 'ingests a StandardsResults object' do
      row.add_data(standards_results, guid)

      expect(row.data_set.first.results_data.points_earned).to eq(3.5)
      expect(row.data_set.first.results_data.points_possible).to eq(4)
    end
  end
end
