require 'requests/login_helper_methods'

describe Gradebook::Standards::SectionReportController do
  let(:module_prefix) { Gradebook::Standards }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:standard_sets) { create_list(:standard_set, 4) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:student) { create(:student) }
  let(:standard) { create(:standard) }
  let(:unit) { create(:unit, program:) }

  before do
    create(:program_config_with_standard_sets, program:)
    course.standard_sets << standard_sets
    section.current_students_base << [student]
    log_in_user_with_access_to_programs(instructor, [program])
  end

  describe 'GET /index' do
    let(:target_path) do
      gradebook_standards_landing_page_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id,
        unit_id: unit.id,
        unit_name: unit.name,
        standard_guid: standard.vendor_guid
      )
    end

    def do_request
      post target_path
    end

    it 'is successful' do
      do_request
      expect(response).to be_successful
    end

    it 'assigns @data_for_student_detail_report' do
      do_request
      expected_data = {
        standard_guid: standard.vendor_guid,
        unit: {
          id: unit.id.to_s,
          name: unit.name
        }
      }
      expect(assigns(:data_for_student_detail_report)).to eq(expected_data)
    end

    context 'when the program does not support standards,' do
      let(:program_2) { create(:program) }
      let(:course_2) { create(:course, owner: instructor, program: program_2) }
      let(:section_2) { create(:section, course: course_2, instructor:) }
      let(:target_path) do
        gradebook_standards_landing_page_path(
          course_id: course_2.id,
          program_id: program_2.id,
          section_id: section.id
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
      let(:program_2) { create(:program) }
      let(:course_2) { create(:course, owner: instructor, program: program_2) }
      let(:section_2) { create(:section, course: course_2, instructor:) }
      let(:target_path) do
        gradebook_standards_landing_page_path(
          course_id: course_2.id,
          program_id: program_2.id,
          section_id: section.id
        )
      end

      def do_request
        post target_path
      end

      before do
        log_in_user_with_access_to_programs(instructor, [program_2])
      end

      context 'with a course that has no selected standards' do
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

      context 'with a course that has selected standards' do
        before do
          create(:program_config_with_standard_sets, program: program_2)
          course_2.standard_sets << standard_sets
        end

        it 'allows the instructor to view the student detail report page' do
          do_request

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
