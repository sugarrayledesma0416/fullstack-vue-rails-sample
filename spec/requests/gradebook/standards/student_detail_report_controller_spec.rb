require 'requests/login_helper_methods'

describe Gradebook::Standards::StudentDetailReportController do
  let(:module_prefix) { Gradebook::Standards }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, unit:) }
  let(:standard_sets) { create_list(:standard_set, 4) }
  let(:standard) { create(:standard) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:student) { create(:student) }

  before do
    create(:program_config_with_standard_sets, program:)
    course.standard_sets << standard_sets
    log_in_user_with_access_to_programs(instructor, [program])
  end

  describe 'GET /index' do
    let(:target_path) do
      gradebook_standards_student_detail_report_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id,
        standard_set_id: standard_sets.first.id,
        student_id: student.id,
        standard_guid: standard.vendor_guid,
        unit_id: unit.id,
        unit_name: unit.name
      )
    end

    def do_request
      get target_path
    end

    context 'when the program does not support standards,' do
      let(:program_2) { create(:program) }
      let(:course_2) { create(:course, owner: instructor, program: program_2) }
      let(:section_2) { create(:section, course: course_2, instructor:) }
      let(:target_path) do
        gradebook_standards_student_detail_report_path(
          course_id: course_2.id,
          program_id: program_2.id,
          section_id: section_2.id,
          standard_set_id: standard_sets.first.id,
          student_id: student.id
        )
      end

      def do_request
        get target_path
      end

      before do
        log_in_user_with_access_to_programs(instructor, [program_2])
      end
    end

    context 'when the program supports standards,' do
      let(:course_3) { create(:course, owner: instructor, program:) }
      let(:section_3) { create(:section, course: course_3, instructor:) }
      let(:target_path) do
        gradebook_standards_student_detail_report_path(
          course_id: course_3.id,
          program_id: program.id,
          section_id: section_3.id,
          standard_set_id: standard_sets.first.id,
          student_id: student.id
        )
      end

      def do_request
        get target_path
      end

      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end
    end
  end
end
