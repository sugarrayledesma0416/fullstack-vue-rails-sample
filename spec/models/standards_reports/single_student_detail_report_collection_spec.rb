describe StandardsReports::SingleStudentDetailReportCollection do
  include RspecJsContentHelpers
  let(:assessment_1) { create(:activity) }
  let(:assessment_2) { create(:activity) }
  let(:assessment_3) { create(:activity) }
  let(:program) { create(:program) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:lesson) { create(:lesson) }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program_settings) { instance_double(ProgramSettings, standard_grade_levels: %w[6 7])  }

  let(:section) do
    create(:section, name: 'ELD Section 1', course:, instructor:)
  end

  let(:student) { create(:student) }

  let(:standards_exam_1_attrs) do
    {
      id: 835_536,
      title: 'Mid-Unit Assessment',
      component_name: 'Assessment',
      lesson_id: lesson.id,
      cms_activity_id: 285_669,
      toc_location_rank: 20,
      points_possible: 41,
      activity_type: 'exam'
    }
  end
  let!(:standards_exam_1) do
    create_activity_with_unit_lesson_and_concept(
      program,
      standards_exam_1_attrs
    )
  end

  let(:standards_exam_2_attrs) do
    {
      id: 835_537,
      title: 'End-of-Unit Assessment',
      component_name: 'Assessment',
      lesson_id: lesson.id,
      cms_activity_id: 285_670,
      toc_location_rank: 20,
      points_possible: 36,
      activity_type: 'exam'
    }
  end
  let!(:standards_exam_2) do
    create_activity_with_unit_lesson_and_concept(
      program,
      standards_exam_2_attrs
    )
  end

  let(:standards_exam_3_attrs) do
    {
      id: 835_538,
      title: 'End-of-Unit Assessment',
      component_name: 'Assessment',
      lesson_id: lesson.id,
      cms_activity_id: 285_671,
      toc_location_rank: 20,
      points_possible: 31,
      activity_type: 'exam'
    }
  end

  let!(:standards_exam_3) do
    create_activity_with_unit_lesson_and_concept(
      program,
      standards_exam_3_attrs
    )
  end

  let!(:standard_set_cc) do
    StandardSet.create(
      vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2010,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: 'CCSS'
    )
  end

  let(:report) do
    described_class.new(
      assessments: [standards_exam_1, standards_exam_2, standards_exam_3],
      section:,
      student:,
      standard_sets: [standard_set_cc]
    )
  end

  let(:sorted_report) do
    described_class.new(
      assessments: [standards_exam_1, standards_exam_2],
      section: ,
      student:,
      standard_sets: [standard_set_cc],
      direction: 'asc',
      sort: :cms_activity_id
    )
  end

  let(:percent_correct_sorted_report) do
    described_class.new(
      assessments: [standards_exam_1, standards_exam_2],
      section: ,
      student:,
      standard_sets: [standard_set_cc],
      direction: 'asc',
      sort: :percent_correct
    )
  end

  def load_fixture(name)
    file_path = Rails.root.join('spec', 'fixtures', 'json', "#{name}.json")
    JSON.parse(File.read(file_path))
  end

  before do
    allow(ProgramSettings).to receive(:new).with(program).and_return(program_settings)
    allow(program_settings).to receive(:supported_standard_sets).and_return([standard_set_cc])

    standards = load_fixture('standards_cc')
    Standard.create!(standards)

    standard_assets_1 = load_fixture('standard_assets_1')
    StandardAsset.create!(standard_assets_1)
    standard_assets_2 = load_fixture('standard_assets_2')
    StandardAsset.create!(standard_assets_2)
    standard_assets_3 = load_fixture('standard_assets_3')
    StandardAsset.create!(standard_assets_3)

    standard_alignments_1 = load_fixture('standard_alignments_1')
    StandardAlignment.create!(standard_alignments_1)

    standard_alignments_2 = load_fixture('standard_alignments_2')
    StandardAlignment.create!(standard_alignments_2)

    standard_alignments_3 = load_fixture('standard_alignments_3')
    StandardAlignment.create!(standard_alignments_3)


    standards_results_data_1 = load_fixture('standards_results_1').each do |standards_result|
      standards_result['user_id'] = student.id
      standards_result['section_id'] = section.id
    end
    StandardsResults.create!(standards_results_data_1)

    standards_results_data_2 = load_fixture('standards_results_2').each do |standards_result|
      standards_result['user_id'] = student.id
      standards_result['section_id'] = section.id
    end
    StandardsResults.create!(standards_results_data_2)

    # NOTE: no StandardsResults for assessment 3 so as to
    # represent the state of either "not submitted" or "pending
    # grading of instructor-graded question(s)"
    # For both states there will be no StandardsResults
    # so that assessment should not be represented in the
    # SingleStudentDetailReportCollection

    assessment_1_items = load_fixture('assessment_items_1')
    assessment_1_items.each do |assessment_item|
      vendor_guid = assessment_item['guid']
      standard_asset = StandardAsset.find_by(vendor_guid:)
      standard_asset.create_assessment_item(assessment_item)
    end

    assessment_2_items = load_fixture('assessment_items_2')
    assessment_2_items.each do |assessment_item|
      vendor_guid = assessment_item['guid']
      standard_asset = StandardAsset.find_by(vendor_guid:)
      standard_asset.create_assessment_item(assessment_item)
    end

    assessment_3_items = load_fixture('assessment_items_3')
    assessment_3_items.each do |assessment_item|
      vendor_guid = assessment_item['guid']
      standard_asset = StandardAsset.find_by(vendor_guid:)
      standard_asset.create_assessment_item(assessment_item)
    end

    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Activity).to receive(:standards_test?) do |activity|
      activity.in?([standards_exam_1, standards_exam_2])
    end
    # rubocop:enable RSpec/AnyInstance
  end

  describe '#report_rows' do
    it 'returns an array with assessment_items' do
      # these are the guids from both standard assets fixtures files
      expected_results = [
         "d80b6ed2-264f-4917-bb01-5107275e97c6",
         "7c41dd1b-bd6c-4ab5-9176-19b7f8cfadc0",
         "81279b26-19cc-42f4-94ed-d18a1dac6bc9",
         "9e792bf5-74f7-426d-a5d6-103ddbcf1d38",
         "56a5775a-589f-49d7-a922-506de373c4ba",
         "8ba67231-ea4e-43cc-99bd-cc9171c237ed",
         "93e1814e-1935-4591-95a3-d8ff9554c0bb",
         "eee7ea48-bfdd-4e41-8342-d53b165ce636",
         "ad3c1e29-447c-47cf-b89a-fa3d13488b88",
         "aa0b6a1c-206f-4192-932e-c980dcea572e",
         "a365d87f-1521-4733-a3fe-97f8b40f3236",
         "12ac65d6-ac41-4f79-8309-a10888712e3f",
         "e1c19962-18ea-4a5b-9675-4df13def5996",
         "6a99b9fd-fd76-4af8-8386-ad2140afa48b",
         "349552ff-7996-436c-9118-16edf2df8fb2",
         "a46ad2c1-d8fc-4da6-8315-5370891e88e1",
         "64d70de5-89f3-4653-a94c-905336f58f9b",
         "34b00ac9-37b7-4c1b-b866-be3f71e7cd88",
         "05c950e8-d0fa-47a5-abe1-0d43f0e9aa83",
         "6e3d3807-de76-478f-b51c-171f5f2ab755",
         "16f72018-ebf0-4b9d-b15f-78e1b2a06d90",
         "5a9c4e7e-75d8-46ae-b8ce-384fbb874480",
         "dfef4f16-1948-4133-9817-c9245fe2d4bb",
         "69d489ed-95fd-4411-a949-f6785c95be49",
         "8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e",
         "5f531235-490b-457b-9369-d7e09ca2b190",
         "acec2b30-ccec-445e-b8d9-54460309df00",
         "9a26e3fd-2b26-41f4-94e2-e6c65d01476d"
      ]
      expect(report.report_rows.map(&:guid)).to eq(expected_results)
    end

    it 'returns results data associated with all assessment items in both assessments' do
      expect(report.report_rows.map(&:points_earned)).to eq(
        [9.5, 1, 2.5, 3.75, 1, 1, 0, 10.8, 1, 1, 1, 0, 0, 1, 0, 12.5, 1, 1, 0, 1, 1, 2.8, 2.8, 0, 1, 1, 1, 1]
      )
    end

    it 'uses the sort by standard label as default' do
      expect(report.report_rows.map(&:standard).map(&:label)).to eq(
                                                                   ["A fake description with mor...",
                                                                    "A fake description with mor...",
                                                                    "CCSS.ELA-Literacy.L.7.1",
                                                                    "CCSS.ELA-Literacy.L.7.1",
                                                                    "CCSS.ELA-Literacy.L.7.1",
                                                                    "CCSS.ELA-Literacy.L.7.1",
                                                                    "CCSS.ELA-Literacy.L.7.2",
                                                                    "CCSS.ELA-Literacy.L.7.2",
                                                                    "CCSS.ELA-Literacy.RL.7.2",
                                                                    "CCSS.ELA-Literacy.RL.7.2",
                                                                    "CCSS.ELA-Literacy.RL.7.2",
                                                                    "CCSS.ELA-Literacy.RL.7.4",
                                                                    "CCSS.ELA-Literacy.RL.7.4",
                                                                    "CCSS.ELA-Literacy.RL.7.4",
                                                                    "CCSS.ELA-Literacy.RL.7.5",
                                                                    "CCSS.ELA-Literacy.RL.7.5",
                                                                    "CCSS.ELA-Literacy.RL.7.5",
                                                                    "CCSS.ELA-Literacy.SL.7.1",
                                                                    "CCSS.ELA-Literacy.SL.7.2",
                                                                    "CCSS.ELA-Literacy.SL.7.2",
                                                                    "CCSS.ELA-Literacy.SL.7.2",
                                                                    "CCSS.ELA-Literacy.SL.7.4",
                                                                    "CCSS.ELA-Literacy.SL.7.4",
                                                                    "zzFAKE.ELA-Literacy.RL.7.1",
                                                                    "zzFAKE.ELA-Literacy.RL.7.1",
                                                                    "zzFAKE.ELA-Literacy.RL.7.1",
                                                                    "zzFAKE.ELA-Literacy.RL.7.1",
                                                                    "zzFAKE.ELA-Literacy.RL.7.1"]
                                                                 )
    end

    it 'returns the rows that fall within the specified percent_correct range' do
      expect(report.rows_in_range(70, 79).count).to eq 3
    end

    it 'sorts by cms_activity id' do
      # not sorted by cms_activity_id
      expect(report.report_rows.map(&:cms_activity_id)).to  eq [285670, 285669, 285670, 285670, 285669, 285669, 285669, 285669, 285669, 285669, 285670, 285669, 285669, 285669, 285669, 285670, 285669, 285669, 285669, 285669, 285670, 285669, 285669, 285670, 285669, 285669, 285669, 285669]
      # this one is sorted by cms_activity_id
      expect(sorted_report.report_rows.map(&:cms_activity_id)).to  eq [285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285669, 285670, 285670, 285670, 285670, 285670, 285670, 285670]
    end

    it 'sorts by the secondary sort, percent_correct' do
      # not sorted by percent_correct
      expect(report.report_rows.map(&:percent_correct)).to  eq(
        [95, 100, 63, 94, 100, 100, 0, 72, 100, 100, 100, 0, 0, 100, 0, 83, 100, 100, 0, 100, 100, 70, 70, 0, 100, 100, 100, 100]
      )
      # sorted by percent_correct
      expect(percent_correct_sorted_report.report_rows.map(&:percent_correct)).to eq(
        [0, 0, 0, 0, 0, 0, 63, 70, 70, 72, 83, 94, 95, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100]
      )
    end

    it 'returns only rows for assessment items mapped to specified standard' do
      rows = report.rows_for_standard('80CAA02E-7440-11DF-93FA-01FD9CFF4B22')
      expect(rows.map(&:standard).pluck(:vendor_guid)).to eq ['80CAA02E-7440-11DF-93FA-01FD9CFF4B22', '80CAA02E-7440-11DF-93FA-01FD9CFF4B22', '80CAA02E-7440-11DF-93FA-01FD9CFF4B22']
    end

    it 'does not contain info about an assessment that is either pending or unsubmitted' do
      expect(
        report.report_rows.map(&:cms_activity_id)
      ).not_to include standards_exam_3.cms_activity_id
    end

    it 'does not contain a standard whose grade level does not match the any of ' \
         'the grades configured for the program' do
      expect(report.rows_for_standard('4008b6e6-b0a4-4e16-b802-a10f889b69f9')).to be_empty
    end
  end
end
