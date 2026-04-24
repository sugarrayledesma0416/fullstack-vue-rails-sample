feature 'Inactivity Timeout', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:school_1) { create(:school, name: 'VHL School 1') }
  let(:school_2) { create(:school, name: 'VHL School 2') }
  let(:instructor) { create(:instructor, schools: [school_1, school_2]) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course_1) { create(:course, program:, school: school_1) }
  let(:section_1) { create(:section, course: course_1) }
  let(:course_2) { create(:course, program:, school: school_2) }
  let(:section_2) { create(:section, course: course_2) }

  let!(:school_config) do
    create(:school_config, school: school_1, timeout_enabled: true, instructor_timeout: 8)
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  def expect_timeout_dialog_warning
    expect(page).to have_selector(
      '.test-timeout-warning',
      text: 'Please confirm you are still there. If not, you will be logged out in a minute.'
    )
  end

  describe 'As an instructor' do
    scenario 'when user`s current school has timeout enabled' do
      step 'Go to instructor dashboard' do
        allow(Section).to receive(:section_zero).and_return(section_1)
        visit instructor_dashboard_path(program.id)
      end

      step 'I can see a a timeout dialog on inactivity' do
        sleep 3
        expect_timeout_dialog_warning
      end

      purpose 'I can stay on page on clicking "I`m here"' do
        step 'Click I`m here' do
          find('.test-confirm-timeout-btn').click
        end

        step 'I cannot see the warning dialog' do
          expect(page).to have_no_selector('.test-timeout-warning', visible: :visible)
        end

        step 'I am on the instructor dashboard page' do
          expect(page).to have_current_path(instructor_dashboard_path(program))
        end
      end

      purpose 'I can get logout on clicking "Sign Out"' do
        step 'I can see a a timeout dialog on inactivity' do
          sleep 3
          expect_timeout_dialog_warning
        end

        step 'Click on Sign Out' do
          find('.test-cancel-timeout-btn').click
        end

        step 'I am on the UA url' do
          expect(page.current_url).to be_start_with(UA_URL)
        end
      end
    end

    scenario 'when user`s current school has timeout disabled' do
      create(:school_config, school: school_2, timeout_enabled: false, instructor_timeout: 8)

      purpose 'I can not see a a timeout dialog on inactivity' do
        step 'Go to instructor dashboard' do
          allow(Section).to receive(:section_zero).and_return(section_2)
          visit instructor_dashboard_path(program.id)
        end

        step 'Select "School 2" from school dropdown' do
          select('VHL School 2', from: 'student_dropdown_menu').select_option
        end

        step "I don't see a timeout dialog on inactivity" do
          sleep 3
          expect(page).to have_no_selector('.test-timeout-warning', visible: :visible)
        end
      end
    end

    scenario 'when user`s current school has no timeout configuration' do
      purpose 'I can not see a a timeout dialog on inactivity' do
        step 'Go to instructor dashboard' do
          allow(Section).to receive(:section_zero).and_return(section_2)
          visit instructor_dashboard_path(program.id)
        end

        step 'Select "School 2" from school dropdown' do
          select('VHL School 2', from: 'student_dropdown_menu').select_option
        end

        step "I don't see a timeout dialog on inactivity" do
          sleep 3
          expect(page).to have_no_selector('.test-timeout-warning', visible: :visible)
        end
      end
    end
  end
end
