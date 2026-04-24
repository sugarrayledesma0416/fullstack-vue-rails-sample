class VocabToolsWordsPresenter

  attr_accessor :user, :program, :unit_id, :lesson_id

  def initialize(user, program, params)
    self.user = user
    self.program = program
    self.unit_id = params[:unit_id]
    self.lesson_id = params[:lesson_id]
  end

  def payload
    {
      words: (user_defined_words + default_vocabulary_words),
      program_metadata: program_metadata
    }
  end

  def default_vocabulary_words
    apply_content_scope(DefaultVocabularyWord)
  end
  private :default_vocabulary_words

  def user_defined_words
    apply_content_scope(UserDefinedWord.where(user_id: user))
  end
  private :user_defined_words

  def apply_content_scope(base_scope)
    if unit_id
      base_scope.by_unit(unit_id)
    else
      base_scope.where(lesson_id: lesson_id)
    end
    #TODO: Detect case where neither unit_id or lesson_id param is specified
    # and raise a nice explanatory error message.
    # In the message, include the actual params submitted, so we can look for things 
    # like 'undefined' etc.
  end
  private :apply_content_scope

  def program_metadata
    program_settings = ProgramSettings.new(program)
    {
      vocab_has_definition: program_settings.has_vocab_definition?,
      hide_translation: program_settings.hide_translation?,
      ssjr_student: program&.supersite_junior? && user.student?
    }
  end
  private :program_metadata
end
