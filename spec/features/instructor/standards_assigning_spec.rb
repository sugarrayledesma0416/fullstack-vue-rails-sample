feature 'Standards Assign Search', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor_owner) { create(:instructor) }
  let(:instructor_assistant) { create(:instructor) }
  let(:instructor_with_no_course) { create(:instructor) }
  let(:category) { create(:category, weighting_percent: 100) }
  let(:co_instructor) { create(:instructor) }
  let(:co_instructor_with_no_course) { create(:instructor) }
  let(:school) { create(:school) }
  let(:standards_program) { create(:program_with_toc_entries) }
  let(:strand) { create(:toc_entry) }
  let(:non_standards_program) { create(:program) }

  let(:standards_course) do
    create(:open_course,
           school:,
           owner: instructor_owner,
           program: standards_program,
           categories: [category])
  end

  let(:standards_section) do
    create(:section, course: standards_course, instructor: instructor_owner)
  end

  let(:other_standards_section) do
    create(:section, course: standards_course, instructor: instructor_owner)
  end

  let(:non_standards_course) do
    create(:open_course, school:, owner: instructor_owner, program: non_standards_program)
  end

  let(:non_standards_section) do
    create(:section, course: non_standards_course, instructor: instructor_owner)
  end

  # Set up standards and alignment data

  # Activity associated with current program
  let(:activity_1) { create(:activity, lesson: standards_program.lessons.first) }

  # Set up a Standard with associated StandardSet
  let(:standard_set) { create(:standard_set) }
  let(:standard) { create(:standard, standard_set: standard_set) }

  # Set up StandardAsset & Alignment data using above standard
  let(:standard_asset_1) { create(:standard_asset, reference_id: activity_1.cms_activity_id) }

  let!(:standard_alignment_1) do
    create(
      :standard_alignment,
      standard_asset: standard_asset_1,
      vendor_standard_guid: standard.vendor_guid
    )
  end

  before do
    allow_any_instance_of(Activity).to receive(:strand).and_return(strand)
    create(:school_user, user: instructor_owner, school:)
    create(:school_user, user: instructor_assistant, school:)
    create(:school_user, user: instructor_with_no_course, school:)
    create(:school_user, user: co_instructor, school:)
    create(:school_user, user: co_instructor_with_no_course, school:)
    create(:section_instructor, section_id: standards_section.id,
                                user_id: instructor_assistant.id,
                                role: 'Assistant')
    create(:section_instructor, section_id: standards_section.id,
                                user_id: co_instructor.id,
                                role: 'Co-Instructor')
    create(:section_instructor, section_id: other_standards_section.id,
                                user_id: instructor_assistant.id,
                                role: 'Assistant')
    create(:section_instructor, section_id: other_standards_section.id,
                                user_id: co_instructor.id,
                                role: 'Co-Instructor')
    # TODO - subbing API calls will need to be refined when adding
    # coverage for course/section feature availability.
    allow(Maestro::CourseLicense).to receive(:all).and_return(
                                       [
                                         Maestro::CourseLicense.new(
                                           'license_group' => { 'id' => 1, 'demo' => false }
                                         )
                                       ]
                                     )
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    initialize_program_access_client_calls_for_instructor(instructor_owner, standards_program)
    initialize_program_access_client_calls_for_instructor(instructor_assistant, standards_program)
    initialize_program_access_client_calls_for_instructor(instructor_with_no_course, standards_program)

    standards_searcher = instance_double(StandardsMapping::StandardsSearch)


    standards_search_result = [
      {
        vendor_guid: standard.vendor_guid,
        name: standard.name,
        number: standard.number,
        label: standard.label,
        description: standard.description,
        vendor_standard_set_guid: standard.vendor_standard_set_guid,
        issuer: standard.standard_set.issuer,
        display_name: standard.standard_set.display_name,
        parent: {
          # TODO - set up a parent standard
          # vendor_guid: parent_standard.vendor_guid,
          # name: parent_standard.name,
          # number: parent_standard.number,
          # label: parent_standard.label,
          # description: parent_standard.description,
          # vendor_standard_set_guid: parent_standard.vendor_standard_set_guid,
          # issuer: parent_standard.standard_set.issuer,
          # display_name: parent_standard.standard_set.display_name
        }
      }
    ]

    browse_standards_empty_results = {
      "matched_browse_standards": {
        "Grade 2": []
      }
    }

    aligned_items_result = [
      {
        standard_asset_id: standard_set.id,
        reference_type: 'Activity',
        reference_id: activity_1.cms_activity_id
      }
    ]

    allow(standards_searcher)
      .to receive(:search_standards)
      .with([
        standard_set.vendor_guid],
        'search term',
        %w[K 1 2 3 4 5 6 7 8 9 10 11 12],
        standards_program.id
      )
      .and_return(standards_search_result)

    allow(standards_searcher)
      .to receive(:search_standard_assets)
      .with(
        [standard.vendor_guid],
        standards_program.id,
        hash_including(
          unit_id: standards_program.lessons.map(&:unit_id),
          next_key: anything,
          selected_skills: anything,
          selected_refinements: anything
        )
      )
      .and_return(aligned_items_result)

    allow(standards_searcher)
      .to receive(:browse_standards)
      .with(
        [standard_set.vendor_guid],
        %w[K 1 2 3 4 5 6 7 8 9 10 11 12],
        standards_program.id
      ).and_return(browse_standards_empty_results)

    allow(StandardsMapping::StandardsSearch).to receive(:new).and_return(standards_searcher)
  end

  context 'with a program with supported standard sets' do
    before do
      allow(GradebookEngine::Section)
        .to(receive(:find)).and_return(standards_section)

      create(
        :program_config_with_std_sets_and_skills_refinements,
        program: standards_program,
        supported_standard_sets: [standard_set]
      )
      CourseStandardSet.create(
        course: standards_course,
        standard_set: standard_set
      )
    end

    context 'with an instructor with assigning abilities' do
      context 'with an open course and section' do
        before do
          log_in_as(instructor_owner)
        end

        scenario 'I can select skills and refinements from skills filter' do
          step 'Navigate to instructor dashboard page' do
            visit instructor_dashboard_path(standards_program.id)
          end

          step 'Click Assign in Content Menu' do
            find('.test-content-menu', text: 'Assign').click
          end

          step 'Click Standards-based Assigning' do
            find('.test-standards-assign', text: 'Standards-based Assigning').click
          end

          step 'Verify Browse Button is by default selected' do
            expect(find('.test-browse-button')[:class]).to include('active')
          end

          step 'Verify that Search Standard button is not selected by default' do
            expect(find('.test-search-button')[:class]).not_to include('active')
          end

          step 'Verify Skills Dropdown is Present' do
            expect(page).to have_selector('.test-skills-dropdown', text: 'Select Skill')
          end

          step 'Open Standard Set Dropdown' do
            find('.test-standard-set-select').click
          end

          step 'Select first option from the dropdown' do
            within('.test-standard-set-select') do
              find('.test-option-0').click
            end
          end

          step 'Click Next button' do
            find('.test-find-browse-std').click
          end

          wait_for_ajax

          # step 'Verify if the breadcrumn is visible' do
          #   expect(page).to have_css('.test-breadcrumb-wrapper', visible: true)
          # end

          step 'Open Skills Options' do
            find('.test-skills-dropdown').click
          end

          step 'Verify Skills Options Container is Visible' do
            expect(page).to have_css('.test-skills-options-container', visible: true)
          end

          step 'Select First Skill' do
            @first_skill = find('.test-skill-option', match: :first)
            @first_skill.find('.test-skill-checkbox').click
          end

          step 'Verify Refinements Container is Visible' do
            expect(page).to have_css('.test-refinements-container', visible: true)
          end

          step 'Verify All Refinements are Checked' do
            @first_skill.all('.test-refinement').each do |refinement|
              expect(refinement.find('.test-refinement-checkbox')).to be_checked
            end
          end

          step 'Uncheck First Skill' do
            @first_skill = find('.test-skill-option', match: :first)
            @first_skill.find('.test-skill-checkbox').click
          end
        end

        scenario 'I cannot see Skills and refinements filters when ' \
                 'show_skills_and_refinement_filters is false' do
          allow_any_instance_of(ProgramConfig).to receive(:show_skills_and_refinement_filters).and_return(false)

          visit instructor_dashboard_path(standards_program.id)
          find('.test-content-menu', text: 'Assign').click
          find('.test-standards-assign', text: 'Standards-based Assigning').click

          expect(page).not_to have_selector('.test-skills-dropdown', text: 'Select Skill')
        end

        scenario 'I can navigate to the Standards-base assigning feature' do
          step 'Navigate to instructor dashboard page' do
            visit instructor_dashboard_path(standards_program.id)
          end

          step 'Click Assign in Content Menu' do
            find('.test-content-menu', text: 'Assign').click
          end

          step 'Click Standards-based Assigning' do
            find('.test-standards-assign', text: 'Standards-based Assigning').click
          end

          step 'I see the page with standards assign search' do
            expect(page).to have_selector('.test-standards-assign-search')
          end

          within('.js-standards-assigning') do
            step 'I can search for standards' do
              find('.test-search-button').click
            end

            step 'I can select a standard set' do
              find('.test-standard-set-select').click
            end

            step 'I can select the first option from the standard set dropdown' do
              within('.test-standard-set-select') do
                find('.test-option-0').click
              end
            end
            
            step 'I can add a search term' do
              find('.test-search-term-input').set('search term')
            end

            step 'I can click the search button' do
              find('.test-find-btn').click
            end

            wait_for_ajax

            step 'I can select the specific standard from the search results' do
              find('.test-matched-standard-label-0').click
            end

            step 'I can click the apply filter button' do
              find('.test-find-content').click
            end

            wait_for_ajax
            expect(page).to have_selector('.aligned-items-results')
            expect(page).to have_selector(
              ".test-strand-color-#{activity_1.lesson_id}-#{activity_1.concept_id}"
            )
          end
        end

        context 'I can navigate with a standards param to pre-populate results' do
          # TODO: pending until we fix the default unit load.
          xscenario 'with a bad standards param value' do
            path = "#{instructor_standards_assigning_path(standards_program.id)}?standards=blah"
            visit path
            expect(find('.js-flash-banner-group').text).to match(/No matching standards found/)
          end

          xscenario 'with a good standards param value' do
            # TODO - get this working - needs aligned results to work.
            standard = create(:standard)
            path = "#{instructor_standards_assigning_path(standards_program.id)}?standards=#{standard.id}"
            visit path
            expect(page).not_to have_selector('#search-term-input')
          end
        end
      end

      context 'with no course' do
        before do
          log_in_as(instructor_with_no_course)
        end

        scenario 'I cannot navigate to the Standards-based assigning feature' do
          visit instructor_dashboard_path(standards_program.id)
          find('.test-content-menu', text: 'Assign').click
          find('.test-standards-assign-disabled', text: 'Standards-based Assigning').click
          expect(page).not_to have_selector('.test-standards-assign-search')
        end
      end
    end

    context 'with an assistant, I can not see standards-based assigning menu' do
      before do
        log_in_as(instructor_assistant)
      end

      scenario 'I cannot select standards-based assigning option in assign menu' do
        visit instructor_dashboard_path(standards_program.id)
        find('.test-content-menu', text: 'Assign').click
        expect(page).not_to have_selector('.test-standards-assign')
      end
    end

    context 'with a co_instructor with assigning abilities' do
      context 'with an open course and section' do
        before do
          initialize_program_access_client_calls_for_instructor(co_instructor, standards_program)
          log_in_as(co_instructor)
        end

        scenario 'I can navigate to the Standards-base assigning feature' do
          step 'Navigate to instructor dashboard page' do
            visit instructor_dashboard_path(standards_program.id)
          end

          step 'Click Assign in Content Menu' do
            find('.test-content-menu', text: 'Assign').click
          end

          step 'Click Standards-based Assigning' do
            find('.test-standards-assign', text: 'Standards-based Assigning').click
          end

          step 'I see the page with standards assign search' do
            expect(page).to have_selector('.test-standards-assign-search')
          end

          within('.js-standards-assigning') do
            step 'I can search for standards' do
              find('.test-search-button').click
            end

            step 'I can select a standard set' do
              find('.test-standard-set-select').click
            end

            step 'I can select the first option from the standard set dropdown' do
              within('.test-standard-set-select') do
                find('.test-option-0').click
              end
            end
            
            step 'I can add a search term' do
              find('.test-search-term-input').set('search term')
            end

            step 'I can click the search button' do
              find('.test-find-btn').click
            end

            wait_for_ajax

            step 'I can select the specific standard from the search results' do
              find('.test-matched-standard-label-0').click
            end

            step 'I can click the apply filter button' do
              find('.test-find-content').click
            end

            wait_for_ajax

            step 'I can see the aligned items results' do
              expect(page).to have_selector('.aligned-items-results')
            end
          end
        end

        context 'I can navigate with a standards param to pre-populate results' do
          # TODO: pending until we fix the default unit load.
          xscenario 'with a bad standards param value' do
            path = "#{instructor_standards_assigning_path(standards_program.id)}?standards=blah"
            visit path
            expect(find('.js-flash-banner-group').text).to match(/No matching standards found/)
          end

          xscenario 'with a good standards param value' do
            # TODO - get this working - needs aligned results to work.
            standard = create(:standard)
            path = "#{instructor_standards_assigning_path(standards_program.id)}?standards=#{standard.id}"
            visit path
            expect(page).not_to have_selector('#search-term-input')
          end
        end

        scenario 'I can change the focus to a different course or section in the same program' \
                 'getting a warning dialog to confirm the focus change' do
          step 'Navigate to the instructor dashboard page' do
            visit instructor_dashboard_path(standards_program.id)
          end

          step 'Click Assign in the Content Menu' do
            find('.test-content-menu', text: 'Assign').click
          end

          step 'Click Standards-based Assigning' do
            find('.test-standards-assign', text: 'Standards-based Assigning').click
          end

          step 'Click the course focus header' do
            find('.test-course-focus__header').click
          end

          step 'Select a different section from the dropdown' do
            find(".test-section_#{standards_section.id}").click
          end

          step 'Verify the focus warning dialog is displayed' do
            expect(page).to have_selector('#focus-warning')
          end
        end

        context 'with no existing assignments' do
          scenario 'I dont see the due date of an assignment' do
            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end

              wait_for_ajax

              expect(page).not_to have_selector(".test-assign-due-date-#{activity_1.id}")
            end
          end

          scenario 'I see the due date of the assignment after assigning it' do
            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end

              wait_for_ajax
              find(".test-expand-content-#{activity_1.id}").click

              expect(page).not_to have_selector(".test-assign-due-date-#{activity_1.id}")
              all(".test-assign-content-#{activity_1.id}").first.click
            end

            wait_for_ajax
            click_button('save')
            wait_for_ajax

            step 'I see the due date of the assignment' do
              expect(page).to have_selector(".test-assign-due-date-#{activity_1.id}")
            end
          end
        end

        context 'with existing assignments' do
          before do
            create(:assignment, assignable: activity_1, section_id: standards_section.id)
          end

          scenario 'I see the due date of an assignment' do
            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Course Focus Header' do
              find('.test-course-focus__header').click
            end

            step 'Select a different section from the dropdown' do
              find(".test-section_#{standards_section.id}").click
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end
  
              wait_for_ajax

              expect(page).to have_selector(".test-assign-due-date-#{activity_1.id}")
              expect(page).not_to have_text('Varies')
            end
          end

          scenario 'I see item "assigned" but I dont see the due date ' \
                   'if item has not been open after first load' do
            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Course Focus Header' do
              find('.test-course-focus__header').click
            end

            step 'Select a different section from the dropdown' do
              find(".test-section_#{standards_section.id}").click
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end

              wait_for_ajax
              expect(find(".test-assign-due-date-#{activity_1.id}")).to have_text('Assigned')
            end
          end

          # scenario 'I see a due date varies if an activity is assigned in multiple due dates' do
          #   due_date_1 = Time.zone.now
          #   due_date_2 = due_date_1 + 2.days

          #   create(
          #     :assignment,
          #     assignable: activity_1,
          #     due_date: due_date_1
          #   )

          #   create(
          #     :assignment,
          #     assignable: activity_1,
          #     due_date: due_date_2
          #   )

          #   step 'Navigate to instructor dashboard page' do
          #     visit instructor_dashboard_path(standards_program.id)
          #   end

          #   step 'Click Assign in Content Menu' do
          #     find('.test-content-menu', text: 'Assign').click
          #   end

          #   step 'Click Standards-based Assigning' do
          #     find('.test-standards-assign', text: 'Standards-based Assigning').click
          #   end

          #   step 'I see the page with standards assign search' do
          #     expect(page).to have_selector('.test-standards-assign-search')
          #   end

          #   within('.js-standards-assigning') do
          #     step 'I can search for standards' do
          #       find('.test-search-button').click
          #     end

          #     step 'I can select a standard set' do
          #       find('.test-standard-set-select').click
          #     end

          #     step 'I can select the first option from the standard set dropdown' do
          #       within('.test-standard-set-select') do
          #         find('.test-option-0').click
          #       end
          #     end

          #     step 'I can add a search term' do
          #       find('.test-search-term-input').set('search term')
          #     end

          #     step 'I can click the search button' do
          #       find('.test-find-btn').click
          #     end

          #     wait_for_ajax

          #     step 'I can select the specific standard from the search results' do
          #       find('.test-matched-standard-label-0').click
          #     end

          #     step 'I can click the apply filter button' do
          #       find('.test-find-content').click
          #     end

          #     wait_for_ajax

          #     step 'Click assign due date' do
          #       all(".test-assign-due-date-#{activity_1.id}").first.click
          #     end

          #     wait_for_ajax

          #     step 'I see the due date varies' do
          #       expect(page).to have_selector(".test-assign-due-date-#{activity_1.id}")
          #     end
          #   end
          # end

          scenario 'I do not see the individual assigning ' \
                   'link if there is no individual assignment' do
            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end

              wait_for_ajax

              expect(page).not_to have_selector(".test-individually-assigned-#{activity_1.id}")
            end
          end

          scenario 'I see the individual assigning link if there is an individual assignment' do
            Assignment.where(assignable_id: activity_1.id)
                      .first
                      .update(individually_assignable: true)

            step 'Navigate to instructor dashboard page' do
              visit instructor_dashboard_path(standards_program.id)
            end

            step 'Click Assign in Content Menu' do
              find('.test-content-menu', text: 'Assign').click
            end

            step 'Click Standards-based Assigning' do
              find('.test-standards-assign', text: 'Standards-based Assigning').click
            end

            step 'I see the page with standards assign search' do
              expect(page).to have_selector('.test-standards-assign-search')
            end

            within('.js-standards-assigning') do
              step 'I can search for standards' do
                find('.test-search-button').click
              end

              step 'I can select a standard set' do
                find('.test-standard-set-select').click
              end

              step 'I can select the first option from the standard set dropdown' do
                within('.test-standard-set-select') do
                  find('.test-option-0').click
                end
              end

              step 'I can add a search term' do
                find('.test-search-term-input').set('search term')
              end

              step 'I can click the search button' do
                find('.test-find-btn').click
              end

              wait_for_ajax

              step 'I can select the specific standard from the search results' do
                find('.test-matched-standard-label-0').click
              end

              step 'I can click the apply filter button' do
                find('.test-find-content').click
              end

              find(".test-assign-due-date-#{activity_1.id}").click

              wait_for_ajax

              expect(page).to have_selector(".test-individually-assigned-#{activity_1.id}")
            end
          end
          # TODO: Add scenarios for the assessments availability
        end
      end

      context 'with no course' do
        before do
          initialize_program_access_client_calls_for_instructor(
            co_instructor_with_no_course, standards_program
          )
          log_in_as(co_instructor_with_no_course)
        end

        scenario 'I cannot navigate to the Standards-based assigning feature' do
          visit instructor_dashboard_path(standards_program.id)
          find('.test-content-menu', text: 'Assign').click
          find('.test-standards-assign-disabled', text: 'Standards-based Assigning').click
          expect(page).not_to have_selector('.test-standards-assign-search')
        end
      end
    end
  end

  context 'with a program without supported standard sets' do
    context 'with an instructor with assigning abilities' do
      before do
        initialize_program_access_client_calls_for_instructor(
          instructor_owner, non_standards_program
        )
        allow(GradebookEngine::Section)
          .to(receive(:find)).and_return(non_standards_section)
        log_in_as(instructor_owner)
      end

      scenario 'I cannot navigate to the Standards-base assigning feature' do
        visit instructor_standards_assigning_path(non_standards_program.id)
        expect(page).to(have_text('Program must support standards'))
      end
    end
  end
end
