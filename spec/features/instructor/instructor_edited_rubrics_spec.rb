feature 'Instructor-editing Rubrics', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let!(:activity) do
    create_composition_activity_with_rubric(program)
  end
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }
  let(:course_licenses) { [] }
  let!(:course_library_activity) do
    CourseLibraryActivity.create(
      activity_id: activity.id,
      course_id: course.id
    )
  end

  before do
    lesson = activity.lesson
    lesson.strands.each do |strand|
      next if Concept.where(id: strand.location).exists?

      create_concept_matching_strand_id(strand, name: strand.title, lesson: lesson)
    end

    give_instructor_access_to_toc
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'Instructor edits an activity with a rubric' do
    # Override Activity.filepath_from_revision_id stubs created by
    # the call to create_composition_activity_with_rubric.
    allow(Activity).to receive(:filepath_from_revision_id).with(
      anything, true, false
    ).and_call_original
    visit instructor_toc_path(program)

    copy_link = "a#copy_rubric_link_#{activity.id}"
    expect(page).to have_selector(copy_link)
  end
end
