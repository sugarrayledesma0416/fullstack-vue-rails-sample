class VocabWordsCleaner
  def self.clean(program_id, should_delete)
    ids = Program.find(program_id).lessons.pluck(:id)
    if should_delete
      DefaultVocabularyWord.where(lesson_id: ids).delete_all
    else
      DefaultVocabularyWord.where(lesson_id: ids).count
    end
  end
end
