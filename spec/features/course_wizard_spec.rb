# -*- coding: utf-8 -*-
feature 'Course wizard', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons, language_code: 'es') }
  let(:old_course) { create(:course, start_date: 1.month.ago, end_date: 5.days.ago) }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    course_packages = { 'level' => [double(Maestro::CoursePackage,  response: { "id" => 123,
                                                                                "program_id" => program.id,
                                                                                "name" => "Supersite",
                                                                                "rank" => 1,
                                                                                "content_type" => "level" } ) ] }
    allow(Maestro::CoursePackage).to receive_message_chain(:all, :group_by).with(program.id).and_return(course_packages)
    instructor.schools << school
    log_in_as(instructor)
  end

  scenario 'As an instructor, I can choose to copy instructor-created activities
            from a previous course in the add course wizard.', js: true do

    visit instructor_new_course_path(program, school)

  end

end
