feature 'ToC Visible Activities', js: true, chrome: true, clear_session_storage: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let!(:program) { create(:program) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activities) {  create_activities_with_the_same_toc_location(program, 2, license_group_id: 1) }
  let(:assigned_activity) { activities.first }
  let(:unassigned_activity) { activities.second }
  let(:due_date) { Time.zone.today }

  before do
    create(
      :assignment,
      assignable: assigned_activity,
      assignable_type: 'Activity',
      due_date: due_date,
      section: section
    )
    activities.each do |activity|
      give_instructor_access_to_toc(activity: activity)
      CourseLibraryActivity.create(
        activity_id: activity.id,
        course_id: course.id,
        hidden: false
      )
    end
  end

  def non_assigned_activities_should_be_visible
    non_assigned_activities = all('.js-non-assigned-activity')
    expect(non_assigned_activities).not_to be_empty
    non_assigned_activities.each do |activity|
      expect(activity).to be_visible
    end
  end

  def non_assigned_activities_should_not_be_visible
    non_assigned_activities = all('.js-non-assigned-activity')
    expect(non_assigned_activities).not_to be_empty
    non_assigned_activities.each do |activity|
      expect(activity).not_to be_visible
    end
  end

  def choose_visibility(assigned_status:)
    find(".js-visibility-selector option[value='#{assigned_status}']").select_option
  end

  context 'As an instructor' do
    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
      page.execute_script('sessionStorage.clear();')
    end

    context 'when browsing the ToC' do
      scenario 'I can choose to show all or only assigned activities' do
        visit instructor_toc_path(
          program,
          display_lesson: assigned_activity.lesson_id,
          toc_location: assigned_activity.toc_location
        )

        non_assigned_activities_should_be_visible
        choose_visibility(assigned_status: 'assigned')
        non_assigned_activities_should_not_be_visible
      end
    end

    context 'when browsing the assessments ToC' do
      before do
        program.lessons.each do |lesson|
          lesson.toc_entries.each { |toc_entry| toc_entry.assessment = true }
          lesson.save!
        end
        visit instructor_assessments_path(
          program,
          display_lesson: assigned_activity.lesson_id,
          toc_location: assigned_activity.toc_location
        )
      end

      scenario 'I can choose to show all or only assigned assessments' do
        non_assigned_activities_should_be_visible
        choose_visibility(assigned_status: 'assigned')
        non_assigned_activities_should_not_be_visible
      end
    end
  end

  context 'As a student' do
    let(:student) { create(:student) }

    before do
      initialize_program_access_client_calls_for_user_and_program(student, program)
      give_user_access_to_program(student, program)
      log_in_as(student)
      page.execute_script('sessionStorage.clear();')
      visit section_toc_path(section.id, program)
    end

    context 'when browsing the ToC' do
      scenario 'I can choose to show all or only assigned activities', new_gb_sync: true do
        non_assigned_activities_should_not_be_visible
        choose_visibility(assigned_status: 'all')
        non_assigned_activities_should_be_visible
      end
    end
  end
end
