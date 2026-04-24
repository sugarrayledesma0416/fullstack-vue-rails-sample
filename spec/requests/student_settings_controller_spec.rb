require 'requests/login_helper_methods'

describe StudentSettingsController do
  describe '#update_section_defaults' do
    let(:instructor) { create(:instructor) }
    let(:student) { create(:student) }
    let(:course) { create(:course, owner: instructor, program:) }
    let(:section) { create(:section, course:, instructor:) }
    let(:program) { create(:program) }

    let(:valid_params) do
      {
        audio_transcript: true,
        video_subtitle_languages: 'foreign_and_english',
        video_transcript_languages: 'foreign_and_english',
        input_mode: 'text'
      }
    end

    before do
      create(:enrollment, user: student, section:)
      log_in_user_with_access_to_programs(instructor, [program])
    end

    context 'with valid params' do
      it 'returns success response with student data' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to be_successful
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be true
        expect(response_json['message']).to eq('Default settings updated successfully.')
        expect(response_json['students']).to be_an(Array)
        expect(response_json['students'].first).to include(
          'id' => student.id,
          'firstName' => student.first_name,
          'lastName' => student.last_name,
          'audio_transcript' => true,
          'video_subtitle_languages' => 'foreign_and_english',
          'video_transcript_languages' => 'foreign_and_english',
          'input_mode' => 'text'
        )
      end
    end

    context 'with invalid params' do
      it 'validates audio_transcript boolean' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(audio_transcript: 'not_a_boolean').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for audio transcripts.')
      end

      it 'validates input_mode' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(input_mode: 'invalid_mode').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for input mode.')
      end

      it 'accepts all valid input_mode values' do
        valid_modes = ['speech', 'text', 'speech-and-text', 'text-no-audio']

        valid_modes.each do |mode|
          post(
            section_student_settings_update_section_defaults_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.merge(input_mode: mode).to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to be_successful
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be true
        end
      end

      it 'handles empty input_mode gracefully' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.except(:input_mode).to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to be_successful
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be true
      end

      it 'validates apply_to_all boolean' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(apply_to_all: 'not_a_boolean').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for applying to all students.')
      end

      it 'validates video_subtitle_languages' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(video_subtitle_languages: 'invalid').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for video subtitles.')
      end

      it 'validates video_transcript_languages' do
        post(
          section_student_settings_update_section_defaults_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(video_transcript_languages: 'invalid').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for video transcripts.')
      end
    end

    context 'when an internal server error occurs' do
      context 'when record is invalid' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_section_defaults)
            .and_raise(ActiveRecord::RecordInvalid.new(section))
        end

        it 'returns error response' do
          post(
            section_student_settings_update_section_defaults_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end

      context 'when database statement is invalid' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_section_defaults)
            .and_raise(ActiveRecord::StatementInvalid.new('Database error'))
        end

        it 'returns error response' do
          post(
            section_student_settings_update_section_defaults_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end

      context 'when record is not found' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_section_defaults)
            .and_raise(ActiveRecord::RecordNotFound.new('Record not found'))
        end

        it 'returns error response' do
          post(
            section_student_settings_update_section_defaults_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end
    end
  end

  describe '#update_students' do
    let(:instructor) { create(:instructor) }
    let(:student1) { create(:student) }
    let(:student2) { create(:student) }
    let(:student3) { create(:student) }
    let(:course) { create(:course, owner: instructor, program:) }
    let(:section) { create(:section, course:, instructor:) }
    let(:program) { create(:program) }

    let(:valid_params) do
      {
        user_ids: [student1.id, student2.id, student3.id],
        audio_transcript: true,
        video_subtitle_languages: 'foreign_and_english',
        video_transcript_languages: 'foreign_and_english',
        input_mode: 'text'
      }
    end

    before do
      create(:enrollment, user: student1, section:)
      create(:enrollment, user: student2, section:)
      create(:enrollment, user: student3, section:)
      log_in_user_with_access_to_programs(instructor, [program])
    end

    context 'with valid params' do
      it 'returns success response with config' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to be_successful
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be true
        expect(response_json['config']).to include(
          'audio_transcript' => true,
          'video_subtitle_languages' => 'foreign_and_english',
          'video_transcript_languages' => 'foreign_and_english',
          'input_mode' => 'text'
        )
      end
    end

    context 'with invalid params' do
      it 'requires user_ids' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.except(:user_ids).to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please provide all required information to update settings.')
      end

      it 'validates user_ids is an array' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(user_ids: 'not_an_array').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please provide an array of user IDs.')
      end

      it 'validates audio_transcript boolean' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(audio_transcript: 'not_a_boolean').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for audio transcripts.')
      end

      it 'validates video_subtitle_languages' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(video_subtitle_languages: 'invalid').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for video subtitles.')
      end

      it 'validates video_transcript_languages' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(video_transcript_languages: 'invalid').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for video transcripts.')
      end

      it 'validates input_mode' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.merge(input_mode: 'invalid_mode').to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )
        expect(response).to have_http_status(:bad_request)
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be false
        expect(response_json['error']).to eq('Please select a valid option for input mode.')
      end

      it 'accepts all valid input_mode values' do
        valid_modes = ['speech', 'text', 'speech-and-text', 'text-no-audio']

        valid_modes.each do |mode|
          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.merge(input_mode: mode).to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to be_successful
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be true
        end
      end

      it 'handles empty input_mode gracefully' do
        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: valid_params.except(:input_mode).to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to be_successful
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be true
      end
    end

    context 'when an internal server error occurs' do
      context 'when record is invalid' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_students)
            .and_raise(ActiveRecord::RecordInvalid.new(StudentSectionConfig.new))
        end

        it 'returns error response' do
          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end

      context 'when database statement is invalid' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_students)
            .and_raise(ActiveRecord::StatementInvalid.new('Database error'))
        end

        it 'returns error response' do
          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end

      context 'when database record is not found during operation' do
        before do
          allow_any_instance_of(SectionStudentSettings).to receive(:update_students)
            .and_raise(ActiveRecord::RecordNotFound.new('Record not found'))
        end

        it 'returns internal server error' do
          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: valid_params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:internal_server_error)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We encountered an issue while saving your changes. Please try again.')
        end
      end
    end

    context 'when student validation fails' do
      context 'when student is not enrolled in section' do
        let(:unenrolled_student) { create(:student) }

        it 'returns not found error' do
          params = valid_params.merge(user_ids: [unenrolled_student.id])

          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:not_found)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('One or more students may not be enrolled in this section.')
        end
      end

      context 'when some students are not enrolled' do
        let(:student4) { create(:student) }
        let(:student5) { create(:student) }

        before do
          create(:enrollment, user: student4, section:)
          # student5 is not enrolled
        end

        it 'returns not found error when some students are not enrolled' do
          params = valid_params.merge(user_ids: [student1.id, student2.id, student4.id,
                                                 student5.id])

          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:not_found)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('One or more students may not be enrolled in this section.')
        end
      end

      context 'when some user_ids do not exist' do
        it 'returns not found error when student count does not match' do
          params = valid_params.merge(user_ids: [student1.id, student2.id, 999_999])

          post(
            section_student_settings_update_students_path(
              program_id: program.id,
              section_id: section.id
            ),
            params: params.to_json,
            headers: { 'CONTENT_TYPE' => 'application/json' }
          )

          expect(response).to have_http_status(:not_found)
          response_json = JSON.parse(response.body)
          expect(response_json['success']).to be false
          expect(response_json['error']).to eq('We couldn\'t find one or more students.')
        end
      end
    end

    context 'when user_ids are strings' do
      it 'handles string user_ids correctly' do
        params = valid_params.merge(user_ids: [student1.id.to_s, student2.id.to_s,
                                               student3.id.to_s])

        post(
          section_student_settings_update_students_path(
            program_id: program.id,
            section_id: section.id
          ),
          params: params.to_json,
          headers: { 'CONTENT_TYPE' => 'application/json' }
        )

        expect(response).to be_successful
        response_json = JSON.parse(response.body)
        expect(response_json['success']).to be true
      end
    end
  end
end
