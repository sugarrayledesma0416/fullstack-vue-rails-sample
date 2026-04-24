feature 'Vocabulary words access' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:my_vocab_function) { double('SiteFunction') }
  let(:instructor) { create(:instructor) }

  # vocab groups
  let(:vocab_group) { VocabProgramGroup.create! }
  let(:other_vocab_group) { VocabProgramGroup.create! }

  # programs
  let(:program) { create(:program, vocab_program_group_id: vocab_group.id) }
  let(:program_without_access) do
    create(:program, vocab_program_group_id: vocab_group.id)
  end
  let(:program_in_other_program_group) do
    create(:program, vocab_program_group_id: other_vocab_group.id)
  end

  # lessons
  let(:unit) { create(:unit, program: program, lessons: []) }
  let(:unit_program_with_no_access) do
    create(:unit, program: program_without_access, lessons: [])
  end
  let!(:valid_lesson_1) { create(:lesson, unit: unit, rank: 1) }
  let!(:valid_lesson_2) { create(:lesson, unit: unit, rank: 2) }

  # default_vocab_words and vocab_words
  let!(:default_word_in_current_program_group) do
    create(
      :default_vocab_word,
      base_word: 'phone',
      target_word: 'telefono',
      vocab_program_group_id: vocab_group.id,
      program_id: program.id
    )
  end

  let!(:default_word_in_other_program_group) do
    create(
      :default_vocab_word,
      base_word: 'river',
      target_word: 'rio',
      vocab_program_group_id: other_vocab_group,
      program_id: program_in_other_program_group.id
    )
  end

  let!(:default_word_in_program_without_access) do
    create(
      :default_vocab_word,
      base_word: 'cat',
      program_id: program_without_access.id,
      target_word: 'gato',
      vocab_program_group_id: vocab_group.id
    )
  end

  let!(:word_for_other_language_with_no_program) do
    create(
      :vocab_word,
      base_word: 'say',
      language: 'de',
      student: instructor,
      target_word: 'decir',
      vocab_program_group_id: vocab_group.id
    )
  end

  let!(:word_for_another_user) do
    create(
      :vocab_word,
      base_word: 'rabbit',
      target_word: 'conejo',
      vocab_program_group_id: vocab_group.id,
      user_id: create(:instructor).id,
      program_id: program.id
    )
  end

  let!(:word_in_current_program_group) do
    create(
      :vocab_word,
      base_word: 'car',
      target_word: 'automovil',
      vocab_program_group_id: vocab_group.id,
      user_id: instructor.id,
      program_id: program.id
    )
  end

  let!(:word_archived) do
    create(
      :vocab_word,
      base_word: 'snake',
      target_word: 'serpiente',
      vocab_program_group_id: vocab_group.id,
      user_id: instructor.id,
      program_id: program.id,
      archived: true
    )
  end

  before do
    create(
      :lesson,
      unit: unit_program_with_no_access,
      rank: 1,
      name: 'no access program lesson'
    )
    # stub access guardian methods
    allow_any_instance_of(AccessGuardian).to receive(:site_functions)
      .and_return(my_vocabulary: my_vocab_function)
    expect_any_instance_of(AccessGuardian).to receive(:has_accessible_license_group?)
      .with(my_vocab_function)
      .and_return(true)

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'learner has access to my vocabulary' do
    visit "/#{program.id}/vocab_words.json"
    expect(page).to(
      have_no_selector(
        %([class="flash-notice"]),
        text: 'You do not have access to My Vocabulary'
      )
    )
  end

  scenario 'learner can only see the vocabulary for his program' do
    visit "/#{program.id}/vocab_words.json"

    content = JSON.parse(page.body)['activities']
    results = content.map { |vocab_word| vocab_word['target_word'] }

    expect(results).to include(default_word_in_current_program_group.target_word)
    expect(results).to include(word_in_current_program_group.target_word)

    expect(results).not_to include(default_word_in_other_program_group.target_word)
    expect(results).not_to include(default_word_in_program_without_access.target_word)
    expect(results).not_to include(word_for_other_language_with_no_program.target_word)
    expect(results).not_to include(word_for_another_user.target_word)
    expect(results).not_to include(word_archived.target_word)
  end

  scenario 'learner can only see lessons for programs the user has ' \
           'access and are into his program group' do
    visit "/#{program.id}/vocab_words.json"

    content = JSON.parse(page.body)['lessons']
    lesson_names = content.map { |lesson| lesson['name'] }

    expect(lesson_names).to include(valid_lesson_1.name)
    expect(lesson_names).to include(valid_lesson_2.name)
  end
end
