feature 'AI Virtual chat activity', js: true, new_gb_sync: true, skip: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include ActivityTest::Helpers
  include WaitForAjax

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:activity) { create_ai_virtual_chat_activity(program) }
  let(:fake_submissions) { {} }
  let(:azure_endpoint) do
    "https://#{AI::AzureClient::REGION}.#{AI::AzureClient::HOST}#{AI::AzureClient::SCOPED_TOKEN_URL}"
  end
  let(:initial_prompt) { activity.content_object.question.initial_prompt }
  let(:activity_data) do
    ActivityTest::ActivityData::AiVirtualChat.new(activity)
  end
  let(:partner_response_1) { 'Partner response 1' }
  let(:partner_response_2) { 'Partner response 2' }
  let(:student_message_1) { 'Student message 1' }
  let(:student_message_2) { 'Student message 2' }

  def create_ai_virtual_chat_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'ai_virtual_chat_with_references.xml'),
      program,
      grading_method: 'instructor',
      max_attempts: 1
    )
  end

  def stub_lossless
    stub_request(
      :get,
      /#{Rails.application.config.lossless_base_url}.*/
    ).to_return(
      status: 200,
      body: { token: '1234-5678' }.to_json
    )
    stub_request(
      :post,
      "#{Rails.application.config.lossless_base_url}/m3/delete_virtual_chat_recordings"
    ).to_return(
      status: 200,
      body: {}.to_json
    )
  end

  def success_ai_response(partner_response:, status: nil)
    {
      status: 200,
      body: {
        choices: [
          message: {
            content: {
              on_topic: true,
              partner_response:,
              expected_response_count: 2
            }.to_json
          }
        ]
      }.to_json
    }
  end

  def stub_open_ai
    stub_request(
      :post,
      'https://api.openai.com/v1/chat/completions'
    ).to_return(
      success_ai_response(partner_response: partner_response_1),
      # The spec will restart the activity between these 2 calls.
      success_ai_response(partner_response: partner_response_1),
      success_ai_response(
        partner_response: partner_response_2
      )
    )
  end

  def stub_azure_token
    stub_request(:post, azure_endpoint).and_return(
      body: 'fake token',
      status: 200
    )
  end

  context 'as a student,' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      create(:active_enrollment, section:, user: student)
      stub_lossless
      stub_open_ai
      stub_azure_token
      log_in_as(student)
    end
    
    scenario 'I can complete the activity' do
      pending 'This test is failing due to timing issues, will need to be refactored significantly to fix.'
      visit section_activity_path(section.id, activity)

      for_preview_page(activity_data) do |pobject|
        expect_activity_shell_structure_to_be_complete

        pobject.from_ai_virtual_chat_app do |app|
          purpose 'I can change settings' do
            app.for_settings_area do |settings_area|
              expect(settings_area).to have_no_play_all_button

              expect(settings_area.auto_play_audio).to be(true)
              settings_area.auto_play_audio = false
            end
          end

          purpose 'I test my connection' do
            app.for_settings_area do |settings_area|
              settings_area.test_connection_button.click
            end

            app.pretest_modal.continue
          end

          purpose 'I start the activity' do
            app.start_activity
            app.switch_to_text

            step 'I see the initial message' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt
                ]
              )
            end

            step 'I submit a message' do
              app.for_pane_footer do |pane_footer|
                pane_footer.send_message(student_message_1)
              end
            end

            step 'I see my message' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1
                ]
              )
            end

            wait_for_ajax

            step 'I see partner response' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1,
                  partner_response_1
                ]
              )
            end

            step 'My messages are saved in the database' do
              expect(AI::ConversationSession.last.messages).to contain_exactly(
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: initial_prompt
                ),
                an_object_having_attributes(
                  role: 'user',
                  message_text: student_message_1
                ),
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: partner_response_1
                )
              )
            end
          end

          purpose "I can't submit if I do not have enough responses" do
            expect(pobject.button(:submit)).to be_disabled
          end

          purpose 'I restart the activity' do
            app.restart_activity
            app.restart_activity_modal.cancel
            app.restart_activity
            app.restart_activity_modal.restart
            wait_for_ajax

            step 'I only see the initial message' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt
                ]
              )
            end

            step 'My messages are deleted from the database' do
              expect(AI::ConversationSession.last.messages).to contain_exactly(
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: initial_prompt
                )
              )
            end

            step 'I submit a message' do
              app.for_pane_footer do |pane_footer|
                pane_footer.send_message(student_message_1)
              end
            end

            step 'I see my message' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1
                ]
              )
            end

            step 'I see partner response' do
              wait_for_ajax
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1,
                  partner_response_1
                ]
              )
            end

            step 'My messages are saved in the database' do
              expect(AI::ConversationSession.last.messages).to contain_exactly(
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: initial_prompt
                ),
                an_object_having_attributes(
                  role: 'user',
                  message_text: student_message_1
                ),
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: partner_response_1
                )
              )
            end
          end

          purpose "I can't submit the AI says I haven't completed the activity" do
            expect(pobject.button(:submit)).to be_disabled
          end

          purpose 'I can submit if the AI says I have completed the activity' do
            step 'I submit a message' do
              app.for_pane_footer do |pane_footer|
                pane_footer.send_message(student_message_2)
              end
            end

            step 'I see my message' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1,
                  partner_response_1,
                  student_message_2
                ]
              )
            end

            step 'I see partner response' do
              wait_for_ajax
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1,
                  partner_response_1,
                  student_message_2,
                  partner_response_2
                ]
              )
            end

            step 'My messages are saved in the database' do
              expect(AI::ConversationSession.last.messages).to contain_exactly(
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: initial_prompt
                ),
                an_object_having_attributes(
                  role: 'user',
                  message_text: student_message_1
                ),
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: partner_response_1
                ),
                an_object_having_attributes(
                  role: 'user',
                  message_text: student_message_2
                ),
                an_object_having_attributes(
                  role: 'assistant',
                  message_text: partner_response_2
                )
              )
            end

            step 'The submit button is enabled' do
              expect(pobject.button(:submit)).not_to be_disabled
            end
          end

          purpose 'I submit the activity' do
            click_button('Submit')
          end
        end
      end

      expect_flash_message(:notice, 'Activity complete.')

      for_accept_page(activity_data) do |pobject|
        expect_activity_shell_structure_to_be_complete

        purpose 'I see a ready only version of the activity' do
          pobject.from_ai_virtual_chat_app do |app|
            app.for_settings_area do |settings_area|
              expect(settings_area).to have_no_test_connection_button
              expect(settings_area).to have_no_auto_play_audio_checkbox
            end

            step 'I can play all the audio files' do
              app.for_settings_area do |settings_area|
                settings_area.play_all_button.click
              end
            end

            step "I can't submit messages nor record audio" do
              app.for_pane_footer do |pane_footer|
                expect(pane_footer).to have_no_record_button
                expect(pane_footer).to have_no_message_input_field
                expect(pane_footer).to have_no_send_button
              end
            end

            step 'I see all the messages' do
              expect(app.chat_messages).to eq(
                [
                  initial_prompt,
                  student_message_1,
                  partner_response_1,
                  student_message_2,
                  partner_response_2
                ]
              )
            end
          end
        end
      end
    end
  end
end
