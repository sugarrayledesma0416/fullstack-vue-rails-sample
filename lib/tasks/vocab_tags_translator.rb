# encoding: utf-8

class VocabTagsTranslator

  def initialize(words)
    @words = words
  end

# programs
# D’accord! © 2015, Level 1: 72
# D’accord! © 2015, Level 2: 73
# D’accord! © 2015, Level 3: 68
# Temas:                     61
# AP Spanish:                60
  def translate
    @words.each do |word|
      case word.program_id
      # AP use the same default vocab words as Temas, but lessons are different.
      # We still need to lookup Temas' lessons, that's why we pass Temas program id here
      when 60, 61 then find_and_replace_lesson_tag_for_temas(word, 61)
      when 68, 72, 73 then find_and_replace_lesson_tag_for_daccord(word, word.program_id)
      end
    end
  end

  def lessons
    @lessons ||= Lesson.joins(:unit)
                  .where('units.program_id IN (60, 61, 68, 72, 73)')
                  .select('units.program_id AS unit_program_id, lessons.id, lessons.name')
                  .group_by(&:unit_program_id)
  end
  private :lessons

  def find_and_replace_lesson_tag_for_temas(word, program_id)
    replace_lesson_tag_for(word, 'Tema_[0-9]', program_id)
  end

  def find_and_replace_lesson_tag_for_daccord(word, program_id)
    replace_lesson_tag_for(word, '[[:<:]]Leçon_[1-9][A-Z]*[[:>:]]', program_id)
  end


  def replace_lesson_tag_for(word, regex, program_id)
    # vocab tag to delete
    vocab_tag = word.vocab_tags.where("name REGEXP ?", regex).first
    lesson = lessons[program_id].detect{ |lesson| lesson.name =~ /#{vocab_tag.name.gsub('_', ' ')}/ }

    if lesson.present? && word.update!(lesson_id: lesson.id)
      puts "Vocab word: #{word.target_word} - lesson_id updated: #{lesson.id} (#{lesson.name}) / Vocab tag #{vocab_tag.name} removed" if lesson.present?
      vocab_tag.destroy
    end
  end
  private :replace_lesson_tag_for
end
