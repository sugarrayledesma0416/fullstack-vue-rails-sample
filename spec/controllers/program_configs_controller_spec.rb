describe ProgramConfigsController do
  describe '#update' do
    let(:user) { create(:program_config_manager) }
    let(:program) { create(:program) }
    let(:program_config) { create(:program_config, program:) }
    let(:params) { {} }
    let(:datastore) do
      {
        datastore: {
          allow_assessments_randomization: nil,
          audio_transcripts: nil,
          ebook: nil,
          hide_activities: nil,
          hide_assessment: nil,
          hide_my_content: nil,
          hide_translation: nil,
          practice_test_analytics_enabled: nil,
          pronto: nil,
          question_banks_enabled: nil,
          share_to_portfolio: nil,
          enable_concurrent_enrollment: nil,
          speech_rec: nil,
          study_center: nil,
          teacher_vtext_label: nil,
          vocab_definition: nil,
          vocab_tools: nil,
          vocab_words: nil,
          vtext_label: nil,
          ai_settings: {
            grading_suggestions: nil,
            program_level: nil
          },
          content_menu_additional_entries: {
            label: nil,
            program_id: nil,
            target_user: nil,
            url: nil,
            description: nil
          },
          course_setup_descriptions: {
            express_course: nil,
            advanced_course: nil,
            learning_tracks: {
              header: nil,
              general: nil,
              options_overall: nil,
              options: { label: nil, explanation: nil}
            }
          },
          settings: { label: nil, link: nil, type: nil },
          standards_settings: {
            min_grade: nil,
            max_grade: nil,
            supported_standard_set_ids: {}
          },
          teacher_vtext: { url: nil },
          vtext: { type: nil, url: nil }
        }
      }
    end

    def do_request
      post :update, params: {
        program_id: program.id.to_s,
        datastore:
      }.merge(params)
    end

    before do
      fake_login(user)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      allow(Program).to receive(:find).and_return(program)
      create(:concept, program:, id: 1)
      create(:concept, program:, id: 2)
    end

    context 'when the program config is not changed' do
      let(:params) do
        {
          ptp_mapping: [
            { 'src_strand_id' => 1, 'dest_strand_id' => 2, program_id: program.id },
          ],
          next_edition_program_id: next_edition_program.id
        }
      end
      let(:next_edition_program) { create(:program) }

      it 'saves the program to program mappings' do
        do_request
        expect(ProgramToProgramMapping.count).to eq(1)
      end

      it 'saves the program edition changes' do
        do_request
        expect(ProgramEdition.count).to eq(1)
      end
    end

    context 'when the program editions are not changed' do
      let(:params) do
        {
          ptp_mapping: [
            { 'src_strand_id' => 1, 'dest_strand_id' => 2, program_id: program.id },
          ],
          datastore: { hide_activities: true }
        }
      end

      it 'saves the program to program mappings' do
        do_request
        expect(ProgramToProgramMapping.where(dest_program_id: program.id).count).to eq(1)
      end

      it 'saves the program config' do
        do_request
        expect(ProgramConfig.currently_active(program)).to be_present
      end
    end

    context 'when the program to program mappings are not changed' do
      let(:params) do
        {
          next_edition_program_id: next_edition_program.id,
          datastore: { hide_activities: true }
        }
      end
      let(:next_edition_program) { create(:program) }

      it 'saves the program edition changes' do
        do_request
        expect(ProgramEdition.where(program_id: program.id).count).to eq(1)
      end

      it 'saves the program config' do
        do_request
        expect(ProgramConfig.currently_active(program)).to be_present
      end
    end
  end
end
