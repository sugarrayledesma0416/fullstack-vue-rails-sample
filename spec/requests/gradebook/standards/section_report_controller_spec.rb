require 'requests/login_helper_methods'

describe Gradebook::Standards::SectionReportController do
  let(:module_prefix) { Gradebook::Standards }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }

  let(:standard_sets) { create_list(:standard_set, 4) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:student) { create(:student) }

  before do
    create(:program_config_with_standard_sets, program: program)
    section.current_students_base << [student]
    course.standard_sets << standard_sets
    log_in_user_with_access_to_programs(instructor, [program])
  end

  describe 'GET /index' do
    let(:target_path) do
      gradebook_standards_landing_page_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id
      )
    end

    def do_request
      post target_path
    end

    context 'when the program does not support standards,' do
      let(:program_2) { create(:program) }
      let(:course_2) { create(:course, owner: instructor, program: program_2) }
      let(:section_2) { create(:section, course: course_2, instructor: instructor) }
      let(:target_path) do
        gradebook_standards_landing_page_path(
          course_id: course_2.id,
          program_id: program_2.id,
          section_id: section_2.id
        )
      end

      def do_request
        post target_path
      end

      before do
        log_in_user_with_access_to_programs(instructor, [program_2])
      end

      it 'redirects to analitics overview page' do
        do_request

        expect(response).to redirect_to(
          gradebook_engine.course_section_analytics_overview_path
        )
        expect(flash[:error]).to eq(
          'This program does not support standards'
        )
      end
    end

    context 'when the program supports standards,' do
      let(:course_3) { create(:course, owner: instructor, program: program) }
      let(:section_3) { create(:section, course: course_3, instructor: instructor) }
      let(:target_path) do
        gradebook_standards_landing_page_path(
          course_id: course_3.id,
          program_id: program.id,
          section_id: section_3.id
        )
      end

      def do_request
        post target_path
      end

      before do
        section_3.current_students_base << [student]
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'with a course that has no selected standards' do
        it 'shows error message' do
          do_request

          expect(flash[:error]).to eq('This course does not support standards')
        end
      end

      context 'with a course that has selected standards' do
        before do
          course_3.standard_sets << standard_sets
        end
      end
    end
  end

  describe 'POST report' do
    let(:activity) { create(:activity) }

    def target_path(opts = {})
      gradebook_standards_section_report_path(
        {
          assessment_ids: activity.id.to_s,
          lesson_id: lesson.id,
          standard_set_display_name: standard_sets[0].display_name,
          course_id: course.id,
          program_id: program.id,
          section_id: section.id
        }.merge(opts)
      )
    end

    def do_request(opts = {})
      post target_path(opts)
    end

    it 'renders an error when params are invalid' do
      post gradebook_standards_section_report_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id
      )

      expect(response).not_to be_successful
      expect(response.body).to include('Invalid parameter(s)')
    end

    it 'is successful with proper params' do
      do_request

      expect(response).to be_successful
    end

    it 'creates a presenter' do
      allow(module_prefix::SectionReportPresenter).to receive(:new).and_call_original
      do_request

      expect(module_prefix::SectionReportPresenter).to have_received(:new).with(
        assessment_ids: activity.id.to_s,
        lesson_id: lesson.id.to_s,
        program: program,
        section: section,
        standard_set_display_name: standard_sets[0].display_name
      )
    end

    it 'passes sort params to the presenter' do
      allow(module_prefix::SectionReportPresenter).to receive(:new).and_call_original
      do_request(sort: activity.id.to_s, direction: 'asc')

      expect(module_prefix::SectionReportPresenter).to have_received(:new).with(
        assessment_ids: activity.id.to_s,
        direction: 'asc',
        lesson_id: lesson.id.to_s,
        program: program,
        section: section,
        sort: activity.id.to_s,
        standard_set_display_name: standard_sets[0].display_name
      )
    end
  end

  describe 'GET assessments' do
    let(:pa_concept) { create(:concept, name: 'Proficiency Assessment') }
    let(:pm_concept) { create(:concept, name: 'Progress Monitoring Assessment') }
    let(:other_concept) { create(:concept, name: 'Other Concept') }
    let!(:assessment) do
      create(:activity_with_json_content, title: 'Mid-Unit Assessment', lesson: lesson, concept: pa_concept)
    end
    let!(:pm_assessment) do
      create(:activity_with_json_content, title: 'Other Assessment', lesson: lesson, concept: pm_concept)
    end
    let!(:other_activity) { create(:activity, lesson: lesson, concept: other_concept) }
    let(:target_path) do
      gradebook_standards_assessments_per_unit_path(
        course_id: course.id.to_s,
        program_id: program.id.to_s,
        section_id: section.id.to_s,
        selected_lesson_id: lesson.id.to_s
      )
    end

    def do_request
      post target_path, xhr: true
    end

    it 'returns activities in the associated lesson that are proficiency assessments' do
      do_request

      expect(response).to be_successful
      expect(response.body).to include(assessment.title)
      expect(response.body).not_to include(other_activity.title)
    end

    it 'does not return activities in the associated lesson that are progress monitoring assessments' do
      do_request

      expect(response).to be_successful
      expect(response.body).not_to include(pm_assessment.title)
    end
  end
end
