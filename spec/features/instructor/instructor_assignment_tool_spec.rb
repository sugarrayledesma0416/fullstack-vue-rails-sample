feature 'Instructor assignment tool', js: true, chrome: true, new_gb_sync: true, test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  scenario 'Instructor assignment tool' do
    step 'Database setup' do
      step 'Create a VOL program'

      step 'Create a course that start on 2018-12-01 and ends on 2019-02-28'
      step %q(Create an event named "New Year's Day" scheduled for 2019-01-01 on which class is cancelled)
      step 'Create an event named "Bean Day" scheduled for "2019-01-06" on which class is in session'
      step 'Create and assign a 20 minutes activity for 2018-12-15'
      step 'Create and assign a 50 minutes activity for 2018-12-15'
      step 'Create and assign a 8 minutes activity for 2018-12-15'
      step 'Create and assign a 7 minutes activity for 2018-12-16'
      step 'Create and assign a 10 minutes activity for 2018-12-16'

      step 'Create a course "New course"' do
        step 'Create a lesson "Lesson 1"' do
          step 'Create a strand "Strand 1"' do
            step 'Create a Component "Component 1"' do
              step 'Create a multiple choice activity "activity 1_1_1_1" taking 5 minutes to complete'
              step 'Create an open ended activity "activity 1_1_1_2"'
            end
            step 'Create a Component "Component 2"' do
              step 'Create a multiple choice activity "activity 1_1_2_1" taking 6 minutes to complete'
              step 'Create an drop down activity "activity 1_1_2_2"'
            end
          end
          step 'Create a strand "Strand 2"' do
            step 'Create a Component "Component 1"' do
              step 'Create an open ended activity "activity 1_2_1_1"'
              step 'Create a drop down activity "activity 1_2_1_2"'
            end
            step 'Create a Component "Component 2"' do
              step 'Create an open ended activity "activity 1_2_2_1"'
              step 'Create a multiple choice activity "activity 1_2_2_2" taking 9 minutes to complete'
            end
          end
        end
        step 'Create a lesson "Lesson 2"' do
          step 'Create a strand "Strand 1"' do
            step 'Create a Component "Component 1"' do
              step 'Create a multiple choice activity "activity 2_1_1_1"'
              step 'Create a drop down activity "activity 2_1_1_2"'
            end
            step 'Create a Component "Component 2"' do
              step 'Create an open ended activity "activity 2_1_2_1"'
              step 'Create an open ended activity "activity 2_1_2_2"'
            end
          end
          step 'Create a strand "Strand 2"' do
            step 'Create a Component "Component 1"' do
              step 'Create a multiple choice activity "activity 2_2_1_1"'
            end
          end
        end
      end
      step 'Create a course "Old course"' do
        step 'Create a section "Old section"' do
          step 'Assign "activity 1_1_1_1" in the second week of the course in category Homework'
          step 'Assign "activity 1_1_2_1" in the third week of the course in category Credit'
          step 'Assign "activity 1_2_2_2" in the third week of the course in category Homework'
        end
      end
    end

    step 'I log in as an instructor'
    step 'Visit the "Start Assigning" page'
    step 'Set the focus to the course "New course"'

    purpose 'I can filter activities by previously assigned' do
      purpose 'I can filter activities by previous section' do
        step 'Click on the "edit" button of the previous assigned filter'
        step 'Select "Old course - Old section" in the previous section drop down'
        step 'Click on the "apply" button'
        step 'I see 3 activities, "activity 1_1_1_1", "activity 1_1_2_1", "activity 1_2_2_2"'
      end
      purpose 'I can filter activities by category' do
        step 'Click on the "edit" button of the previous assigned filter'
        step 'Select "Homework" in the category drop down'
        step 'Click on the "apply" button'
        step 'I see 2 activities: "activity 1_1_1_1" and "activity 1_2_2_2"'
      end
      purpose 'I can filter activities by week' do
        step 'Click on the "edit" button of the previous assigned filter'
        step 'Select "All Categories" in the category drop down'
        step 'Select "Week 2" in the week drop down'
        step 'Click on the "apply" button'
        step 'I see activity "activity 1_1_1_1"'
      end
      step 'Click on the "edit" button of the previous assigned filter'
      step 'Select "None" in the previous section drop down'
      step 'Click on the "apply" button'
    end

    purpose 'I can filter activities by TOC location' do
      step 'Click on the "edit" button of the location filter'
      step 'Select "All lessons"'
      step 'The section drop down is disabled'
      step 'The component drop down is disabled'
      purpose 'I can filter activities by lesson' do
        step 'Click on the "apply" button'
        step 'I see activities of all the lessons'
        step 'Click on the "edit" button of the location filter'
        step 'Select "Lesson 1" in the lesson drop down'
        step 'The section drop down is enabled'
        step '"All Sections" is selected in the section drop down'
        step 'The component drop down is enabled'
        step '"All Components" is selected in the component drop down'
        step 'Click on the "apply" button'
        step 'I only see activities of the "lesson 1"' do
          step 'I see activity "activity 1_1_1_1"'
          step 'I see activity "activity 1_1_1_2"'
          step 'I see activity "activity 1_1_2_1"'
          step 'I see activity "activity 1_1_2_2"'
          step 'I see activity "activity 1_2_1_1"'
          step 'I see activity "activity 1_2_1_2"'
          step 'I see activity "activity 1_2_2_1"'
          step 'I see activity "activity 1_2_2_2"'
          step 'I do not see activity "activity 2_1_1_1"'
          step 'I do not see activity "activity 2_1_1_2"'
          step 'I do not see activity "activity 2_1_2_1"'
          step 'I do not see activity "activity 2_1_2_2"'
          step 'I do not see activity "activity 2_2_1_1"'
        end
      end
      purpose 'I can filter activities by strand' do
        step 'Click on the "edit" button of the location filter'
        step 'Select "Strand 1" in the section drop down'
        step 'Click on the "apply" button'
        step 'I see activity "activity 1_1_1_1"'
        step 'I see activity "activity 1_1_1_2"'
        step 'I see activity "activity 1_1_2_1"'
        step 'I see activity "activity 1_1_2_2"'
        step 'I do not see activity "activity 1_2_1_1"'
        step 'I do not see activity "activity 1_2_1_2"'
        step 'I do not see activity "activity 1_2_2_1"'
        step 'I do not see activity "activity 1_2_2_2"'
        step 'I do not see activity "activity 2_1_1_1"'
        step 'I do not see activity "activity 2_1_1_2"'
        step 'I do not see activity "activity 2_1_2_1"'
        step 'I do not see activity "activity 2_1_2_2"'
        step 'I do not see activity "activity 2_2_1_1"'
      end
      purpose 'I can filter activities by component' do
        step 'Click on the "edit" button of the location filter'
        step 'Select "Strand 1" in the section drop down'
        step 'Select "Component 1" in the component drop down'
        step 'Click on the "apply" button'
        step 'I see activity "activity 1_1_1_1"'
        step 'I see activity "activity 1_1_1_2"'
        step 'I do not see activity "activity 1_1_2_1"'
        step 'I do not see activity "activity 1_1_2_2"'
        step 'I do not see activity "activity 1_2_1_1"'
        step 'I do not see activity "activity 1_2_1_2"'
        step 'I do not see activity "activity 1_2_2_1"'
        step 'I do not see activity "activity 1_2_2_2"'
        step 'I do not see activity "activity 2_1_1_1"'
        step 'I do not see activity "activity 2_1_1_2"'
        step 'I do not see activity "activity 2_1_2_1"'
        step 'I do not see activity "activity 2_1_2_2"'
        step 'I do not see activity "activity 2_2_1_1"'

        step 'Click on the "edit" button of the location filter'
        step 'Select "All Sections" in the section drop down'
        step 'Select "Component 1" in the component drop down'
        step 'Click on the "apply" button'
        step 'I see activity "activity 1_1_1_1"'
        step 'I see activity "activity 1_1_1_2"'
        step 'I see activity "activity 1_2_1_1"'
        step 'I see activity "activity 1_2_1_2"'
        step 'I do not see activity "activity 1_1_2_1"'
        step 'I do not see activity "activity 1_1_2_2"'
        step 'I do not see activity "activity 1_2_2_1"'
        step 'I do not see activity "activity 1_2_2_2"'
        step 'I do not see activity "activity 2_1_1_1"'
        step 'I do not see activity "activity 2_1_1_2"'
        step 'I do not see activity "activity 2_1_2_1"'
        step 'I do not see activity "activity 2_1_2_2"'
        step 'I do not see activity "activity 2_2_1_1"'

      end
      step 'Select all the lessons' do
        step 'Click on the "edit" button of the location filter'
        step 'Select "All lessons"'
        step 'Click on the "apply" button'
      end
    end

    purpose 'I can filter activities by properties' do
      purpose 'I can filter activities by content type' do
        step 'Click on the "edit" button of the properties filter'
        step 'Select "activities" in the content type drop down'
        step 'Click on the "apply" button'
        step 'I see "All Activities" in the properties filter summary'
        step 'I see all the activities'

        step 'Click on the "edit" button of the properties filter'
        step 'Select "assessments" in the content type drop down'
        step 'Click on the "apply" button'
        step 'I see "All Assessment" in the properties filter summary'
        step 'I see the message "No activities match the current filter settings."'

        step 'Click on the "edit" button of the properties filter'
        step 'Select "Activities and assessment" in the content type drop down'
        step 'Click on the "apply" button'
        step 'I see "All Activities and assessment" in the properties filter summary'
        step 'I see all the activities'
      end
      purpose 'I can filter activities by activity type' do
        step 'Click on the "edit" button of the properties filter'
        step 'Select "activities" in the content type drop down'
        step 'Select "Multiple choice" in the activity type drop down'
        step 'Click on the "apply" button'
        step 'I see a drop down with "Multiple choice" selected in the filter summary'
        step 'I only see multiple choice activities' do
          step 'I see activity "activity 1_1_1_1"'
          step 'I see activity "activity 1_1_2_1"'
          step 'I see activity "activity 1_2_2_2"'
          step 'I see activity "activity 2_1_1_1"'
          step 'I see activity "activity 2_2_1_1"'
          step 'I do not see activity "activity 1_1_1_2"'
          step 'I do not see activity "activity 1_1_2_2"'
          step 'I do not see activity "activity 1_2_1_1"'
          step 'I do not see activity "activity 1_2_1_2"'
          step 'I do not see activity "activity 1_2_2_1"'
          step 'I do not see activity "activity 2_1_1_2"'
          step 'I do not see activity "activity 2_1_2_1"'
          step 'I do not see activity "activity 2_1_2_2"'
        end
        purpose 'I can select the activity type from the filter summary' do
          step 'Select "Drop down" from the properties filter summary'
          step 'I only see drop down activities' do
          step 'I see activity "activity 1_1_2_2"'
          step 'I see activity "activity 1_2_1_2"'
          step 'I see activity "activity 2_1_1_2"'
          step 'I do not see activity "activity 1_1_1_1"'
          step 'I do not see activity "activity 1_1_1_2"'
          step 'I do not see activity "activity 1_1_2_1"'
          step 'I do not see activity "activity 1_2_1_1"'
          step 'I do not see activity "activity 1_2_2_1"'
          step 'I do not see activity "activity 1_2_2_2"'
          step 'I do not see activity "activity 2_1_1_1"'
          step 'I do not see activity "activity 2_1_2_1"'
          step 'I do not see activity "activity 2_1_2_2"'
          step 'I do not see activity "activity 2_2_1_1"'
          end
        end
      end
      purpose 'I can filter activities by grading method' do
        step 'Click on the "edit" button of the properties filter'
        step 'Select "All types" in the activity type drop down'
        step 'Select "Auto" in the grading method drop down'
        step 'Click on the "apply" button'
        step 'The properties filter summary is updated' do
          step 'I see a drop down with "Instructor" selected'
        end
        step 'I only see activities that are auto graded' do
          step 'I see activity "activity 1_1_1_1"'
          step 'I see activity "activity 1_1_2_1"'
          step 'I see activity "activity 1_1_2_2"'
          step 'I see activity "activity 1_2_2_2"'
          step 'I see activity "activity 2_1_1_1"'
          step 'I see activity "activity 2_1_1_2"'
          step 'I see activity "activity 2_2_1_1"'
          step 'I do not see activity "activity 1_1_1_2"'
          step 'I do not see activity "activity 1_2_1_1"'
          step 'I do not see activity "activity 1_2_1_2"'
          step 'I do not see activity "activity 1_2_2_1"'
          step 'I do not see activity "activity 2_1_2_1"'
          step 'I do not see activity "activity 2_1_2_2"'
        end
        purpose 'I can select the grading type from the filter summary' do
          step 'Select "Instructor" from the filter summary'
          step 'I only see activities that are instructor graded' do
            step 'I see activity "activity 1_1_1_2"'
            step 'I see activity "activity 1_2_1_1"'
            step 'I see activity "activity 1_2_2_1"'
            step 'I see activity "activity 2_1_2_1"'
            step 'I see activity "activity 2_1_2_2"'
            step 'I do not see activity "activity 1_1_1_1"'
            step 'I do not see activity "activity 1_1_2_1"'
            step 'I do not see activity "activity 1_1_2_2"'
            step 'I do not see activity "activity 1_2_1_2"'
            step 'I do not see activity "activity 1_2_2_2"'
            step 'I do not see activity "activity 2_1_1_1"'
            step 'I do not see activity "activity 2_1_1_2"'
            step 'I do not see activity "activity 2_2_1_1"'
          end
        end
      end
      step 'Click on the "edit" button of the properties filter'
      step 'select "All types" and "all grading methods"'
      step 'Click on the "apply" button'
    end

    purpose 'Every activity has a tooltip with a complete summary in it' do
      step "It shows the activity's type"
      step "It shows the activity's name"
      step "It shows the lesson's name and the strand"
      step 'It shows the possible points for the activity'
      purpose 'I can see a word summary for learning engine activities' do
        step 'The learning engine activity has a tooltip with the list of words from the activity'
      end
    end

    purpose 'I can select activities to assign' do
      purpose 'I can individually select activities' do
        step 'The assign button is disabled'
        step 'Select an activity'
        step 'The assign button is enabled'
        step 'Select an activity'
        step 'The assign button is enabled'
      end

      purpose 'I can select all the activities of a strand' do
        step 'The assign button is disabled'
        step 'Select an activity in the first strand'
        step 'The assign button is enabled'
        step 'Select an activity in the second strand'
        step 'The activity in the first strand is still selected'
        step 'Select the first strand'
        step 'All the activities in the first strand are selected'
        step 'The activity in the second strand is still selected'
        step 'Unselect an activity in the first strand'
        step 'Other activities from the first strand are still selected'
        step 'Unselect the first strand'
        step 'All the activities in the first strand are unselected'
        step 'The activity in the second strand is still selected'
        step 'Unselect the activity in the second strand'
      end

      purpose 'I can select all the shown activities' do
        step 'The assign button is disabled'
        step 'Select an activity in the first strand'
        step 'Check the "Select all" checkbox'
        step 'All the activities are selected'
        step 'The assign button is enabled'
        step 'Uncheck the "Select all" checkbox'
        step 'All the activities are unselected'
        step 'The assign button is disabled'
      end

      purpose 'I can only see the months my course covers' do
        step 'I see "December 2018"'
        step 'The "previous month" button is disabled'
        step 'Click on the "next month" button'
        step 'I see "January 2019"'
        step 'Click on the "next month" button'
        step 'I see "February 2019"'
        step 'The "next month" button is disabled'
        step 'Lick on the "previous month" button'
        step 'I see "January 2019"'
      end
      purpose 'I see the "special" days on the calendar' do
        step %q(I see "New Year's Day" on 2019-01-01 marked as class cancelled)
        step 'I see "Bean Day" on 2019-01-06 marked as an event'
      end
      purpose 'I see the number of activities and the total time for each day and for the month' do
        step 'Click on the "previous month" button'
        step 'I see "December 2018"'
        step 'I see 3 activities assigned for the day 2018-12-15'
        step 'I see a total of 1h 18 minutes for the day 2018-12-15'
        step 'I see a tooltip "Homework: 3" for the day 2018-12-15'
        step 'I see 2 activities assigned for the day 2018-12-16'
        step 'I see a total of 17 minutes for the day 2018-12-16'
        step 'I see a tooltip "Homework: 2" for the day 2018-12-16'
        step 'I see 5 activities assigned for the month'
        step 'I see 1h 35 minutes of activities assigned for the month'
      end
    end

    purpose 'I can assign activities' do
      step 'The assign button is disabled'
      step 'Select activity "activity_1_1_1_1"'
      step 'Click on the "Assign selected" button'
      step 'I see a modal'
      step 'I see the message "1 activity selected"'
      step 'The due date is set to today'
      step 'No group is selected'
      step 'The "save" button is enabled'

      purpose 'A valid due date is required' do
        step 'Set a due date before the course start date'
        step 'Click on the "save" button'
        step 'I see the error message "Due date must be after course start date, which is 2018-12-01"'
        step 'I see the error message "Group is required."'
        step 'Select a due date after the course end date'
        step 'Click on the "save" button'
        step 'I see the error message "Due date must be before course end date, which is 2019-02-28"'
        step 'I see the error message "Group is required."'
        step 'Set a valid due date'
      end
      purpose 'A group is required' do
        step 'Click on the "save" button'
        step 'I see the error message "Group is required."'
      end
      step 'Select a group'
      step 'Click on the "save" button'
      step 'I see the flash message "Activity assigned successfully."'
      step 'I do not see the activity "activity_1_1_1_1" in the activity list anymore'
      step 'The assign button is disabled'
      purpose 'The calendar is updated' do
        step 'I see the total number of activities for the month updated'
        step 'I see the total number of hours for the month updated'
        step 'I see the number of activities assigned for the selected due date'
        step 'I see the number of hours assigned for the selected due date'
      end
      purpose 'The due date of the last assignment is saved' do
        step 'Select activity "activity_2_1_2_1"'
        step 'Click on the "Assign selected" button'
        step 'The due date is set to the lastest select due date'
      end
      purpose 'I can cancel the assignment procedure' do
        step 'Click on the "cancel" button'
        step 'The activity "activity_1_1_2_1" is still selected'
        step 'The "Assign selected" button is enabled'
        step 'Unselect the activity "activity_2_1_2_1"'
      end
    end

    purpose 'I see the number of selected activites and the number of hours they take' do
      step 'I see a total of 0 activities and 0 minutes'
      step 'Select activity "activity 1_1_2_1"'
      step 'I see a total of 1 activities and 6 minutes'
      step 'Select activity "activity 1_2_2_2"'
      step 'I see a total of 2 activities and 15 minutes'
    end

    purpose 'Instructor assignment calendar' do
      # A lot of what is tested here is similar to what has been tested before
      # When implementing this spec, a lot of code can be factorized.
      step 'Visit the assignment calendar page'

      purpose 'I can only see the months my course covers' do
        step 'I see "December 2018"'
        step 'The "previous month" button is disabled'
        step 'Click on the "next month" button'
        step 'I see "January 2019"'
        step 'Click on the "next month" button'
        step 'I see "February 2019"'
        step 'The "next month" button is disabled'
        step 'Lick on the "previous month" button'
        step 'I see "January 2019"'
      end
      purpose 'I see the "special" days on the calendar' do
        step %q(I see "New Year's Day" on 2019-01-01 marked as class cancelled)
        step 'I see "Bean Day" on 2019-01-06 marked as an event'
      end
      purpose 'I see the number of activities and the total time for each day and for the month' do
        step 'Click on the "previous month" button'
        step 'I see "December 2018"'
        step 'I see 3 activities assigned for the day 2018-12-15'
        step 'I see a total of 1h 18 minutes for the day 2018-12-15'
        step 'I see a link "Homework: 3" for the day 2018-12-15'
        step 'I see 2 activities assigned for the day 2018-12-16'
        step 'I see a total of 17 minutes for the day 2018-12-16'
        step 'I see a link "Homework: 2" for the day 2018-12-16'
        step 'I see 6 activities assigned for the month'
        step 'I see 1h 40 minutes of activities assigned for the month'
      end

      purpose 'I can unassign activities' do
        step 'click on the link "Homework: 3" for the day 2018-12-15'
        step 'I see a modal'
        step 'I see the message "3 activities selected"'
        step 'I see the name of the course'
        step 'I see the name of the section'
        step 'I see 3 activities checked'
        step 'I see an "unassign" button enabled'
        step 'Uncheck all the activities'
        step 'Click on the "unassign" button'
        step 'I see an alert with the message "Please select at least one activity."'
        step 'Accept the alert'
        step 'Select the 3 activities'
        step 'Click on the "unassign" button'
        step 'I see an alert with the message "You are about to unassign 3 items."'
        step 'Accept the alert'
        step 'I see the flash message "Activities unassigned successfully."'
        step 'I see no assigned activities for the day 2018-12-15'
      end
      purpose 'I can reassign activities' do
        step 'click on the link "Homework: 2" for the day 2018-12-16'
        step 'I see a modal'
        step 'I see the message "2 activities selected"'
        step 'I see the name of the course'
        step 'I see the name of the section'
        step 'I see 2 activities checked'
        step 'I see a "reassign" button enabled'
        step 'Uncheck all the activities'
        step 'I see the message "Please select at least one activity."'
        step 'The "reassign" button is disabled'
        step 'Select one activity'
        step 'Click on the "reassign" button'
        purpose 'I can review the selected activities' do
          step 'I see a link "review activities"'
          step 'I see 2 activities, and only one checked'
          # This message is currently displayed
          step 'I do not see the message "Please select at least one activity."'
          step 'Click on the "reassign" button'
        end
        step 'I see the message "1 activity selected"'
        step 'The due date is set to 2018-12-16'
        step 'No group is selected'
        step 'The "save" button is enabled'
        purpose 'A valid due date required' do
          step 'Set a due date before the course start date'
          step 'Click on the "save" button'
          step 'I see the error message "Due date must be after course start date, which is 2018-12-01"'
          step 'I see the error message "Group is required."'
          step 'Select a due date after the course end date'
          step 'Click on the "save" button'
          step 'I see the error message "Due date must be before course end date, which is 2019-02-28"'
          step 'I see the error message "Group is required."'
          step 'Set the due date to 2018-12-17'
        end
        purpose 'A group is required' do
          step 'Click on the "save" button'
          step 'I see the error message "Group is required."'
        end
        step 'Select a group'
        step 'Click on the "save" button'
        step 'I see the flash message "Activity assigned successfully."'
        step 'I see 1 activity assigned for the day 2018-12-16'
        step 'I see 1 activity assigned for the day 2018-12-17'
      end
    end
  end
end
