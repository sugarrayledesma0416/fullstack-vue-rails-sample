require 'timecop'

feature 'gradebook_analytics', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  def create_score(activity:, date:, points:, time_spent:, user: nil)
    common_attrs = {
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    }
    create(:gb_attempt_duration, common_attrs.merge(seconds_spent: time_spent))
    create(
      :gb_score_action,
      common_attrs.merge(
        summation: {
          'points_earned' => points,
          'submitted_at' => date,
          'time_spent' => time_spent
        }
      )
    )
  end

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:lesson_2) { lesson }
  let(:category) { create(:category, course: course) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      start_date: Date.new(2019, 2, 1)
    )
  end

  let(:summative_activity) do
    create_diagnostic_v2_activity_with_unit_lesson_and_concept(
      program,
      :summative,
      points_possible: 10,
      lesson: lesson,
      toc_location: 2
    )
  end

  let(:formative_activity) do
    create_diagnostic_v2_activity_with_unit_lesson_and_concept(
      program,
      :formative,
      points_possible: 10,
      lesson: lesson_2,
      toc_location: 1
    )
  end

  # Use fixed time to make date range determinative.
  around do |example|
    Timecop.freeze(Time.new(2019, 3, 1, 12, 0, 0)) do
      example.run
    end
  end

  before do
    create(:practice_test_analytics_program_config, program: program)
    create(
      :assignment,
      assignable: summative_activity,
      category: category,
      due_date: Date.new(2019, 2, 8),
      section: section
    )
    create(
      :assignment,
      assignable: formative_activity,
      category: category,
      due_date: Date.new(2019, 2, 8),
      section: section
    )
    # Create an assignment in a section that only has assignments due in
    # the future.
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    create(:enrollment, user: student_3, section: section)

    # User 1 submits the older assignment on time,
    #   and the newer assignment late.
    create_score(
      activity: summative_activity,
      date: Date.new(2019, 2, 7),
      points: 9,
      time_spent: 5400,
      user: student_1
    )
    create_score(
      activity: formative_activity,
      date: Date.new(2019, 2, 27),
      points: 9,
      time_spent: 2700,
      user: student_1
    )

    # User 3 submits the summative activity
    # and earns 0 points
    create_score(
      activity: summative_activity,
      date: Date.new(2019, 2, 7),
      points: 0,
      time_spent: 5400,
      user: student_3
    )

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    StudyPlanConceptsCreator.batch_create([summative_activity, formative_activity], program.id)
    allow(summative_activity).to receive(:summative_concepts_count).and_return(5)
  end

  RSpec.shared_examples 'practice test examples' do
    feature 'As an instructor, I see all relevant section analytics information' do
      describe 'When all formative and summative assignment due dates have passed' do
        it 'displays all students currently enrolled in the selected section in the table' do
          within('table.test-section-practice-test-table') do
            student_names = find_all('.student-name').map(&:text)

            section.current_students_base.each do |student|
              expect(student_names).to include(student.full_name)
            end
          end
        end

        it 'displays all of the summative concept titles' do
          within('table.test-section-practice-test-table') do
            concept_headers = find_all('.concept-type').map{ |header| header.text.downcase }
            expected_concept_header_text = summative_activity.study_plan_concepts.map do |concept|
              "#{concept.diagnostic_concept.type} #{concept.diagnostic_concept.ref}"
            end

            expected_concept_header_text.each do |concept_header|
              expect(concept_headers).to include concept_header
            end
          end
        end
      end

      describe 'When there is an additional diagnostic_v2 summative activity in the lesson' \
               'that is not in the TOC' do
        let(:summative_activity_2) do
          create_diagnostic_v2_activity_with_unit_lesson_and_concept(
            program,
            :summative,
            points_possible: 10,
            lesson: lesson,
            toc_location: nil
          )
        end
        let(:formative_activity_2) do
          create_diagnostic_v2_activity_with_unit_lesson_and_concept(
            program,
            :formative,
            points_possible: 10,
            lesson: lesson_2,
            toc_location: nil
          )
        end

        before do
          StudyPlanConceptsCreator.batch_create([summative_activity_2, formative_activity_2], program.id)
        end

        it 'displays the scores correctly' do
          within('table.test-section-practice-test-table') do
            #check for the presence of a valid score
            expect(page).to have_content('9.0%')
          end
        end
      end

      scenario 'I can sort the table by student name' do
        within('table.test-section-practice-test-table') do
          find(:css, 'th.student-header').first('a').click
          expect(page).to have_css('th.student-header div.analytics-menu__arrow--up')
        end
      end

      scenario 'I can sort the table by summative average' do
        within('table.test-section-practice-test-table') do
          find(:css, 'th.test-summative-average-header').first('a').click
          expect(page).to have_css('th.test-summative-average-header div.analytics-menu__arrow--up')
        end
      end

      scenario 'I can sort the table by summative concept score' do
        within('table.test-section-practice-test-table') do
          first(:css, 'th.test-summative-concept-header').first('a').click
          expect(page).to have_css('th.test-summative-concept-header div.analytics-menu__arrow--up')
        end
      end

      scenario 'I can sort the table by formative concept score' do
        within('table.test-section-practice-test-table') do
          first(:css, 'th.formative-header').first('a').click
          expect(page).to have_css('th.formative-header div.analytics-menu__arrow--up')
        end
      end

      scenario 'I can sort the table by concept score change' do
        within('table.test-section-practice-test-table') do
          first(:css, 'th.test-score-change-header').first('a').click
          expect(page).to have_css('th.test-score-change-header div.analytics-menu__arrow--up')
        end
      end

      scenario "I can view an individual student's practice test page" do
        individual_student_window = nil
        previous_window = current_window

        within('table.test-section-practice-test-table') do
          individual_student_window = window_opened_by { click_link(student_1.full_name) }
        end

        switch_to_window(individual_student_window)

        expect(page).to have_content('This student has not completed the activities.')
        switch_to_window(previous_window)
      end
    end
  end

  context 'when in a Lesson program' do
    background do
      visit gradebook_engine.course_section_scores_path(
        program_id: program.id,
        course_id: course.id,
        section_id: section.id
      )
      within('.test-gradebook-subnav') do
        click_link('Analytics')
        click_link('Practice Test')
      end
    end

    include_examples 'practice test examples'

    scenario 'I see a message that informs me if a lesson is not setup for practice tests' do
      find('select').find(:xpath, 'option[2]').select_option

      expect(page).to have_content('This lesson does not have Practice Test activities.')
    end

    scenario 'displays all lessons in the drop down' do
      previous_window = current_window
      activity_window = nil
      expected_select_options = program.lessons.pluck(:name)

      options_text = find_all('option').map(&:text)
      expect(expected_select_options).to match options_text
      within('table.test-section-practice-test-table') do
        activity_window = window_opened_by do
          find('td.student-name > a', text: student_1.full_name).click
        end
      end
      switch_to_window(activity_window)
      expect(page.current_url).to match(%r{/individual_student\?.*student_id=#{student_1.id}$})
      options_text = find_all('option').map(&:text)
      expect(expected_select_options).to match options_text
      switch_to_window(previous_window)
    end
  end

  context 'when in a Unit program' do
    let(:program) { create(:two_tier_program_with_toc_entries) }
    let(:lesson) { program.units.first.lessons[0] }
    let(:lesson_2) { program.units.first.lessons[1] }

    background do
      visit gradebook_engine.course_section_scores_path(
        program_id: program.id,
        course_id: course.id,
        section_id: section.id
      )
      within('.test-gradebook-subnav') do
        click_link('Analytics')
        click_link('Practice Test')
      end
    end

    include_examples 'practice test examples'

    scenario 'I see a message that informs me if a unit is not setup for practice tests' do
      find('select').find(:xpath, 'option[3]').select_option

      within('.no-diagnostic-v2-activities') do
        expect(page).to have_content('This unit does not have Practice Test activities.')
      end
    end

    scenario 'displays all units in the drop downs' do
      previous_window = current_window
      activity_window = nil
      expected_select_options = program.units.pluck(:name)

      options_text = find_all('option').map(&:text)
      expect(expected_select_options).to match options_text
      within('table.test-section-practice-test-table') do
        activity_window = window_opened_by do
          find('td.student-name > a', text: student_1.full_name).click
        end
      end
      switch_to_window(activity_window)
      expect(page.current_url).to match(%r{/individual_student\?.*student_id=#{student_1.id}$})
      options_text = find_all('option').map(&:text)
      expect(expected_select_options).to match options_text
      switch_to_window(previous_window)
    end
  end

  feature 'As an instructor, I can see all relevant study plan information' do
    let(:results) { instance_double(MaestroActivityEngine::ActivityContent::Results) }
    let(:generator) { described_class.new(activity, results, section, user) }
    let(:supplemental_activity) { create(:activity, cms_activity_id: 90466, lesson: lesson) }

    background do
      allow(summative_activity).to receive(:summative_concepts_count).and_return(5)
      visit gradebook_engine.course_section_scores_path(
        program_id: program.id,
        course_id: course.id,
        section_id: section.id
      )
      within('.test-gradebook-subnav') do
        click_link('Analytics')
        click_link('Practice Test')
      end
      click_link('Study Plan')
    end

    describe 'When all formative and summative assignment due dates have passed' do
      it 'displays all students currently enrolled in the selected section in the table' do
        within('table.test-section-study-plan-table') do
          student_names = find_all('.student-name').map(&:text)

          section.current_students_base.each do |student|
            expect(student_names).to include(student.full_name)
          end
        end
      end

      it 'displays all of the summative concept titles' do
        within('table.test-section-study-plan-table') do
          concept_headers = find_all('.concept-type').map{ |header| header.text.downcase }
          expected_concept_header_text = summative_activity.study_plan_concepts.map do |concept|
            "#{concept.diagnostic_concept.type} #{concept.diagnostic_concept.ref}"
          end

          expected_concept_header_text.each do |concept_header|
            expect(concept_headers).to include concept_header
          end
          summative_link_text = find_all('.test-student-summative-link').map(&:text)
          expect(summative_link_text).to include '9.0%'
          expect(summative_link_text).to include '0.0%'
          expect(find('.test-student-summative-non-submitted').text).to eq('0.0')
        end
      end
    end

    feature 'I can see related supplemental activities' do
      background do
        allow(formative_activity.notifications).to receive(:dispatch)
        formative_activity.study_plan_concepts.each do |concept|
          allow(results).to receive(:concept_percent).with(
            concept.reference_id
          ).and_return(0)
        end

        create(:attempt_completed, user: student_1, section: section, activity: formative_activity)
        UserReadingsGenerator.new(formative_activity, results, student_1, section).generate
        @activity_window = nil
        @previous_window = current_window
      end

      xscenario 'I can click on a supplemental activity link to view the activity' do
        pending('find fix for missing supplemental readings')
        within('table.test-section-study-plan-table') do
          @activity_window = window_opened_by do
            first('a.test-supplemental-reading-link').click
          end
        end
        switch_to_window(@activity_window)
        expect(page).to have_content(supplmental_activity.title)
        switch_to_window(@previous_window)
      end
    end
  end
end
