class VocabWordDeleter
  attr_reader :student, :params

  def initialize(student, params)
    @student = student
    @params = params
  end

  def delete_vocab_word
    if default_vocab_word?
      delete_default_vocab_word
    else
      delete_user_vocab_word
    end
  end

  def vocab_word_id
    params[:id]
  end
  private :vocab_word_id

  def delete_user_vocab_word
    vocab_word = student.vocab_words.find(vocab_word_id)
    vocab_word.update(archived: true)
  end
  private :delete_user_vocab_word

  def delete_default_vocab_word
    vocab_word = VocabWord.create!(build_vocab_word_attributes)
  end
  private :delete_default_vocab_word

  def default_vocab_word?
    # A :default_vocab_word of '1' indicates the associated :id param
    # is a default vocab word id, not a user defined vocab word id.
    params[:default_vocab_word] == '1'
  end
  private :default_vocab_word?

  def build_vocab_word_attributes
    default_vocab_word = DefaultVocabWord.find(vocab_word_id)
    {
      archived: true,
      base_word: default_vocab_word.base_word,
      default_vocab_word_id: vocab_word_id,
      language: default_vocab_word.language,
      lesson_id: default_vocab_word.lesson_id,
      target_definition: default_vocab_word.target_definition,
      target_word: default_vocab_word.target_word,
      user_id: student.id
    }
  end
  private :build_vocab_word_attributes
end
