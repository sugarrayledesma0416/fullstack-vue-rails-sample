
class DefaultVocabWordsReplacer
    REQUIRED_HEADERS = ['word', 'English translation', 'lesson', 'tags']

    def initialize(file_path, program_id)
      @file_path = file_path
      @program = Program.find(program_id)
      @lesson_ids_by_lesson_name = {}
    end

    def replace
      if file_headers_valid?
        delete_current_vocab_words
        extract_and_create_vocab_words_from_csv
      end
    end

    def delete_current_vocab_words
      DefaultVocabWord.delete(DefaultVocabWord.where(program_id: @program.id).map(&:id))
    end
    private :delete_current_vocab_words

    def extract_and_create_vocab_words_from_csv
      ActiveRecord::Base.transaction do
        csv_file.each do |row|
          DefaultVocabWord.create(vocab_word_attributes_for(row.to_hash))
        end
      end
    end
    private :extract_and_create_vocab_words_from_csv

    def vocab_word_attributes_for(csv_hash)
      { base_word: csv_hash['English translation'],
        language: @program.language_code,
        program_id: @program.id,
        target_word: csv_hash['word'],
        vocab_tags_attributes: parse_vocab_tags_attributes(csv_hash['tags']),
        lesson_id: lesson_id_for(csv_hash['word'], csv_hash['lesson']),
        target_definition: csv_hash['definition'] }
    end
    private :vocab_word_attributes_for

    def parse_vocab_tags_attributes(tags_value)
      return {} unless tags_value.present?
      tags_value.split(';').map{ |tag_text| { name: tag_text } }
    end

    def lesson_id_for(word, lesson_column_value)
      @lesson_ids_by_lesson_name[lesson_column_value] || find_lesson_by_name(word, lesson_column_value)
    end
    private :lesson_id_for

    def find_lesson_by_name(word, lesson_column_value)
      lesson = program_lessons.detect{ |lesson| lesson.name.split(' ')[1] == lesson_number(lesson_column_value) }
      raise "#{lesson_column_value} was not found for #{word} in #{@program.title}" unless lesson.present?
      @lesson_ids_by_lesson_name[lesson_column_value] = lesson.id
    end
    private :find_lesson_by_name

    def lesson_number(lesson_column_value)
      # Returns the less rankd lesson name
      lessons_by_number = {}
      lesson_names = lesson_column_value.split(';')
      lesson_names.inject(lessons_by_number) do |memo, lesson_name|
        lesson_suffix = lesson_name[/[^_]*$/]
        memo[lesson_suffix.to_i] = lesson_suffix
        memo
      end
      format_lesson_number(lessons_by_number[lessons_by_number.keys.min])
    end
    private :lesson_number

    def format_lesson_number(lesson_name)
      if is_german?
        "#{lesson_name}B" # Returns "B" lesson of the specified lesson number
      else
        lesson_name
      end
    end
    private :format_lesson_number

    def is_german?
      @is_german ||= csv_file.first.to_hash['lesson'].include?('Lektion')
    end
    private :is_german?

    def program_lessons
      @program_lessons ||= @program.units.map(&:lessons).flatten
    end
    private :program_lessons

    def csv_file
      @csv_file ||= CSV.read(@file_path, headers: true, encoding: 'windows-1252:utf-8')
    end
    private :csv_file

    def file_headers_valid?
      file_headers = csv_file.first.to_hash.keys
      missing_headers = REQUIRED_HEADERS - file_headers
      (missing_headers.empty?) || (raise "Required file headers missing in CSV file: #{missing_headers.join(', ')}.")
    end
    private :file_headers_valid?
  end
