require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe VocabTools::UserDefinedWordsController do
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.units.first.lessons.first }
  let(:section) { create(:section) }

  let(:original_attrs) do
    {
      definition: 'original definition',
      lesson_id: lesson.id,
      pinyin: 'original pinyin',
      target: 'original target',
      translation: 'original translation'
    }
  end

  describe 'POST /create' do
    let(:target_path) do
      vocab_tools_user_defined_words_path(program_id: program.id, section_id: section.id)
    end

    def do_request
      post(target_path, params: original_attrs)
    end

    include_examples 'require logged in user'

    context 'with a valid user,' do
      before { log_in_user_with_access_to_programs(student, [program]) }

      it 'creates a new user-defined word record when valid params are specified' do
        do_request

        expect(response).to be_ok

        # Verify that posted params were permitted and saved.
        user_defined_word = UserDefinedWord.last
        expect(user_defined_word).to have_attributes(original_attrs)

        # Verify non-posted attributes were set in the controller action.
        expect(user_defined_word).to have_attributes(
          program_id: program.id,
          user_id: student.id
        )

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          original_attrs.merge(
            id: user_defined_word.id,
            lesson_id: lesson.id,
            topic: 'My Words'
          )
        )
      end

      it 'does not create a user-defined word record when invalid params ' \
         'are specified' do
        expect do
          post(target_path, params: original_attrs.merge(target: ''))
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Foreign word is required'
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:user_defined_word) do
      create(
        :user_defined_word,
        original_attrs.merge(program_id: program.id, user_id: student.id)
      )
    end

    let(:target_path) do
      vocab_tools_user_defined_word_path(
        id: user_defined_word.id,
        program_id: program.id,
        section_id: section.id
      )
    end

    let(:new_attrs) do
      {
        pinyin: 'new pinyin',
        target: 'new target',
        translation: 'new translation'
      }
    end

    def do_request
      put(target_path, params: new_attrs)
    end

    include_examples 'require logged in user'

    context 'with a valid user,' do
      before { log_in_user_with_access_to_programs(student, [program]) }

      it 'updates the user-defined word with the specified id when valid ' \
         'params are specified' do
        do_request

        expect(response).to be_ok

        user_defined_word.reload

        expect(user_defined_word).to have_attributes(new_attrs)
      end

      it 'does not update the specified user-defined word record when invalid ' \
         'params are specified' do
        put(target_path, params: new_attrs.merge(target: ''))

        expect(response).to be_unprocessable

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          definition: 'original definition',
          id: user_defined_word.id,
          lesson_id: lesson.id,
          pinyin: 'new pinyin',
          target: '',
          topic: 'My Words',
          translation: 'new translation'
        )
      end
    end
  end

  describe 'DELETE /destroy' do
    let(:user_defined_word) do
      create(
        :user_defined_word,
        original_attrs.merge(program_id: program.id, user_id: student.id)
      )
    end

    let(:target_path) do
      vocab_tools_user_defined_word_path(
        id: user_defined_word.id,
        program_id: program.id,
        section_id: section.id
      )
    end

    def do_request
      delete(target_path)
    end

    include_examples 'require logged in user'

    context 'with a valid user,' do
      before { log_in_user_with_access_to_programs(student, [program]) }

      it 'deletes the specified user-defined word when the logged-in user ' \
         'created that word' do
        do_request

        expect(response).to be_ok
        expect(UserDefinedWord.where(id: user_defined_word.id)).not_to exist
      end

      it 'does not delete the specified user-defined word when the ' \
         'logged-in user did not create that word' do
        user_defined_word.update!(user: create(:student))

        do_request

        expect(response).to be_ok
        expect(UserDefinedWord.where(id: user_defined_word.id)).to exist
      end
    end
  end
end
