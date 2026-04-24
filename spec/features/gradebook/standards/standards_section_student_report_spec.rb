feature 'Standards Section Report',
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
    let(:activity_1_attrs) do
      {
        id: 835_536,
        title: 'End-of-Unit Assessment',
        component_name: 'Assessment',
        lesson_id: lesson.id,
        cms_activity_id: 285_669,
        toc_location_rank: 20,
        points_possible: 41,
        activity_type: 'exam'
      }
    end
    let!(:activity_1) do
      create_activity_with_unit_lesson_and_concept(
        program,
        activity_1_attrs
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

    def load_fixture(name)
      file_path = Rails.root.join('spec', 'fixtures', 'json', "#{name}.json")
      JSON.parse(File.read(file_path))
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

    before do
      course.standard_sets << [standard_set_wida_1, standard_set_wida_2, standard_set_cc]

      standards = load_fixture('standards_cc')
      Standard.create(standards)

      standard_assets = load_fixture('standard_assets')
      StandardAsset.create!(standard_assets)

      standard_alignments = load_fixture('standard_alignments')
      StandardAlignment.create!(standard_alignments)

      standards_results_data = load_fixture('standards_results').each do |standards_result|
        standards_result['section_id'] = section.id
        standards_result['user_id'] = create(:student).id
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
      allow_any_instance_of(Activity).to receive(:proficiency_assessment?) do |activity|
        activity == activity_1
      end
      # rubocop:enable RSpec/AnyInstance

      create(:program_config_with_standard_sets, program:)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      initialize_program_access_client_calls_for_instructor(assistant, program)
      allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
    end

    context 'with a course configured for ELD standards' do
      # TODO: pending until we fix the default unit load.
      xscenario 'as an instructor navigating to a standards report for a section' do
        visit_section_report(instructor)

        purpose 'I can go to the Standards page' do
          expect(page).to have_current_path(
            "#{gradebook_standards_section_report_path(
              program_id: program.id,
              course_id: course.id,
              section_id: section.id
            )}?direction=asc&sort=standard"
          )
        end

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
            selected: lesson.name
          )

          select(lesson.name, from: 'lesson_id')
        end

        step 'I select an assessment' do
          expect(page).to have_button(
            'Select Assessments',
            disabled: false
          )

          click_button('Select Assessments')
          check(activity_1.title, allow_label_click: true)

          expect(page).to have_button('section_report_submit', disabled: false)
        end

        purpose 'I can see the export button enabled once after click on Go button' do
          click_button('section_report_submit')
          expect(page).to have_button('Export', disabled: false)
        end

        purpose 'I can see the export button on the Student drill-down report page' do
          step 'Select a standard and click it to get to the student drill-down report' do
            report_standard = find('.test-linked-standard', match: :first)
            report_standard.click

            expect(page).to have_selector('.test-student-table', count: 1)
            expect(page).to have_selector('.test-student-result-row', count: 10)
            expect(page).to have_button('Export', disabled: false)
          end
        end
      end
    end
  end
