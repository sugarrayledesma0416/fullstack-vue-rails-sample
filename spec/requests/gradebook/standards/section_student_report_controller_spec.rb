require 'requests/login_helper_methods'

describe Gradebook::Standards::SectionStudentReportController do
  let(:module_prefix) { Gradebook::Standards }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:activity) { create(:activity, lesson: lesson) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:standard_set) { create(:standard_set) }
  let(:standard) do
    Standard.create(
      id: 4382,
      vendor_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
      vendor_standard_set_guid: standard_set.vendor_guid,
      name: 'English Language Arts/Literacy',
      description: 'Demonstrate command of the conventions of standard English ' \
                   'grammar and usage when writing or speaking.',
      label: 'Grade Level Standard',
      number: 'CCSS.ELA-Literacy.L.7.1'
    )
  end

  before do
    course.standard_sets << standard_set
    log_in_user_with_access_to_programs(instructor, [program])
  end

  describe 'GET /index' do
    def do_request
      get gradebook_standards_section_student_report_path(
        assessment_ids: activity.id,
        course_id: course.id,
        lesson_id: lesson.id,
        program_id: program.id,
        section_id: section.id,
        standard_id: standard.id,
        standard_set_display_name: standard_set.display_name
      )
    end
  end
end
