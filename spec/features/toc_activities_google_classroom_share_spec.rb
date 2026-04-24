feature 'ToC Activities with Google Classroom Share button', js: true, chrome: true, clear_session_storage: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  def give_instructor_access_on_activities
    activities.each do |activity|
      give_instructor_access_to_toc(activity: activity)
    end
  end

  def give_instructor_access_on_activities_with_course
    activities.each do |activity|
      give_instructor_access_to_toc(activity: activity)
      CourseLibraryActivity.create(
        activity_id: activity.id,
        course_id: course.id,
        hidden: false
      )
    end
  end

  def google_classroom_column_visible
    expect(page).to have_selector('.test-col-gc-share')
  end

  def google_classroom_column_not_visible
    expect(page).to have_no_selector('.test-col-gc-share')
  end

  def google_classroom_button_visible_in_all_activities
    all_activities = all('.test-row-activities')
    expect(all_activities).not_to be_empty
    all_activities.each do |activity|
      within(activity) do
        expect(page).to have_selector('.test-google-classroom-btn iframe')
      end
    end
  end

  def google_classroom_button_not_visible_in_all_activities
    all_activities = all('.test-row-activities')
    expect(all_activities).not_to be_empty
    all_activities.each do |activity|
      within(activity) do
        expect(page).to have_no_selector('.test-google-classroom-btn')
      end
    end
  end

  context 'As an instructor when browsing the ToC' do
    
    let(:program) { create(:program) }
    let(:activities) {  create_activities_with_the_same_toc_location(program, 2, license_group_id: 1) }
    let(:old_timestamp) { DateTime.now.prev_day.utc }
    let(:new_timestamp) { DateTime.now.next_day.utc }

    context 'and if course is not set' do
      before do
        give_instructor_access_on_activities
        initialize_program_access_client_calls_for_instructor(instructor, program)
        log_in_as(instructor)
        page.execute_script('sessionStorage.clear();')
      end
      
      context 'and if Google Classroom configuration is Yes for school' do
        let(:school) { create(:school, share_to_google_classroom: true) }
        let(:instructor) { create(:instructor, schools: [school]) }
        
        scenario 'I can not see Share column and Google Classroom Share button' do
          visit instructor_toc_path(program)
          google_classroom_column_not_visible
          google_classroom_button_not_visible_in_all_activities
        end
      end
    end
    
    context 'and if course is set' do
      before do
        give_instructor_access_on_activities_with_course
        initialize_program_access_client_calls_for_instructor(instructor, program)
        log_in_as(instructor)
        page.execute_script('sessionStorage.clear();')
      end
      
      context 'and if Google Classroom configuration is Yes for school and Yes for course' do
        let(:district) { create(:district,
          share_to_google_classroom: true,
          share_to_google_classroom_last_updated_at: old_timestamp) }
        let(:school) { create(:school,
          share_to_google_classroom: true,
          district_id: district.id,
          share_to_google_classroom_last_updated_at: new_timestamp) }
        let(:instructor) { create(:instructor, schools: [school]) }
        let(:course) { create(:course,
          owner: instructor,
          program: program,
          school: school,
          share_to_google_classroom: true) }
        
        scenario 'I can see Share column and Google Classroom Share buttons in each activity row' do
          visit instructor_toc_path(program)
          google_classroom_column_visible
          google_classroom_button_visible_in_all_activities
        end
      end

      context 'and if Google Classroom configuration is Yes for school and Yes for course' do
        context 'and if Google Classroom configuration is No for district and district timestamp is latest' do
          let(:district) { create(:district,
            share_to_google_classroom: false, 
            share_to_google_classroom_last_updated_at: new_timestamp) }
          let(:school) { create(:school,
            share_to_google_classroom: true,
            district_id: district.id,
            share_to_google_classroom_last_updated_at: old_timestamp) }
          let(:instructor) { create(:instructor, schools: [school]) }
          let(:course) { create(:course,
            owner: instructor,
            program: program,
            school: school,
            share_to_google_classroom: true) }
          
          scenario 'I can not see Share column and Google Classroom Share button' do
            visit instructor_toc_path(program)
            google_classroom_column_not_visible
            google_classroom_button_not_visible_in_all_activities
          end
        end
      end

      context 'and if Google Classroom configuration is Yes for school and No for course' do
        let(:district) { create(:district,
          share_to_google_classroom: true,
          share_to_google_classroom_last_updated_at: old_timestamp) }
        let(:school) { create(:school,
          share_to_google_classroom: true,
          district_id: district.id,
          share_to_google_classroom_last_updated_at: new_timestamp) }
        let(:instructor) { create(:instructor, schools: [school]) }
        let(:course) { create(:course,
          owner: instructor,
          program: program,
          school: school,
          share_to_google_classroom: false) }
        
        scenario 'I can not see Share column and Google Classroom Share button' do
          visit instructor_toc_path(program)
          google_classroom_column_not_visible
          google_classroom_button_not_visible_in_all_activities
        end
      end
      
      context 'and if Google Classroom configuration is No for school and Yes for course' do
        let(:district) { create(:district,
          share_to_google_classroom: true,
          share_to_google_classroom_last_updated_at: old_timestamp) }
        let(:school) { create(:school,
          share_to_google_classroom: false,
          district_id: district.id,
          share_to_google_classroom_last_updated_at: new_timestamp) }
        let(:instructor) { create(:instructor, schools: [school]) }
        let(:course) { create(:course,
          owner: instructor,
          program: program,
          school: school, share_to_google_classroom: true) }
        
        scenario 'I can not see Share column and Google Classroom Share button' do
          visit instructor_toc_path(program)
          google_classroom_column_not_visible
          google_classroom_button_not_visible_in_all_activities
        end
      end

      context 'and if Google Classroom configuration is No for school and Yes for course' do
        context 'and if Google Classroom configuration is Yes for district and district timestamp is latest' do
          let(:district) { create(:district,
            share_to_google_classroom: true,
            share_to_google_classroom_last_updated_at: new_timestamp) }
          let(:school) { create(:school,
            share_to_google_classroom: false,
            district_id: district.id,
            share_to_google_classroom_last_updated_at: old_timestamp) }
          let(:instructor) { create(:instructor, schools: [school]) }
          let(:course) { create(:course,
            owner: instructor,
            program: program,
            school: school,
            share_to_google_classroom: true) }
          
          scenario 'I can see Share column and Google Classroom Share buttons in each activity row' do
            visit instructor_toc_path(program)
            google_classroom_column_visible
            google_classroom_button_visible_in_all_activities
          end
        end
      end

      context 'and if Google Classroom configuration is No for school and No for course' do
        let(:district) { create(:district,
          share_to_google_classroom: true,
          share_to_google_classroom_last_updated_at: old_timestamp) }
        let(:school) { create(:school,
          share_to_google_classroom: false,
          district_id: district.id,
          share_to_google_classroom_last_updated_at: new_timestamp) }
        let(:instructor) { create(:instructor, schools: [school]) }
        let(:course) { create(:course, owner: instructor, program: program, school: school, share_to_google_classroom: false) }
        
        scenario 'I can not see Share column and Google Classroom Share button' do
          visit instructor_toc_path(program)
          google_classroom_column_not_visible
          google_classroom_button_not_visible_in_all_activities
        end
      end
    end
  end
end
