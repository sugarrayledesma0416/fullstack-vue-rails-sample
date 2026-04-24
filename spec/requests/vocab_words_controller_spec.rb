require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe VocabWordsController, type: :request do
  let(:unexpired_vocab_license) do
    Maestro::UserLicense.new(
      'demo' => false,
      'expiration_date' => 1.year.from_now.to_date.to_s,
      'grace_period' => false,
      'license_group' => {
        'demo' => false,
        'id' => 2,
        'includes_content' => false,
        'm2_only' => false,
        'name' => 'My Vocabulary',
        'site_function_name' => 'my_vocabulary',
      }
    )
  end

  let(:section) { create(:section) }
  let(:current_user) { create(:student) }
  let(:vocab_program_group) { VocabProgramGroup.create }
  let(:current_program) do
    create(
      :program,
      language_code: 'es',
      vocab_program_group_id: vocab_program_group.id
    )
  end

  let(:original_attrs) do
    {
      base_word: 'original base',
      lesson_id: create(:lesson).id,
      target_definition: 'original definition',
      target_word: 'original target'
    }
  end

  def grant_vocab_license_access
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
      .and_return([create_unexpired_user_license, unexpired_vocab_license])
    allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
      .and_return(
        Maestro::LicensedContent.new(
          'license_group_ids' => [2], 'lessons' => '*'
        )
      )
  end

  describe 'POST /create' do
    let(:create_params) do
      { vocab_word: original_attrs }.merge(format: :json)
    end
    let(:target_path) { vocab_words_path(program_id: current_program.id, section_id: section.id) }

    def do_request
      post(target_path, params: create_params)
    end

    include_examples 'require logged in user', :json

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(current_user, [current_program])
        grant_vocab_license_access
      end

      it 'requires a root key :vocab_word in the params' do
        expect { post(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: vocab_word/
        )
      end

      it 'creates a new vocab word record' do
        do_request

        expect(response).to be_created

        new_word = VocabWord.last
        expect(new_word).to have_attributes(original_attrs)
        expect(new_word).to have_attributes(
          program_id: current_program.id,
          user_id: current_user.id
        )
      end

      it 'sends an error message when input is invalid' do
        post(
          target_path,
          params: create_params.merge(vocab_word: { lesson_id: 1 })
        )

        expect(response).to be_unprocessable
        expect(JSON.parse(response.body)['errors']).to include(
          'Target word, base word, or definition must be entered.'
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:vocab_word) do
      create(
        :vocab_word,
        original_attrs.merge(
          program_id: current_program.id,
          user_id: current_user.id
        )
      )
    end
    let(:new_attrs) do
      {
        base_word: 'new base',
        lesson_id: create(:lesson).id,
        target_definition: 'new definition',
        target_word: 'new target'
      }
    end

    let(:update_params) do
      { vocab_word: { id: vocab_word.id }.merge(new_attrs) }.merge(format: :json)
    end

    let(:target_path) do
      vocab_word_path(
        id: vocab_word.id,
        program_id: current_program.id,
        section_id: section.id
      )
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require logged in user', :json

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(current_user, [current_program])
        grant_vocab_license_access
      end

      it 'requires a root key :vocab_word in the params' do
        expect { put(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: vocab_word/
        )
      end

      it 'updates an existing vocab word record' do
        do_request

        expect(response).to be_created

        updated_word = VocabWord.find(vocab_word.id)
        expect(updated_word).to have_attributes(new_attrs)
        expect(updated_word).to have_attributes(
          program_id: current_program.id,
          user_id: current_user.id
        )
      end

      it 'sends an error message when input is invalid' do
        invalid_params = {
          vocab_word: {
            base_word: nil,
            id: vocab_word.id,
            target_definition: nil,
            target_word: nil
          },
          format: :json
        }
        put(target_path, params: invalid_params)

        expect(response).to be_unprocessable
        expect(JSON.parse(response.body)['errors']).to include(
          'Target word, base word, or definition must be entered.'
        )
      end
    end
  end
end
