class VocabWordUpdater
  attr_reader :student, :params

  def initialize(student, params)
    @student = student
    @params = params
  end

  def update_vocab_word
    if default_vocab_word?
      copy_default_vocab_word
    else
      update_user_vocab_word
    end
  end

  private def default_vocab_word?
    # A :default_vocab_word of '1' indicates the associated :id param
    # is a default vocab word id, not a user defined vocab word id.
    params[:default_vocab_word] == 1
  end

  private def attrs
    params.except(
      :default_vocab_word, :id, :created_at, :updated_at, :lesson_name, :image_path
    )
  end

  private def update_user_vocab_word
    vocab_word = student.vocab_words.find(params[:id])
    # default_word is a helpful attribute, but it's not actually a
    # database column. So, we reject it in order to update the vocab
    # word successfully.
    vocab_word.update(attrs)
    vocab_word.reload
  end

  private def copy_default_vocab_word
    VocabWord.create(build_vocab_word_attributes)
  end

  private def build_vocab_word_attributes
    attrs.merge(
      default_vocab_word_id: params[:id],
      user_id: student.id,
      vocab_tags_attributes: (params[:vocab_tags_attributes] || [])
    )
  end
end
