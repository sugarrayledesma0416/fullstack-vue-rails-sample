describe StandardsReports::AssessmentSupport do
  let(:activity_1) { create(:activity) }
  let(:program) { create(:program) }
  let(:course) { create(:course, program: program) }
  let(:section) { create(:section_with_enrollments, course:) }
  let(:enrolled_student) { section.real_students_base.first }
  let(:standard_set) { create(:standard_set) }
  let(:standards) { create_list(:standard, 3, standard_set:) }
  let(:section_collection) do
    [
      StandardsReports::SectionReportCollection.new(
        activities: [activity_1],
        section:,
        standard_sets: [standard_set]
      )
    ]
  end
  let(:assessment_item) { create(:assessment_item_with_assessment, assessment: activity_1) }
  let(:results_data_1) do
    {
      assessment_item.guid => {
        question_label: 'question_01',
        points_earned: 2,
        points_possible: 2
      }
    }
  end
  let(:standard_asset) { create(:standard_asset_assessment_item, assessment_item:) }
  let(:reporter) { described_class.new(collections: section_collection) }

  before do
    standards.each do |standard|
      create(:standard_alignment, standard_asset:, standard:)
    end
    create(
      :standards_results,
      section_id: section.id,
      cms_activity_id: activity_1.cms_activity_id,
      user_id: enrolled_student.id,
      results_data: results_data_1
    )
    allow(program).to receive(:standard_grade_levels).and_return(%w[6 7 8])
  end

  RSpec.shared_context 'set up second assessment' do
    let(:activity_2) { create(:activity) }
    let(:assessment_item_2) { create(:assessment_item_with_assessment, assessment: activity_2) }
    let(:results_data_2) do
      {
        assessment_item_2.guid => {
          question_label: 'question_01',
          points_earned: 3,
          points_possible: 4
        }
      }
    end
    let(:standard_asset_2) do
      create(:standard_asset_assessment_item, assessment_item: assessment_item_2)
    end
    let(:section_report_collection) do
      StandardsReports::SectionReportCollection.new(
        activities: [activity_2],
        section:,
        standard_sets: [standard_set]
      )
    end

    before do
      standards.each do |standard|
        create(:standard_alignment, standard_asset: standard_asset_2, standard:)
      end
      create(
        :standards_results,
        section_id: section.id,
        cms_activity_id: activity_2.cms_activity_id,
        user_id: section.real_students_base.second.id,
        results_data: results_data_2
      )
    end
  end

  shared_examples 'single assessment report' do
    it 'returns the standard associated' do
      expect(first_row.standard).to eq(standards.first)
    end

    it 'returns the total number of items associated' do
      expect(first_row.total_number_of_items).to eq(1)
    end

    it 'returns the percent correct associated' do
      expect(first_row.assessments_result.percent_correct).to eq(100)
    end

    it 'returns the points earned and points possible values' do
      expect(first_row.assessments_result.assessment_summary).to eq([2.0, 2])
    end

    it 'returns nil in the total information' do
      expect(first_row.total).to be_nil
    end
  end

  shared_examples 'multiple assessments report' do
    it 'returns the standard associated' do
      expect(first_row.standard).to eq(standards.first)
    end

    it 'returns the total number of items associated' do
      expect(first_row.total_number_of_items).to eq(2)
    end

    it 'returns the percent correct associated to the first assessment' do
      expect(first_row.assessments_result.first.percent_correct).to eq(100)
    end

    it 'returns the points earned and points possible values for the first assessment' do
      expect(first_row.assessments_result.first.assessment_summary).to eq([2.0, 2])
    end

    it 'returns the percent correct associated to the second assessment' do
      expect(first_row.assessments_result.second.percent_correct).to eq(75)
    end

    it 'returns the points earned and points possible values for the second assessment' do
      expect(first_row.assessments_result.second.assessment_summary).to eq([3.0, 4])
    end

    it 'returns the total percent correct' do
      expect(first_row.total.percent_correct).to eq(83)
    end

    it 'returns the total points earned and points possible values' do
      expect(first_row.total.assessment_summary).to eq([5.0, 6])
    end
  end

  shared_examples 'assessments sorting' do
    # We can not rely on the assessment name to order them. The toc_location_rank
    # attribute might be a better attribute to achieve this.
    it 'saves the assessments in a the toc_location_rank order' do
      assessments_sorted = [activity_1, activity_2].sort_by(&:toc_location_rank)
      assessments_ids = assessments_sorted.pluck(:id)

      # Checking all the rows in the report
      report.each do |row|
        report_assessments_ids = row.assessments_result.map do |result|
          result.assessment.id
        end

        assessment_ids_in_report = assessments_ids.intersection(report_assessments_ids)

        expect(report_assessments_ids).to eq(assessment_ids_in_report)
      end
    end
  end

  describe '#report' do
    context 'with one assessment selected' do
      let(:first_row) { reporter.report.first }

      include_examples 'single assessment report'
    end

    context 'with two assessments selected' do
      include_context 'set up second assessment'

      let(:report) { reporter.report }
      let(:first_row) { report.first }

      before do
        section_collection << section_report_collection
      end

      include_examples 'multiple assessments report'
      include_examples 'assessments sorting'

      context 'when a standard does not have results in one assessment' do
        before do
          StandardsResults.last.delete
        end

        it 'returns the right total percent correct information' do
          expect(first_row.total.percent_correct).to eq(100)
        end

        it 'returns the right total assessment summary information' do
          expect(first_row.total.assessment_summary).to eq([2.0, 2])
        end
      end

      context 'when a standard does not have results in any of the assessment' do
        before do
          StandardsResults.delete_all
        end

        it 'returns the right total percent correct information' do
          expect(first_row.total.percent_correct).to be_nil
        end

        it 'returns the right total assessment summary information' do
          expect(first_row.total.assessment_summary).to eq([nil, nil])
        end
      end

      context 'when a standard is not aligned with an assessment' do
        let(:last_row) { reporter.report.last }

        before do
          StandardAlignment.last.delete
        end

        include_examples 'assessments sorting'

        it 'returns the right total percent correct information' do
          expect(last_row.total.percent_correct).to eq(100)
        end

        it 'returns the right total assessment summary information' do
          expect(last_row.total.assessment_summary).to eq([2.0, 2])
        end
      end

      context 'when a standard is not aligned with the first assessment' do
        before do
          StandardAlignment.first.delete
        end

        include_examples 'assessments sorting'
      end
    end
  end

  describe '#student_report' do
    let(:student_detail_collection) do
      [
        StandardsReports::StudentDetailReportCollection.new(
          activities: [activity_1],
          section:,
          standard: standards.first,
          standard_sets: [standard_set]
        )
      ]
    end
    let(:reporter) { described_class.new(collections: student_detail_collection) }

    context 'with one assessment selected' do
      let(:first_row) { reporter.student_report.first }

      it 'returns the first student associated in the report' do
        expect(first_row.student.user_id).to eq(enrolled_student.id)
      end

      include_examples 'single assessment report'
    end

    context 'with two assessments selected' do
      include_context 'set up second assessment'

      let(:enrolled_students) { section.real_students_base }
      let(:student_detail_collection) do
        [
          StandardsReports::StudentDetailReportCollection.new(
            activities: [activity_1],
            section:,
            standard: standards.first,
            standard_sets: [standard_set]
          ),
          StandardsReports::StudentDetailReportCollection.new(
            activities: [activity_2],
            section:,
            standard: standards.first,
            standard_sets: [standard_set]
          )
        ]
      end
      let(:reporter) { described_class.new(collections: student_detail_collection) }
      let(:report) { reporter.student_report }
      let(:first_row) { report.first }

      before do
        # To avoid key duplications, remove the current StandardsResults records and
        # create new ones for all the enrolled students
        StandardsResults.delete_all

        enrolled_students.each do |student|
          create(
            :standards_results,
            section_id: section.id,
            cms_activity_id: activity_1.cms_activity_id,
            user_id: student.id,
            results_data: results_data_1
          )

          create(
            :standards_results,
            section_id: section.id,
            cms_activity_id: activity_2.cms_activity_id,
            user_id: student.id,
            results_data: results_data_2
          )
        end
      end

      it 'returns the first student associated in the report' do
        expect(first_row.student.user_id).to eq(enrolled_students.first.id)
      end

      include_examples 'multiple assessments report'
      include_examples 'assessments sorting'

      context 'when a student does not have results in one assessment' do
        let(:student) { enrolled_students.first }

        before do
          StandardsResults.where(user_id: student.id).first.delete
        end

        include_examples 'assessments sorting'

        it 'returns the right total percent correct information' do
          expect(first_row.total.percent_correct).to eq(75)
        end

        it 'returns the right total assessment summary information' do
          expect(first_row.total.assessment_summary).to eq([3.0, 4])
        end
      end

      context 'when a student does not have results in any of the assessments' do
        let(:student) { enrolled_students.first }

        before do
          StandardsResults.where(user_id: student.id).delete_all
        end

        include_examples 'assessments sorting'

        it 'returns the right total percent correct information' do
          expect(first_row.total.percent_correct).to be_nil
        end

        it 'returns the right total assessment summary value' do
          expect(first_row.total.assessment_summary).to eq([nil, nil])
        end
      end
    end
  end
end
