describe StandardsReports::StudentDetailReportRow do
  MockArel = Struct.new(:cms_activity_id, :results_data, :user_id)

  let(:standards_results) do
    json = File.read('spec/fixtures/json/standards_results.json')
    student_results = JSON.parse(json).map(&:symbolize_keys).first
    [
      MockArel.new(
        student_results[:cms_activity_id],
        student_results[:results_data],
        student.id
      )
    ]
  end

  let(:cms_activity_id) { standards_results.pick(:cms_activity_id) }

  let(:guids) do
    standards_results.first[:results_data].keys.last(4)
  end

  let(:student) { create(:student, first_name: 'Jeff', last_name: 'Dunham') }

  let(:student_info) do
    StandardsReports::StudentDetailReportCollection::StudentInfo.new(
      name: 'Dunham, Jeff',
      user_id: student.id
    )
  end

  let(:standard_info) do
    StandardsReports::SectionReportCollection::StandardInfo.new(
      label: 'CCSS.ELA-Literacy.L.7.1', guids: guids
    )
  end

  let(:report_row) do
    row = described_class.new(student: student_info, standard: standard_info, activities: [cms_activity_id])
    standards_results.each do |sr|
      guids.each do |guid|
        row.add_data(sr, guid)
      end
    end
    row
  end

  describe '#percent_correct' do
    it 'returns a floating point number' do
      expect(report_row.percent_correct_by_activity(cms_activity_id)).to eq(66.0)
    end

    it 'returns a whole number for a perfect score' do
      allow(report_row).to receive(:average_points_achieved_by_activity).and_return(10)
      allow(report_row).to receive(:points_possible_by_activity).and_return(10)

      expect(report_row.percent_correct_by_activity(cms_activity_id)).to eq(100)
    end

    it 'returns nil when there is no data' do
      report_row = described_class.new(student: student_info, standard: standard_info)

      expect(report_row.percent_correct_by_activity(cms_activity_id)).to be_nil
    end
  end

  describe '#total_number_of_items' do
    it 'contains the number_of_items for a standard' do
      expect(report_row.total_number_of_items).to eq(4)
    end

    it 'returns zero when there is no data' do
      report_row = described_class.new(student: student_info, standard: standard_info)

      expect(report_row.total_number_of_items).to be_zero
    end
  end

  describe '#assessment_summary' do
    it 'generates an assessment_summary as an array' do
      expect(report_row.assessment_summary(cms_activity_id)).to eq([6.6, 10])
    end

    it 'returns an empty array when there is no data' do
      report_row = described_class.new(student: student_info, standard: standard_info, activities: [cms_activity_id])

      expect(report_row.assessment_summary(cms_activity_id)).to eq([])
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

    let(:row) { described_class.new(student: student_info, standard: standard_info) }

    it 'ingests a StandardsResults object' do
      row.add_data(standards_results, guid)

      expect(row.data_set.first.results_data.points_earned).to eq(3.5)
      expect(row.data_set.first.results_data.points_possible).to eq(4)
    end
  end
end
