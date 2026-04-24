feature 'Standards Report for a Section',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include WaitForAjax
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:assistant) do
    create(:instructor).tap do |user|
      create(:section_instructor, instructor: user, role: 'Assistant', section:)
    end
  end
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:lesson) { program.units.first.lessons.first }
  let(:course_package) { instance_double(Maestro::CoursePackage, id: 1) }
  let(:graded_count) { 25 }
  let(:standard_number) { 'zzFAKE.ELA-Literacy.RL.7.1' }
  let(:standard_description) { 'A fake description with more than 30 characters' }

  let(:section) do
    create(:section, name: 'ELD Section 1', course:, instructor:)
  end

  let!(:section_2) do
    create(:section, name: 'ELD Section 2', course:, instructor:)
  end

  let(:concept_proficiency) do
    create(:concept, name: 'Proficiency Assessment', program:, lesson:)
  end

  let(:activity_1_attrs) do
    {
      id: 835_536,
      title: 'End-of-Unit Assessment',
      component_name: 'Assessment',
      lesson_id: lesson.id,
      cms_activity_id: 285_669,
      toc_location_rank: 20,
      points_possible: 41,
      activity_type: 'exam',
      concept: concept_proficiency
    }
  end

  let!(:activity_1) do
    create_activity_with_unit_lesson_and_concept(
      program,
      activity_1_attrs
    )
  end

  let(:concept_pmr) do
    create(:concept, name: 'Progress Monitoring Assessment', program:, lesson:)
  end
  let(:activity_pmr_1_attrs) do
    {
      id: 835_537,
      title: 'Before You Read: Build Vocabulary',
      component_name: 'Quizzes',
      lesson_id: lesson.id,
      cms_activity_id: 285_670,
      toc_location_rank: 10,
      points_possible: 42,
      activity_type: 'exam',
      concept: concept_pmr
    }
  end
  let!(:activity_pmr_1) do
    create_activity_with_unit_lesson_and_concept(
      program,
      activity_pmr_1_attrs
    )
  end

  let(:activity_pmr_2_attrs) do
    {
      id: 835_538,
      title: 'Before You Read: Analyze Chronology',
      component_name: 'Quizzes',
      lesson_id: lesson.id,
      cms_activity_id: 285_671,
      toc_location_rank: 11,
      points_possible: 20,
      activity_type: 'exam',
      concept: concept_pmr
    }
  end

  let!(:activity_pmr_2) do
    create_activity_with_unit_lesson_and_concept(
      program,
      activity_pmr_2_attrs
    )
  end

  let(:activity_pmr_3_attrs) do
    {
      id: 835_539,
      title: 'Writing Test',
      component_name: 'Speaking and Writing Tests',
      lesson_id: lesson.id,
      cms_activity_id: 285_672,
      toc_location_rank: 11,
      points_possible: 20,
      activity_type: 'exam',
      concept: concept_pmr
    }
  end

  let!(:activity_pmr_3) do
    create_activity_with_unit_lesson_and_concept(
      program,
      activity_pmr_3_attrs
    )
  end

  let(:standard_set_cc) do
    StandardSet.create(
      vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2010,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: 'CCSS'
    )
  end
  let(:standard_set_wida_1) do
    StandardSet.create(
      vendor_guid: '912B82CC-5F82-11ED-9387-F0A169E7CC7F',
      issuer: 'WIDA',
      name: 'Language Expectations by WIDA ELD Standard Statements and Grade-Level Cluster',
      adopt_year: 2020,
      state: 'US',
      description: 'WIDA English Language Development Standards Framework',
      display_name: 'WIDA'
    )
  end
  let(:standard_set_wida_2) do
    StandardSet.create(
      vendor_guid: 'A1933530-5EC7-11ED-B629-D1CE9CF63431',
      issuer: 'WIDA',
      name: 'Proficiency Level Descriptors by Grade-Level Cluster and Communication Modes',
      adopt_year: 2020,
      state: 'US',
      description: 'WIDA English Language Development Standards Framework',
      display_name: 'WIDA'
    )
  end

  before do
    stub_request(:get, '/assets/opentok.min.js.map')
  end

  def load_fixture(name)
    file_path = Rails.root.join('spec', 'fixtures', 'json', "#{name}.json")
    JSON.parse(File.read(file_path))
  end

  def validate_main_report_headings_are_visible(section)
    expect(find('.test-section-name')).to have_text(section.name)
    expect(find('.test-unit-name')).to have_text(lesson.name)
  end

  def validate_section_report_table_is_visible
    expect(page).to have_selector('.test-section-summary-table', count: 1)
    expect(page).to have_selector('.test-result-row', count: 10)
    expect(page).to have_selector('.test-linked-standard', count: 10)
    expect(page).not_to have_selector('.test-unlinked-standard')
  end

  def validate_assessment_column_is_visible(activity)
    within(".test-standard-assessment-#{activity.id}-column") do
      validate_graded_assessment_count
      validate_student_count
    end
  end

  # TODO: Add activity parameter when multi-select is added.
  def validate_graded_assessment_count
    expect(find('.test-graded-count')).to have_text(
      section.real_students_base.count.zero? ? 0 : graded_count
    )
  end

  def validate_student_count
    expect(find('.test-student-count')).to have_text(
      section.real_students_base.count
    )
  end

  def validate_sections_in_the_interstitial_page(section_1, section_2)
    expect(page).to have_selector(".test-section_focusable_#{section_1.id}")
    expect(page).to have_selector(".test-section_focusable_#{section_2.id}")
  end

  def return_to_section_report_from_student_report
    click_button('Return')

    expect(page).to have_select(
      'standard_set_display_name',
      options: %w[
        CCSS
        WIDA
      ],
      selected: 'CCSS'
    )

    expect(page).to have_select(
      'lesson_id',
      options: ['Select a Unit'] + course.lessons_covered.map(&:name),
      selected: lesson.name
    )
    expect(page).to have_selector(
      '#assessment_ids_select:not(.is-disabled) ' \
      "#assessment-option-0 #assessment-id-#{activity_1.id}"
    )
    expect(page).to have_button('section_report_submit', disabled: true)
    expect(page).not_to have_selector('.test-unlinked-standard')
  end

  def visit_section_report(user)
    log_in_as(user)
    visit(
      gradebook_standards_landing_page_path(
        program_id: program.id,
        course_id: course.id,
        section_id: section.id
      )
    )
  end

  def visit_student_report(user, section)
    log_in_as(user)
    visit(
      gradebook_standards_landing_page_path(
        program_id: program.id,
        course_id: course.id,
        section_id: section.id
      )
    )

    select(lesson.name, match: :first)

    within('#assessment_ids_select') do
      click_on 'Select Assessments'
    end

    within('.assessment-options') do
      check activity_1.title, allow_label_click: true
    end

    click_button('section_report_submit')

    report_standard = find('.test-linked-standard', match: :first)
    report_standard.click
  end

  context 'with proficiency assessments' do
    before do
      course.standard_sets << [standard_set_wida_1, standard_set_wida_2, standard_set_cc]

      standards = load_fixture('standards_cc')
      Standard.create(standards)

      standard_assets = load_fixture('standard_assets')
      StandardAsset.create!(standard_assets)

      standard_alignments = load_fixture('standard_alignments')
      StandardAlignment.create!(standard_alignments)

      standards_results_data = load_fixture('standards_results').each do |standards_result|
        standards_result['user_id'] = create(:student).id
        standards_result['section_id'] = section.id
      end
      StandardsResults.create(standards_results_data)

      assessment_items = load_fixture('assessment_items')
      assessment_items.each do |assessment_item|
        vendor_guid = assessment_item['guid']
        standard_asset = StandardAsset.find_by(vendor_guid:)
        standard_asset.create_assessment_item(assessment_item)
      end

      user_ids = StandardsResults.pluck(:user_id).sort.uniq.take(10)
      user_ids.each do |user_id|
        student = Student.find user_id
        create(:enrollment, section:, user: student)
      end

      # rubocop:disable RSpec/AnyInstance
      # rubocop:disable RSpec/VerifiedDoubles
      allow_any_instance_of(Activity).to receive(:questions).and_return(
        [
          double('Question', question_guid: 'question-guid-1'),
          double('Question', question_guid: 'question-guid-2')
        ]
      )
      # rubocop:enable RSpec/VerifiedDoubles
      # rubocop:enable RSpec/AnyInstance

      create(:program_config_with_standard_sets, program:)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      initialize_program_access_client_calls_for_instructor(assistant, program)
      allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
    end

    context 'with a course configured for ELD standards' do
      scenario 'as an instructor selecting a section in the interstitial page' do
        pending('pending until we fix the default unit load')
        # We don't use visit_section_report(instructor) here because we
        # want to force the section interstitial page to appear so we can return to the
        # section report page once the section is selected
        log_in_as(instructor)
        visit instructor_dashboard_path(program_id: program.id)

        find_by_id('tour-guide-nav-grades').click # this is the Grade menu option
        click_link 'Gradebook'

        purpose 'Return to the section report page after selecting the section' do
          step 'I see two sections in the interstitial page' do
            validate_sections_in_the_interstitial_page(section, section_2)
          end

          step 'I am redirected to the interstitial page after navigating to the section report' do
            click_link 'Analytics'
            click_link 'Assess to Learn'

            validate_sections_in_the_interstitial_page(section, section_2)
          end

          step 'I see the section report page after selecting one of the sections' do
            click_link section.name, visible: true

            expect(page).to have_current_path(
              "#{gradebook_standards_section_report_path(
                program_id: program.id,
                course_id: course.id,
                section_id: section.id
              )}?direction=asc&sort=standard"
            )
          end
        end
      end

      scenario 'as an instructor selecting a section in the course focus list' do
        pending('pending until we fix the default unit load')
        log_in_as(instructor)
        visit instructor_dashboard_path(program_id: program.id)

        find_by_id('tour-guide-nav-grades').click # this is the Grade menu option
        click_link 'Gradebook'
        click_link 'Analytics'
        click_link 'Assess to Learn'

        purpose 'Return to the section report page after selecting the section' do
          step 'I am redirected to the interstitial page after navigating to the section report' do
            validate_sections_in_the_interstitial_page(section, section_2)
          end

          step 'I see the section report page after selecting one of the sections' do
            find('.test-course-focus__header').click
            find(".test-section_#{section.id}").click

            expect(page).to have_current_path(
              "#{gradebook_standards_section_report_path(
                program_id: program.id,
                course_id: course.id,
                section_id: section.id
              )}?direction=asc&sort=standard"
            )
          end
        end
      end

      scenario 'as an instructor navigating to a standards report for a section' do
        pending('pending until we fix the default unit load')
        visit_section_report(instructor)

        purpose 'I can go to the Standards page' do
          expect(page).to have_current_path(
            gradebook_standards_landing_page_path(
              program_id: program.id,
              course_id: course.id,
              section_id: section.id
            )
          )
        end

        purpose 'I can see the Standards menu option in the Analytics menu' do
          within('.test-gradebook-subnav') do
            expect(page).to have_link('Assess to Learn')
          end
        end

        purpose 'I can see drop-downs to filter the report by standard set, unit and assessment' do
          expect(page).to have_select('standard_set_display_name')
          expect(page).to have_select('lesson_id')
          expect(page).to have_button('section_report_submit', disabled: false)

          step 'I can see the the standard sets associated with my course' do
            expect(page).to have_select(
              'standard_set_display_name',
              options: %w[
                CCSS
                WIDA
              ],
              selected: 'CCSS'
            )
          end

          step 'I select a unit' do
            expect(page).to have_select(
              'lesson_id',
              options: ['Select a Unit'] + course.lessons_covered.map(&:name),
              selected: course.lessons_covered[0].name
            )

            select(lesson.name)
          end

          step 'I select an assessment' do
            expect(page).to have_selector(
              '#assessment_ids_select:not(.is-disabled) ' \
              "#assessment-option-0 #assessment-id-#{activity_1.id}"
            )

            within('#assessment_ids_select') do
              click_on 'Select Assessments'
            end

            within('.assessment-options') do
              check activity_1.title, allow_label_click: true
            end

            expect(page).to have_button('section_report_submit', disabled: false)
          end

          step 'I select a different standard set' do
            select('WIDA', from: 'standard_set_display_name')

            expect(page).to have_select(
              'lesson_id',
              options: ['Select a Unit'] + course.lessons_covered.map(&:name)
            )
            expect(page).to have_button('section_report_submit', disabled: false)
          end

          step 'I go back to my original set of selections' do
            select(
              'CCSS',
              from: 'standard_set_display_name'
            )

            select(lesson.name, match: :first)
            expect(page).to have_selector(
              '#assessment_ids_select:not(.is-disabled) ' \
              "#assessment-option-0:not(.selected-row) #assessment-id-#{activity_1.id}"
            )

            within('#assessment_ids_select') do
              click_on 'Select Assessments'
            end

            within('.assessment-options') do
              check activity_1.title, allow_label_click: true
            end

            expect(page).to have_button('section_report_submit', disabled: false)
          end
        end

        purpose 'I can see the report once I have made selections from the drop-drowns' do
          click_button('section_report_submit')

          expect(page).not_to have_selector('.test-standards-getting-started')

          step 'I can see my previous selections in the drop-downs' do
            expect(page).to have_select(
              'standard_set_display_name',
              options: %w[
                CCSS
                WIDA
              ],
              selected: 'CCSS'
            )
            expect(page).to have_select(
              'lesson_id',
              options: ['Select a Unit'] + course.lessons_covered.map(&:name),
              selected: lesson.name
            )
            expect(page).to have_selector(
              '#assessment_ids_select:not(.is-disabled) ' \
              "#assessment-option-0.selected-row #assessment-id-#{activity_1.id}"
            )
            expect(page).to have_button('section_report_submit', disabled: false)
          end

          step 'I can see the expected report headings' do
            validate_main_report_headings_are_visible(section)
          end

          step 'I can see the main body of the report' do
            validate_section_report_table_is_visible
          end

          step 'I can see the header for the selected assessment with the graded/student count' do
            validate_assessment_column_is_visible(activity_1)
          end

          step 'I can see the "Find Matching Content" table heading' do
            expect(page).to have_selector('th.test-find-matching-content', count: 1)
          end

          # The first standard displayed has no number and a description that sorts it to the top.
          report_standard = first('.test-linked-standard')
          report_standard_id = Standard.find_by(description: standard_description).id

          step "I can see the standard's truncated description when the standard has no number" do
            expect(report_standard.text).to eq(standard_description.truncate(30))
          end

          step 'I can see a link to search and assign content aligned with the standard' do
            search_link = "#{instructor_standards_assigning_path(program.id)}" \
                          "?standards=#{report_standard_id}" \
                          "&selected_unit=#{activity_1.lesson.unit_id}"

            expect(page).to have_css(
              ".test-search-standard-resources[href='#{search_link}']"
            )
          end

          step 'I can see the Standard column sorted ascending by default' do
            standard_header_sorting = find('.test-standard-header')['aria-sort']

            expect(standard_header_sorting).to eq('ascending')
          end

          step 'I can see the other sortable columns with no sorting attribute' do
            percent_correct_sorting = find(".test-#{activity_1.id}-header")['aria-sort']

            expect(percent_correct_sorting).to be_nil
          end

          step 'I can click on the standard header to make a descending sort' do
            within '.test-standard-header' do
              click_on 'Standard'
            end

            standard_header_sorting = find('.test-standard-header')['aria-sort']

            expect(standard_header_sorting).to eq('descending')
          end

          step 'I can click on any other sortable column to make a sort' do
            within ".test-#{activity_1.id}-header" do
              click_on 'End-of-Unit'
            end

            percent_correct_sorting = find((".test-#{activity_1.id}-header"))['aria-sort']

            expect(percent_correct_sorting).to eq('ascending')
          end

          step 'I can click on a standard to get to the student drill-down report' do
            report_standard = find('.test-linked-standard', match: :first)
            report_standard.click

            expect(page).to have_selector(
              '.test-unlinked-standard',
              count: 1
            )
          end
        end
      end

      context 'when the section has students' do
        scenario 'as an instructor navigating to the student drill-down report for a section' do
          pending('pending until we fix the default unit load')
          visit_student_report(instructor, section)

          purpose 'I can see the summary report' do
            step 'I can see the main report headings' do
              validate_main_report_headings_are_visible(section)
            end

            step 'I can see the "Find Matching Content" table heading' do
              expect(page).to have_selector('th.test-find-matching-content', count: 1)
            end

            expect(page).to have_selector(
              '.test-unlinked-standard',
              count: 1,
              exact_text: :standard_number
            )
            expect(page).not_to have_selector('.test-linked-standard')
            expect(page).to have_selector(
              '.test-return-to-section-report-link',
              count: 1,
              exact_text: 'Return'
            )
          end

          purpose 'I can see table headers with the sorting functionality' do
            step 'I can see the Student column sorted ascending by default' do
              student_header_sorting = find('.test-student-header')['aria-sort']

              expect(student_header_sorting).to eq('ascending')
            end

            step 'I can see the other sortable columns with no sorting attribute' do
              # We already have the same two classes for the section report table so
              # we need to make sure we are selecting the ones in the student report
              # table
              within '.test-student-table' do
                percent_correct_sorting = find(".test-#{activity_1.id}-header")['aria-sort']

                expect(percent_correct_sorting).to be_nil
              end
            end

            step 'I can click on the student header to make a descending sort' do
              within '.test-student-table' do
                click_on 'Student'

                student_header_sorting = find('.test-student-header')['aria-sort']

                expect(student_header_sorting).to eq('descending')
              end
            end

            step 'I can click on any other sortable column to make a sort' do
              within '.test-student-table' do
                click_on 'End-of-Unit'

                percent_correct_sorting = find(".test-#{activity_1.id}-header")['aria-sort']

                expect(percent_correct_sorting).to eq('ascending')
              end
            end
          end

          purpose 'I can see the body of the report' do
            expect(page).to have_selector('.test-student-table', count: 1)
            expect(page).to have_selector('.test-student-result-row', count: 10)

            step 'I can click the Return link to return to the standards report' do
              return_to_section_report_from_student_report
            end
          end
        end

        scenario 'as an assistant instructor navigating to a standards report for a section' do
          pending('pending until we fix the default unit load')
          visit_section_report(assistant)

          purpose 'I can see the report once I have made selections from the drop-drowns' do
            step 'I can make selections from the drop-downs' do
              select(
                'CCSS',
                from: 'standard_set_display_name'
              )

              expect(page).to have_select(
                'standard_set_display_name',
                options: %w[
                  CCSS
                  WIDA
                ],
                selected: 'CCSS'
              )
              expect(page).to have_select(
                'lesson_id',
                options: ['Select a Unit'] + course.lessons_covered.map(&:name),
                selected: lesson.name
              )
              select(lesson.name)

              within('#assessment_ids_select') do
                click_on 'Select Assessments'
              end

              within('.assessment-options') do
                check activity_1.title, allow_label_click: true
              end

              click_button('section_report_submit')
            end

            step 'I can see the main report headings' do
              validate_main_report_headings_are_visible(section)
            end

            step 'I can see the main body of the report' do
              validate_section_report_table_is_visible
            end

            step 'I cannot see the "Find Matching Content" table heading' do
              expect(page).not_to have_selector('th.test-find-matching-content')
            end
          end
        end

        scenario 'as an assistant instructor navigating to the student drill-down report ' \
                 'for a section' do
          pending('pending until we fix the default unit load')
          visit_student_report(assistant, section)

          purpose 'I can see the summary report' do
            step 'I can see the main report headings' do
              validate_main_report_headings_are_visible(section)
            end

            step 'I can see the header for the selected assessment with the graded/student count' do
              validate_assessment_column_is_visible(activity_1)
            end

            step 'I cannot see the "Find Matching Content" table heading' do
              expect(page).not_to have_selector('th.test-find-matching-content')
            end
          end

          step 'I can click the Return link to return to the standards report' do
            return_to_section_report_from_student_report
          end
        end
      end

      context 'when the section does not have students' do
        let(:empty_section) do
          create(:section, name: 'ELD Empty Section', course:, instructor:)
        end

        scenario 'as an instructor navigating to the student drill-down report for a section' do
          pending('pending until we fix the default unit load')
          visit_student_report(instructor, empty_section)

          purpose 'I can see the summary report' do
            step 'I can see the main report headings' do
              validate_main_report_headings_are_visible(empty_section)
            end

            step 'I can see the "Find Matching Content" table heading' do
              expect(page).to have_selector('th.test-find-matching-content', count: 1)
            end

            expect(page).to have_selector(
              '.test-unlinked-standard',
              count: 1,
              exact_text: :standard_number
            )
            expect(page).not_to have_selector('.test-linked-standard')
            expect(page).to have_selector(
              '.test-return-to-section-report-link',
              count: 1,
              exact_text: 'Return'
            )
          end

          purpose 'I can see the "Go to Enroll" link' do
            expect(page).to have_selector(
              '.test-go-to-enroll-link',
              count: 1,
              exact_text: 'Go to Enroll'
            )
          end
        end
      end
    end

    context 'with a course not configured for ELD standards' do
      let(:program_2) { create(:program) }
      let(:course_2) { create(:course, owner: instructor, program: program_2) }
      let(:section_2) { create(:section, course: course_2, instructor:) }
      let!(:section_3) { create(:section, name: 'ELD Section 3', course: course_2, instructor:) }

      before do
        create(:program_config_with_standard_sets, program: program_2)
        initialize_program_access_client_calls_for_instructor(instructor, program_2)
      end

      scenario 'as an instructor navigating to a standards report for a section' do
        log_in_as(instructor)
        visit instructor_dashboard_path(
          program_id: program_2.id,
          course_id: course_2.id,
          section_id: section.id
        )

        find('.test-grading-link').click
        click_on('Analytics')

        step 'I can see the Standard sub-link' do
          find('.test-analytics-tab').click
          expect(page).to have_button('Assess to Learn')
        end

        step 'I can not see drop-downs to filter the report' do
          find('.test-analytics-tab').hover
          click_button('Assess to Learn')
          expect(page).not_to have_select('section_report_standard_set_display_name')
          expect(page).not_to have_select('section_report_lesson_id')
          expect(page).not_to have_select('section_report_assessment_id')
          expect(page).to have_button('Go', disabled: false)
        end
      end
    end

    context 'with a program not configured for ELD standards' do
      let(:non_standards_program) { create(:program_with_toc_entries) }
      let(:non_standards_course) do
        create(:course, owner: instructor, program: non_standards_program)
      end
      let!(:non_standards_section) do
        create(:section, course: non_standards_course, instructor:)
      end

      before do
        initialize_program_access_client_calls_for_instructor(instructor, non_standards_program)
      end

      scenario 'as an instructor navigating to a standards report for a section' do
        log_in_as(instructor)

        visit instructor_dashboard_path(program_id: non_standards_program.id)

        find_by_id('tour-guide-nav-grades').click # this is the Grade menu option
        click_link 'Gradebook'

        purpose 'I do not see the Standards menu option in the Analytics menu' do
          within('.test-gradebook-subnav') do
            expect(page).not_to have_link('Assess to Learn')
          end
        end

        purpose 'when trying to visit the section report page' do
          log_in_as(instructor)
          visit instructor_dashboard_path(
            course_id: non_standards_course.id,
            program_id: non_standards_program.id,
            section_id: non_standards_section.id
          )

          find('.test-grading-link').click
          click_on('Analytics')
          find('.test-analytics-tab').hover

          expect(page).to have_current_path(
            gradebook_engine.course_section_analytics_overview_path(
              course_id: non_standards_course.id,
              program_id: non_standards_program.id,
              section_id: non_standards_section.id
            )
          )
        end
      end
    end
  end

  def validate_initial_filters_state
    step 'I can see the standards filter' do
      expect(page).to have_select('standard_set_display_name')
    end

    step 'I can see the unit filter' do
      expect(page).to have_select('lesson_id')
    end

    step 'I can see the assessment multi select filter' do
      expect(page).to have_selector('.test-assessment-multi-select')
    end

    step 'I can see the assessment type select filter' do
      expect(page).to have_select('assessment_type')
    end

    step 'I can see the assessment type filter with default value of "proficiency"' do
      expect(page.find('.test-assessment-type').value).to eq('proficiency')
    end

    step 'I can see the Go button in enabled state' do
      expect(page).to have_button('Go', disabled: false)
    end
  end

  def select_progress_monitoring_type_filter
    step 'I can see the assessment type select filter' do
      expect(page).to have_select('assessment_type')
    end
  end

  def validate_filters_state_for_progress_monitoring
    step 'I can select Progress Monitoring value' do
      page.find('.test-assessment-type')
          .find("option[value='progress_monitoring']").select_option
    end

    step 'I can see the assessment type filter with value of progress_monitoring' do
      expect(page.find('.test-assessment-type').value).to eq('progress_monitoring')
    end

    step 'I can see the Category filter' do
      expect(page.find('.test-category-multi-select')).to be_visible
    end

    step 'I cannot see the Assessment Multi Filter' do
      expect(page.find('.test-assessment-multi-select')).not_to be_visible
    end

    step 'I can see the Category filter with "2 Selected" text' do
      within('.test-category-multi-select') do
        expect(page).to have_text('2 Selected')
      end
    end
  end

  def apply_filters_to_view_pmr_reports
    step 'I can click on Go button' do
      page.find('.test-filter-apply-btn').click
      wait_for_ajax
    end
  end

  def validate_pmr_by_assessments_page_data
    step 'I can see the Progress Monitoring Assessment table view' do
      header_data = pmr_data[:header_for_view_by_assessments]
      table_data = pmr_data[:data_for_view_by_assessments]
      validate_pmr_by_assessments_data(page, header_data, table_data)
    end

    step 'I cannot see the Progress Monitoring Assessment standard view' do
      expect(page).not_to have_selector('.test-pmr-standards-table')
    end

    within('.test-section-summary-table') do
      step 'I can see the "Before You Read: Build Vocabulary" activity in the table' do
        expect(page).to have_selector(
          '.row-header-txt',
          text: 'Before You Read: Build Vocabulary'
        )
      end

      step 'I cannot see the "End-of-Unit Assessment" activity in the table' do
        expect(page).not_to have_selector(
          '.row-header-txt',
          text: 'End-of-Unit Assessment'
        )
      end
    end
  end

  def change_to_view_pmr_by_standard_tab
    step 'I can click on View By Standard tab button' do
      page.find('.test-tab-show-by-standards-report').click
    end
  end

  def validate_pmr_view_by_standards_page_data
    within('.section-report-table') do
      step 'validates the data in each row of the report table' do
        header_data = pmr_data[:header_for_view_by_standards]
        table_data = pmr_data[:data_for_view_by_standards]
        validate_pmr_by_standards_data(page, header_data, table_data)
      end
    end
  end

  def click_standard_link_on_pmr_by_standards_view(standard_txt)
    step 'I can click on first Standard link' do
      page.find('.section-report-table .test-linked-standard', text: standard_txt).click
    end
  end

  def validate_pmr_standard_detail_page_data
    step 'I can see single standard table' do
      expect(page).to have_selector('.test-table-mode-pmr-students')
    end

    step 'I can see student performance table' do
      expect(page).to have_selector('.test-table-mode-pmr-students')
    end

    step 'validates the data in single standard table' do
      header_data = pmr_data[:header_for_single_standard]
      table_data = pmr_data[:data_for_single_standard]
      validate_pmr_single_standard_table_data(page, header_data, table_data)
    end

    step 'validates the data in student performance table' do
      sort = :student_asc
      header_data = pmr_data[:header_for_student_performace]
      table_data = pmr_data[:data_for_student_performace][sort]
      validate_pmr_student_performace_data(page, header_data, table_data)
    end
  end

  def validate_pmr_standard_detail_page_sorting
    step 'click to sort by student name in desending order' do
      find('.test-table-header', text: 'student').click
    end

    step 'validates the sort by student names in student performance table' do
      sort = :student_desc
      header_data = pmr_data[:header_for_student_performace]
      table_data = pmr_data[:data_for_student_performace][sort]
      validate_pmr_student_performace_data(page, header_data, table_data)
    end

    step 'click to sort by percent score in a category in descending order' do
      within(page.find('.test-table-mode-pmr-students')) do
        find('.test-table-header', text: 'Quizzes').click
      end
    end

    step 'validates the sort by percent score in a category in student performance table' do
      sort = :quizzes_desc
      header_data = pmr_data[:header_for_student_performace]
      table_data = pmr_data[:data_for_student_performace][sort]
      validate_pmr_student_performace_data(page, header_data, table_data)
    end
  end

  def validate_how_to_use_modal
    step 'In section report, I can see How to Use link' do
      expect(find('.test-how-to-use-btn')).to have_text('How to Use')
    end

    step 'I can click how to use button to open modal' do
      page.find('.test-how-to-use-btn').click
    end

    step 'I can see the modal that outlines the section tab information' do
      expect(
        find('.test-standard-report-info-modal')
      ).to have_selector('.test-section-tab-information-modal')
    end

    step 'I cannot see the modal that outlines the student tab information' do
      expect(
        find('.test-standard-report-info-modal')
      ).not_to have_selector('.test-student-tab-information-modal')
    end

    step 'I can close the current modal' do
      page.find('.test-close-how-to-use-modal').click
    end

    step 'I can click Student report tab and can click How to Use link' do
      page.find('.test-show-student-report').click
      page.find('.test-how-to-use-btn').click
    end

    step 'I can see the modal that outlines the student tab information' do
      expect(
        find('.test-standard-report-info-modal')
      ).to have_selector('.test-student-tab-information-modal')
    end

    step 'I cannot see the modal that outlines the section tab information' do
      expect(
        find('.test-standard-report-info-modal')
      ).not_to have_selector('.test-section-tab-information-modal')
    end
  end

  def return_to_pmr_by_assessments_page
    step 'I can click the Return link to return to the standards report' do
      return_to_section_report_from_student_report
    end
  end

  def click_first_standard_link_on_pmr_by_assessments_view
    step 'I can click on first Standard link' do
      page.first('.section-report-table .test-data-cell .test-data-percent-box').click
    end
  end

  def validate_pmr_by_assessments_data(page, expected_header_row_data, expected_row_data)
    expect(page).to have_selector('.test-section-report-table-by-assessment')
    expect(page).to have_selector('.test-section-report-table-by-assessment tbody tr')

    header_row = page.find('.test-section-report-table-by-assessment thead tr:first-child')
    header_row_txt = header_row.all('.test-display-header-text')
    actual_header_row_data = header_row_txt.map(&:text)
    expect(actual_header_row_data).to eq(expected_header_row_data)

    rows = page.all('.test-section-report-table-by-assessment tbody tr')
    actual_row_data = rows.map do |row|
      data_elms = row.all('
      .test-row-header-txt,
      .test-attempted-student-count,
      .test-data-cell .test-data-percent-box,
      .test-data-cell .test-data-desc-box')
      data_elms.map(&:text)
    end
    expect(actual_row_data).to eq(expected_row_data)
  end

  def validate_pmr_by_standards_data(page, expected_header_row_data, expected_row_data)
    header_row = page.find('.test-section-report-table-by-standards thead tr:first-child')
    header_row_txt = header_row.all('.test-display-header-text')
    actual_header_row_data = header_row_txt.map(&:text)
    expect(actual_header_row_data).to eq(expected_header_row_data)

    rows = page.all('.test-section-report-table-by-standards tbody tr')
    actual_row_data = rows.map do |row|
      data_elms = row.all('
      .test-row-header-txt,
      .test-data-cell .test-data-percent-box,
      .test-data-cell .test-data-desc-box')
      data_elms.map(&:text)
    end
    expect(actual_row_data).to eq(expected_row_data)
  end

  def validate_pmr_single_standard_table_data(page, expected_header_row_data, expected_row_data)
    single_standard_table = page.find('.test-table-mode-pmr-single-standard')
    header_row = single_standard_table.find('thead tr:first-child')
    actual_header_row_data = header_row.all(
      '.test-header-text, .test-submission-count-info-txt'
    ).map(&:text)
    expect(actual_header_row_data).to eq(expected_header_row_data)

    rows = page.all('.test-table-mode-pmr-single-standard tbody tr')
    actual_row_data = rows.map do |row|
      data_elms = row.all('
      .test-row-header-txt,
      .test-item-count,
      .test-data-percent-box,
      .test-data-desc-box,
      .test-no-grade-percent-box')
      data_elms.map(&:text)
    end
    expect(actual_row_data).to eq(expected_row_data)
  end

  def validate_pmr_student_performace_data(page, expected_header_row_data, expected_row_data)
    student_performace_table = page.find('.test-table-mode-pmr-students')
    header_row = student_performace_table.find('thead tr:first-child')
    actual_header_row_data = header_row.all('td, th').map(&:text)
    expect(actual_header_row_data).to eq(expected_header_row_data)

    rows = page.all('.test-table-mode-pmr-students tbody tr')
    actual_row_data = rows.map do |row|
      data_elms = row.all('
      .test-link-to-gradebook,
      .test-item-count,
      .test-data-percent-box,
      .test-data-desc-box,
      .test-no-grade-percent-box')
      data_elms.map(&:text)
    end
    expect(actual_row_data).to eq(expected_row_data)
  end

  shared_examples 'data validation steps for progress monitoring views' do
    before do
      course.standard_sets << [standard_set_wida_1, standard_set_wida_2, standard_set_cc]

      standards = load_fixture('standards_cc')
      Standard.create(standards)

      standard_assets = load_fixture('standard_assets')
      StandardAsset.create!(standard_assets)

      standard_alignments = load_fixture('standard_alignments')
      StandardAlignment.create!(standard_alignments)

      results_fixture = load_fixture(standards_results_file_name)
      standards_results_data = results_fixture.each_with_index do |standards_result, index|
        standards_result['user_id'] = create(
          :student,
          first_name: "firstname-#{index}",
          last_name: "lastname-#{index}"
        ).id
        standards_result['section_id'] = section.id
      end
      StandardsResults.create(standards_results_data)

      assessment_items = load_fixture(assessment_items_file_name)
      assessment_items.each do |assessment_item|
        vendor_guid = assessment_item['guid']
        standard_asset = StandardAsset.find_by(vendor_guid:)
        standard_asset.create_assessment_item(assessment_item)
      end

      user_ids = StandardsResults.pluck(:user_id).sort.uniq.take(10)
      user_ids.each do |user_id|
        student = Student.find user_id
        create(:enrollment, section:, user: student)
      end

      # rubocop:disable RSpec/AnyInstance
      # rubocop:disable RSpec/VerifiedDoubles
      allow_any_instance_of(Activity).to receive(:questions).and_return(
        [
          double('Question', question_guid: 'question-guid-1'),
          double('Question', question_guid: 'question-guid-2')
        ]
      )
      # rubocop:enable RSpec/VerifiedDoubles
      # rubocop:enable RSpec/AnyInstance

      create(:program_config_with_standard_sets, program:)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      initialize_program_access_client_calls_for_instructor(assistant, program)
      allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
    end

    context 'with a program that supports both Progress Monitoring and Proficiency Assessment' do
      before do
        stub_request(:get, '/assets/opentok.min.js.map')
        create(:program_config_with_standard_sets, program:)
        initialize_program_access_client_calls_for_instructor(instructor, program)
        log_in_as(instructor)
        visit instructor_dashboard_path(
          program_id: program.id,
          course_id: course.id,
          section_id: section.id
        )
        find('.test-grading-link').click
        click_on('Analytics')
      end

      scenario 'as an instructor navigating to a standards report ' \
               'for Progress Monitoring assessments for a section' do
        step 'I can see the Standard sub-link' do
          find('.test-analytics-tab').click
          expect(page).to have_button('Assess to Learn')
        end

        step 'I can click on Assess to Learn link' do
          find('.test-analytics-tab').hover
          click_button('Assess to Learn')
        end

        step 'I can see all the select filters of the report' do
          validate_initial_filters_state
        end

        step 'I can change the assessment type to Progress Monitoring and view the report page' do
          select_progress_monitoring_type_filter
          validate_filters_state_for_progress_monitoring
          apply_filters_to_view_pmr_reports
        end

        step 'I can see data in view by assessments and view by standards page' do
          validate_pmr_by_assessments_page_data
          change_to_view_pmr_by_standard_tab
          validate_pmr_view_by_standards_page_data
        end

        step 'I can navigate from by-standards view to standard detail page and see data' do
          click_standard_link_on_pmr_by_standards_view(single_standard)
          validate_pmr_standard_detail_page_data
          validate_pmr_standard_detail_page_sorting
        end

        step 'I can return from standard detail page and see data' do
          return_to_pmr_by_assessments_page
          validate_pmr_by_assessments_page_data
        end

        step 'I can navigate from by-assessments view to standard detail page and see data' do
          click_first_standard_link_on_pmr_by_assessments_view
          validate_pmr_standard_detail_page_data
        end

        step 'I can see How to Use link and click to see the modal for section and student report' do
          validate_how_to_use_modal
        end
      end
    end
  end

  context 'with simple progress monitoring assessment data' do
    let(:pmr_data) do
      {
        header_for_view_by_assessments: ['Progress Monitoring', 'Standards'],
        data_for_view_by_assessments: [
          ['Before You Read: Build Vocabulary', '3 of 3',
           '33%', '(0.3 of 1.0)', '67%', '(0.7 of 1.0)', '67%', '(0.7 of 1.0)'],
          ['Before You Read: Analyze Chronology', '0 of 3'],
          ['Writing Test', '0 of 3']
        ],
        header_for_view_by_standards: %w[Standards Assessment],
        data_for_view_by_standards: [
          ['CCSS.ELA-Literacy.RL.7.2', '67%', '(0.7 of 1.0)'],
          ['CCSS.ELA-Literacy.RL.7.5', '67%', '(0.7 of 1.0)'],
          ['zzFAKE.ELA-Literacy.RL.7.1', '33%', '(0.3 of 1.0)']
        ],
        header_for_single_standard: ['Standards', 'Quizzes', '3 of 6',
                                     'Speaking and Writing Tests', '0 of 3'],
        data_for_single_standard: [
          ['zzFAKE.ELA-Literacy.RL.7.1', '1 Items', '33%', '--']
        ],
        header_for_student_performace: ['Student', 'Quizzes', 'Speaking and Writing Tests'],
        data_for_student_performace: {
          student_asc: [
            ['lastname-0, firstname-0', '0%', '--'],
            ['lastname-1, firstname-1', '0%', '--'],
            ['lastname-2, firstname-2', '100%', '--']
          ],
          student_desc: [
            ['lastname-2, firstname-2', '100%', '--'],
            ['lastname-1, firstname-1', '0%', '--'],
            ['lastname-0, firstname-0', '0%', '--']
          ],
          quizzes_desc: [
            ['lastname-2, firstname-2', '100%', '--'],
            ['lastname-0, firstname-0', '0%', '--'],
            ['lastname-1, firstname-1', '0%', '--']
          ]
        }
      }
    end
    let(:single_standard) { 'zzFAKE.ELA-Literacy.RL.7.1' }
    # In these data fixtures, mapping of assessments items with standards is used as is
    # from existing files. But and assessment items from existing assessment_items.json
    # are copied and assessments are made smaller with less number of items.
    # In this standard result fixure, there is only one simple pmr assessment.
    let(:standards_results_file_name) { 'standards_results_pmr_simple' }
    let(:assessment_items_file_name) { 'assessment_items_pmr_simple' }

    include_examples 'data validation steps for progress monitoring views'
  end

  context 'with 3 progress monitoring and 1 proficiency assessments in the section' do
    let(:pmr_data) do
      {
        header_for_view_by_assessments: ['Progress Monitoring', 'Standards'],
        data_for_view_by_assessments: [
          ['Before You Read: Build Vocabulary', '1 of 4',
           '100%', '(1 of 1)', '100%', '(1 of 1)', '100%', '(3 of 3)'],
          ['Before You Read: Analyze Chronology', '1 of 4',
           '0%', '(0 of 1)', '100%', '(2 of 2)', '100%', '(1 of 1)'],
          ['Writing Test', '1 of 4', '100%', '(1 of 1)']
        ],
        header_for_view_by_standards: %w[Standards Assessment],
        data_for_view_by_standards: [
          ['A fake description with mor...', '100%', '(1 of 1)'],
          ['CCSS.ELA-Literacy.L.7.1', '100%', '(2 of 2)', '100%', '(1 of 1)'],
          ['CCSS.ELA-Literacy.RL.7.2', '100%', '(1 of 1)'],
          ['CCSS.ELA-Literacy.RL.7.4', '0%', '(0 of 1)', '100%', '(1 of 1)'],
          ['zzFAKE.ELA-Literacy.RL.7.1', '100%', '(3 of 3)']
        ],
        header_for_single_standard: ['Standards', 'Quizzes', '2 of 8',
                                     'Speaking and Writing Tests', '1 of 4'],
        data_for_single_standard: [
          ['A fake description with mor...', '1 Items', '100%', '--']
        ],
        header_for_student_performace: ['Student', 'Quizzes', 'Speaking and Writing Tests'],
        data_for_student_performace: {
          student_asc: [
            ['lastname-0, firstname-0', '--', '--'],
            ['lastname-1, firstname-1', '100%', '--'],
            ['lastname-2, firstname-2', '--', '--'],
            ['lastname-3, firstname-3', '--', '--']
          ],
          student_desc: [
            ['lastname-3, firstname-3', '--', '--'],
            ['lastname-2, firstname-2', '--', '--'],
            ['lastname-1, firstname-1', '100%', '--'],
            ['lastname-0, firstname-0', '--', '--']
          ],
          quizzes_desc: [
            ['lastname-1, firstname-1', '100%', '--'],
            ['lastname-0, firstname-0', '--', '--'],
            ['lastname-2, firstname-2', '--', '--'],
            ['lastname-3, firstname-3', '--', '--']
          ]
        }
      }
    end
    let(:single_standard) { 'A fake description with mor...' }
    # In these data fixtures, mapping of assessments items with standards is used as is
    # from existing files. But and assessment items from existing assessment_items.json
    # are copied and assessments are made smaller with less number of items.
    # In the standard result fixure, first object is related to proficiency and rest are for pmr.
    let(:standards_results_file_name) { 'standards_results_pmr' }
    let(:assessment_items_file_name) { 'assessment_items_pmr' }

    include_examples 'data validation steps for progress monitoring views'
  end
end
