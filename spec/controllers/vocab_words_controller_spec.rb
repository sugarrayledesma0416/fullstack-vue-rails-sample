describe VocabWordsController do
  let(:current_user) { create(:student) }
  let(:current_program) { create(:program, language_code: 'es') }
  let(:unit) { create(:unit, program: current_program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:access_guardian) do
    instance_double(
      AccessGuardian,
      has_vocab_words?: true,
      has_mobile_app?: false
    )
  end

  before do
    fake_login(current_user)
    allow(@controller).to receive(:current_program).and_return(current_program)
    allow(@controller).to receive(:access_guardian).and_return(access_guardian)
  end

  context 'when the current user does not have access to My Vocabulary' do
    before do
      stub_request(
        :get, %r{users/.*/programs}
      ).to_return(status: 200, body: '', headers: {})
      allow(access_guardian).to receive(:has_vocab_words?).and_return(false)
    end

    it 'sets the flash', test_debt: true do
      get :index, params: { program_id: 1 }
      expect(flash[:error]).to eq('You do not have access to My Vocabulary.')
    end

    it 'redirects to the best default path' do
      expect(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')
      get :index, params: { program_id: current_program.id }
      expect(response).to redirect_to('/best_default_path')
    end
  end

  describe '#index' do
    it 'call serialize_to_json_for_student_and_language with right params' do
      allow(VocabWord).to receive(:find_or_build_vocab_words).with(current_user, current_program)
      expect(VocabWord).to receive(:serialize_to_json_for_student_and_language).with(current_user, current_program)
      get :index, params: { program_id: current_program.id, format: 'json' }, xhr: true
    end

    it 'sets the menu location' do
      get :index, params: { program_id: current_program.id }
      expect(assigns[:menu_location]).to eql level_1: 'teaching'
    end

    it 'returns a list of vocab words for a user and language' do
      vocab_word = VocabWord.create!(
        base_word: 'bar',
        language: 'es',
        lesson: lesson,
        student: current_user,
        target_definition: 'qux',
        target_word: 'foo'
      )
      expected = {
        'activities' => [vocab_word].to_json(include: :vocab_tags),
        'language' => current_program.language_code,
        'lessons' => []
      }.to_json

      expect(VocabWord).to receive(
        :serialize_to_json_for_student_and_language
      ).with(current_user, current_program).and_return(expected)

      # I'm not sure why, but we have to specify format 'json' -- but only in this spec.
      get :index, params: { program_id: current_program.id, format: 'json' }, xhr: true

      expect(response.body).to eq(expected)
      expect(response.code).to eq('200')
    end
  end

  describe '#index_popup' do
    it 'returns a list of vocab words for a user' do
      vocab_word = VocabWord.create!(
        base_word: 'bar',
        language: 'es',
        lesson: lesson,
        student: current_user,
        target_definition: 'qux',
        target_word: 'foo'
      )

      get :index_popup, params: { program_id: current_program.id }, xhr: true
      expect(response).to render_template('index')
      expect(response.code).to eq('200')
    end
  end

  describe '#destroy' do
    before do
      @vocab_word = current_user.vocab_words.create!(
        base_word: 'bar',
        language: 'es',
        lesson: lesson,
        target_word: 'foo'
      )
    end

    it 'deletes the vocab word' do
      deleter = double('VocabWordDeleter')
      expect(deleter).to receive(:delete_vocab_word)
      expect(VocabWordDeleter).to receive(:new).with(current_user, anything).and_return(deleter)
      delete :destroy, xhr: true, params: {
        program_id: current_program.id, id: @vocab_word.id
      }
      expect(response.code).to eq('204')
    end
  end

  describe '#print_pdf' do
    it 'returns a pdf as the reponse' do
      post :print_pdf,
           params: {
             format: 'pdf',
             program_id: 48,
             study_sheet_type: 'spanish_english'
           }
      expect(response.content_type).to eq('application/pdf')
    end

    it 'finds vocab words and default vocab words that were sent in the params' do
      expect(VocabWord).to receive(:find).with(%w{1 2 3})
      expect(DefaultVocabWord).to receive(:find).with(%w{4 5 6})
      post :print_pdf,
           params: {
             default_vocab_word_ids: [4, 5, 6],
             program_id: 48,
             study_sheet_type: 'spanish_english',
             vocab_word_ids: [1, 2, 3]
           }
    end
  end
end
