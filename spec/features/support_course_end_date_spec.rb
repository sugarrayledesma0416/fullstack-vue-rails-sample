feature 'Support edit course end date', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers

  scenario 'As a support rep, i can set a course end date in the past' do
    user = create(:user)
    course = create(:course)

    initialize_client_calls_for_user(user)
    log_in_as(user)

    purpose 'i can not access a tool without a support rep role' do
      step 'give user the wrong role' do
        user.roles << Role.create!(name: Role::SUPPORT_VENDOR)
      end

      visit support_courses_path
      expect(page).to have_content('FORBIDDEN')
    end

    purpose 'i can see a page with a form for an id' do
      step 'give user the right role' do
        user.roles << Role.create!(name: Role::SUPPORT_REP)
      end

      step 'visit the index page' do
        visit support_courses_path
      end
      expect(page).to have_field('Course id')
    end

    invalid_course_id = 0

    purpose 'i can input an invalid course id on the form and submit' do
      fill_in('Course id', with: invalid_course_id)
      click_button('Submit')
    end

    purpose 'i see an error message and i am redirected to the index page' do
      expect_flash_message(
        :error,
        "No course with id #{invalid_course_id} found"
      )
      step 'i am on the index page' do
        expect(page).to have_field('Course id')
      end
    end

    purpose 'i can input a valid course id on the form and submit' do
      fill_in('Course id', with: course.id)
      click_button('Submit')
    end

    purpose 'i should see a course with the searched id' do
      step 'i see the searched course' do
        expect(page).to have_content(course.id)
      end
      expect(page).to have_field('End date')
    end

    invalid_date_1 = 'MarioBrothers'
    invalid_date_2 = '33-25-2390'

    purpose 'i can input an invalid date in the course end date field' do
      fill_in('End date', with: invalid_date_1)
      click_button('Submit')
      expect_flash_message(:error, "#{invalid_date_1} is an invalid date.")

      step 'i am on the edit page' do
        expect(page).to have_field('End date')
      end

      fill_in('End date', with: invalid_date_2)
      click_button('Submit')
      expect_flash_message(:error, "#{invalid_date_2} is an invalid date.")

      step 'i am on the edit page' do
        expect(page).to have_field('End date')
      end
    end

    end_date_in_past = 1.days.ago.to_date

    purpose 'i can input a valid date in the course end date field' do
      fill_in('End date', with: end_date_in_past)
      click_button('Submit')
      expect_flash_message(
        :notice,
        "Course id: #{course.id} updated with new end date: #{end_date_in_past}."
      )

      step 'i am on the edit page' do
        expect(page).to have_field('End date')
      end

      step 'i can see the changed date on the database' do
        course.reload
        expect(course.end_date).to eq(end_date_in_past)
      end
    end
  end
end
