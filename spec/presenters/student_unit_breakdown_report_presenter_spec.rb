describe StudentUnitBreakdownReportPresenter do
  include RspecJsContentHelpers
  # these need to match the assessment_ids in the assessment_items JSON files
  let(:assessment_1) { create(:activity, cms_activity_id: 285669) }
  let(:assessment_2) { create(:activity, cms_activity_id: 285670) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:lesson) { program.units.first.lessons.first }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let!(:activity) { create(:activity, lesson: lesson) }

  let!(:section) do
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
      points_possible: 41,
      activity_type: 'exam'
    }
  end
  let!(:standards_exam_2) do
    create_activity_with_unit_lesson_and_concept(
      program,
      standards_exam_2_attrs
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

  let(:presenter) do
    described_class.new(
      section:,
      student:,
      standard_sets: [standard_set_cc],
      unit: lesson.unit
    )
  end

  let!(:attempt) { create(:attempt_completed, activity:standards_exam_1, section:, user: student) }


  def load_fixture(name)
    file_path = Rails.root.join('spec', 'fixtures', 'json', "#{name}.json")
    JSON.parse(File.read(file_path))
  end

  before do
    standards = load_fixture('standards_cc')
    Standard.create!(standards)

    standard_assets_1 = load_fixture('standard_assets_1')
    StandardAsset.create!(standard_assets_1)
    standard_assets_2 = load_fixture('standard_assets_2')
    StandardAsset.create!(standard_assets_2)

    standard_alignments_1 = load_fixture('standard_alignments_1')
    StandardAlignment.create!(standard_alignments_1)

    standard_alignments_2 = load_fixture('standard_alignments_2')
    StandardAlignment.create!(standard_alignments_2)

    standards_results_data_1 = load_fixture('standards_results_1').each do |standards_result|
      standards_result['section_id'] = section.id
      standards_result['user_id'] = student.id
    end
    StandardsResults.create!(standards_results_data_1)

    standards_results_data_2 = load_fixture('standards_results_2').each do |standards_result|
      standards_result['section_id'] = section.id
      standards_result['user_id'] = student.id
    end
    StandardsResults.create!(standards_results_data_2)

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

    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Activity).to receive(:proficiency_assessment?) do |activity|
      activity.in?([standards_exam_1, standards_exam_2])
    end
    # rubocop:enable RSpec/AnyInstance
    allow(program).to receive(:standard_grade_levels).and_return(%w[6 7])
  end

  describe '#range_breakdown_standards_counts' do
    it 'returns an array with number of standards per report level' do
      breakdown_results = presenter.range_breakdown_standards_counts
      expect(breakdown_results[:meeting]).to eq 3
      expect(breakdown_results[:progressing]).to eq 2
      expect(breakdown_results[:needs_some_support]).to eq 2
      expect(breakdown_results[:needs_moderate_support]).to eq 2
      expect(breakdown_results[:needs_high_support]).to eq 1
      expect(breakdown_results[:total_standards_assessed]).to eq 10
    end
  end

  describe '#range_breakdown_results' do
    it 'returns the standards, percent_ correct, and number of items for a specified range' do
      standards_results = presenter.range_breakdown_results(90, 100)
      expect(standards_results['80D60194-7440-11DF-93FA-01FD9CFF4B22'][:items_count]).to eq 2
      expect(standards_results['80D60194-7440-11DF-93FA-01FD9CFF4B22'][:percent_correct]).to eq 95
      standards_results = presenter.range_breakdown_results(60, 70)
      expect(standards_results['80CAA02E-7440-11DF-93FA-01FD9CFF4B22'][:percent_correct]).to eq 67
      expect(standards_results['80CAA02E-7440-11DF-93FA-01FD9CFF4B22'][:items_count]).to eq 3
    end
  end

  describe '#standard_unit_assessments_summary' do
    context  'when standard is mapped to assessment items in multiple assessments' do
      it 'returns the percent_ correct, number of items and list of items broken down by assessment ' do
        summary = presenter.standard_unit_assessments_summary('8074E404-7440-11DF-93FA-01FD9CFF4B22')
        expect(summary.keys).to contain_exactly(standards_exam_1.id, standards_exam_2.id)
        expect(summary[standards_exam_1.id][:label]).to eq 'Mid-Unit'
        expect(summary[standards_exam_2.id][:label]).to eq 'End-of-Unit'
        expect(summary[standards_exam_1.id][:items_count]).to eq 4
        expect(summary[standards_exam_1.id][:percent_correct]).to eq 100
        expect(summary[standards_exam_1.id][:assessment_item_guids]).to contain_exactly('8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e',
                                                                           '5f531235-490b-457b-9369-d7e09ca2b190',
                                                                           'acec2b30-ccec-445e-b8d9-54460309df00',
                                                                           '9a26e3fd-2b26-41f4-94e2-e6c65d01476d')
        expect(summary[standards_exam_2.id][:items_count]).to eq 1
        expect(summary[standards_exam_2.id][:percent_correct]).to eq 0.0
        expect(summary[standards_exam_2.id][:assessment_item_guids]).to contain_exactly('69d489ed-95fd-4411-a949-f6785c95be49')
      end
    end

    context  'when standard is mapped to assessment items in a single assessment' do
      it 'returns the percent_ correct, number of items and list of items for only one assessment ' do
        summary = presenter.standard_unit_assessments_summary('80CC8146-7440-11DF-93FA-01FD9CFF4B22')
        expect(summary.keys).to contain_exactly(standards_exam_1.id)
        expect(summary[standards_exam_1.id][:items_count]).to eq 2
        expect(summary[standards_exam_1.id][:percent_correct]).to eq 70
      end
    end
  end

  describe '#assessment' do
    it 'returns an assessment given its id' do
      expect(presenter.assessment(standards_exam_2.id)).to eq standards_exam_2
    end
  end

  describe '#current_student_attempt_for_assessment' do
    it 'returns the student\'s attempt for specified assessment' do
      expect(presenter.current_student_attempt_for_assessment(standards_exam_1)).to eq attempt
    end
  end

  describe '.standards_summary' do
    it 'returns the standards, percent_ correct, and number of items for all standards ' \
       'in proficiency assessments in the unit' do
      standards_results = presenter.send(:standards_summary)
      expect(standards_results['80D33112-7440-11DF-93FA-01FD9CFF4B22'][:items_count]).to eq 2
      expect(standards_results['80D33112-7440-11DF-93FA-01FD9CFF4B22'][:percent_correct]).to eq 68
    end
  end

  describe '.standards_in_range' do
    it 'returns the count of standards that have percent_correct in the specified range' do
      standards_in_range = expect(presenter.send(:standards_in_range, 90, 100).count).to eq 3
    end
  end
end
