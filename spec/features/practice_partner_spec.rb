feature 'Practice Partner App Message' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, title: 'Vistas, Fifth Edition') }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:course_licenses) { [] }
  let!(:activity) do
    create_activity_with_unit_lesson_concept_strand_and_substrand(
      program,
      instructor_revision_id: 70
    )
  end

  before do
    create(:section, course: course, instructor: instructor)
    allow_any_instance_of(AccessGuardian).to receive(:has_mobile_app?) { true }
    initialize_program_access_client_calls_for_instructor(instructor, program)
    give_instructor_access_to_toc
    log_in_as(instructor)
  end
end
