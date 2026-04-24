require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ProgramConfigsController do
  let(:creator) { create(:user) }
  let(:program) { create(:program) }
  let(:first_setting_value) { 'first_url' }
  let(:second_setting_value) { 'second_url' }
  let(:user) { create(:user) }

  describe 'GET /show' do
    before do
      Timecop.travel(1.day.ago) do
        ProgramConfig.create!(
          program_id: program.id,
          creator_id: creator.id,
          vtext: { url: first_setting_value }
        )
      end
      ProgramConfig.create!(
        program_id: program.id,
        creator_id: creator.id,
        vtext: { url: second_setting_value }
      )
    end

    def do_request
      get(program_config_path(program.id))
    end

    include_examples 'require logged in user'

    it 'redirects a user who is not a program config manager' do
      log_in_user(user)
      do_request

      expect(response).to redirect_to '/403'
    end

    it 'displays only the most recent config to a program config manager' do
      user.roles.create!(name: Role::PROGRAM_CONFIG_MANAGER)

      log_in_user(user)
      do_request

      expect(response.body).to include(second_setting_value)
      expect(response.body).not_to include(first_setting_value)
    end
  end

  describe 'GET /edit' do
    def do_request
      get(edit_program_config_path(program.id))
    end

    include_examples 'require logged in user'

    it 'redirects a user who is not a program config manager' do
      log_in_user(user)
      do_request

      expect(response).to redirect_to '/403'
    end

    # Cases for authorized user are covered by feature spec.
  end

  describe 'PUT /update' do
    def do_request(params = {})
      put(
        program_config_path(program.id),
        params: params
      )
    end

    include_examples 'require logged in user'

    it 'redirects a user who is not a program config manager' do
      log_in_user(user)
      do_request

      expect(response).to redirect_to '/403'

      # No ProgramConfig should be created.
      expect(ProgramConfig.count).to eq(0)
    end

    # Cases for authorized user are covered by feature spec.
    context 'when logged in as a user with the correct role,' do
      let(:program_config_manager) do
        create(:user).tap do |user|
          user.roles.create!(name: Role::PROGRAM_CONFIG_MANAGER)
        end
      end

      before do
        log_in_user(program_config_manager)
      end

      it 'creates a new program config' do
        standard_set_1 = create(:standard_set)
        standard_set_2 = create(:standard_set)

        program_config = create(
          :program_config_with_standard_sets,
          supported_standard_sets: [standard_set_1, standard_set_2],
          program:
        )
        program_config.ai_settings = {
          grading_suggestions: true,
          program_level: 'introductory'
        }
        program_config.allow_assessments_randomization = true
        program_config.audio_transcripts = true
        program_config.content_menu_additional_entries = [
          {
            label: 'additional entry 1 label',
            program_id: 1234,
            target_user: 'Instructor',
            url: 'additional entry 1 url',
            description: 'Virtual textbook'
          },
          {
            label: 'additional entry 2 label',
            program_id: 5678,
            target_user: 'Student',
            url: 'additional entry 2 url',
            description: 'Reproducible worksheets'
          }
        ]
        program_config.course_setup_descriptions = {
          express_course: 'express course',
          advanced_course: 'advanced course',
          learning_tracks: {
            header: 'learning tracks header',
            general: 'learning tracks general',
            options_overall: 'learning tracks options overall',
            options: [
              {
                label: 'option 1 label',
                explanation: 'option 1 explanation'
              },
              {
                label: 'option 2 label',
                explanation: 'option 2 explanation'
              },
              {
                label: 'option 3 label',
                explanation: 'option 3 explanation'
              }
            ]
          }
        }
        program_config.ebook = 'Override eBook title for Content Menu'
        program_config.hide_activities = true
        program_config.hide_assessment = true
        program_config.hide_my_content = true
        program_config.hide_translation = true
        program_config.practice_test_analytics_enabled =true
        program_config.pronto = true
        program_config.question_banks_enabled = true
        program_config.settings = [
          {
            label: 'Label 1',
            link: 'some/link/1',
            type: 'link'
          },
          {
            label: 'Label 2',
            link: 'some/link/2',
            type: 'link'
          }
        ]
        program_config.pmr_standard_reports_allowed = true
        program_config.share_to_portfolio = true
        program_config.enable_concurrent_enrollment = true
        program_config.speech_rec = true
        program_config.study_center = true
        program_config.teacher_vtext = {
          url: 'teacher/vtext/url'
        }
        program_config.teacher_vtext_label = 'teacher vtext label'
        program_config.vocab_definition = true
        program_config.vocab_tools = 'vocab tools title'
        program_config.vocab_words = true
        program_config.vtext = {
          type: 'vText or eCompanion',
          url: 'vtext/url/book.html'
        }
        program_config.vtext_label = 'vtext label'

        expect do
          do_request(datastore: program_config.datastore,
                     vocab_tools_enabled: true,
                     previous_edition_program_id: Program.first.id,
                     next_edition_program_id: Program.last.id)
        end.to change(ProgramConfig, :count).by(1).and change(ProgramEdition, :count).by(1)

        expect(response).to be_ok
        expect(response).to render_template('program_configs/edit')
        expect(flash[:notice]).to include('New configuration created.')

        program_config = ProgramConfig.last
        expect(program_config).to have_attributes(
          ai_settings: {
            grading_suggestions: true,
            program_level: 'introductory'
          },
          allow_assessments_randomization: true,
          audio_transcripts: true,
          content_menu_additional_entries: [
            an_object_having_attributes(
              label: 'additional entry 1 label',
              program_id: '1234',
              target_user: 'Instructor',
              url: 'additional entry 1 url',
              description: 'Virtual textbook'
            ),
            an_object_having_attributes(
              label: 'additional entry 2 label',
              program_id: '5678',
              target_user: 'Student',
              url: 'additional entry 2 url',
              description: 'Reproducible worksheets'
            )
          ],
          course_setup_descriptions: an_object_having_attributes(
            express_course: 'express course',
            advanced_course: 'advanced course',
            learning_tracks: an_object_having_attributes(
              header: 'learning tracks header',
              general: 'learning tracks general',
              options_overall: 'learning tracks options overall',
              options: [
                an_object_having_attributes(
                  label: 'option 1 label',
                  explanation: 'option 1 explanation'
                ),
                an_object_having_attributes(
                  label: 'option 2 label',
                  explanation: 'option 2 explanation'
                ),
                an_object_having_attributes(
                  label: 'option 3 label',
                  explanation: 'option 3 explanation'
                )
              ]
            )
          ),
          ebook: 'Override eBook title for Content Menu',
          hide_activities: true,
          hide_assessment: true,
          hide_my_content: true,
          hide_translation: true,
          practice_test_analytics_enabled: true,
          pronto: true,
          question_banks_enabled: true,
          settings: [
            an_object_having_attributes(
              label: 'Label 1',
              link: 'some/link/1',
              type: 'link'
            ),
            an_object_having_attributes(
              label: 'Label 2',
              link: 'some/link/2',
              type: 'link'
            )
          ],
          share_to_portfolio: true,
          pmr_standard_reports_allowed: true,
          enable_concurrent_enrollment: true,
          speech_rec: true,
          standards_settings: {
            supported_standard_set_ids: [
              standard_set_1.id,
              standard_set_2.id
            ],
            min_grade: 'K',
            max_grade: '12'
          },
          study_center: true,
          teacher_vtext: an_object_having_attributes(
            url: 'teacher/vtext/url'
          ),
          teacher_vtext_label: 'teacher vtext label',
          vocab_definition: true,
          vocab_tools: 'vocab tools title',
          vocab_words: true,
          vtext: an_object_having_attributes(
            type: 'vText or eCompanion',
            url: 'vtext/url/book.html'
          ),
          vtext_label: 'vtext label'
        )
      end
    end
  end

  describe 'GET /update_vocab_tools' do
    def do_request
      get(program_update_vocab_tools_path(program.id))
    end

    include_examples 'require logged in user'

    it 'redirects a user who is not a program config manager' do
      log_in_user(user)
      do_request

      expect(response).to redirect_to '/403'
    end

    # Cases for authorized user are covered by feature spec.
  end
end
