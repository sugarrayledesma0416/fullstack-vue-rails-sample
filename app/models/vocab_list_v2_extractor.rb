class VocabListV2Extractor
  attr_reader :activity

  def self.generate_vocabulary_for(program)
    activities = Activity.where(lesson_id: program.lessons,
                                activity_type: 'vocab_list_v2')
                         .where('activities.instructor_revision_id is null')
    # If an activity has a nil toc_location, we only
    # want to keep it if it also has a component_name of Unlisted.
    # Supplemental vocab words are stored in Unlisted vocab_list_v2 activities.
    filtered_activities = activities.reject do |activity|
      activity.toc_location.nil? && activity.component_name != 'Unlisted'
    end
    # We sort so that the biggest vocabularies are at the end.
    # That way when we do the merge, words that were in two different activities
    # of the same lesson will go to the activity with the biggest vocabulary.
    # Because the vocabgroup title can be different between two vocabulary activities,
    # techProd wants to use the vocabgroup title of the end of lesson activity. Which
    # is the one with the biggest vocabulary.
    flashcards = filtered_activities.map do |activity|
      VocabListV2Extractor.new(activity).flashcards
    end.sort { |x, y| x.size <=> y.size }
    flashcards = flashcards.inject(&:merge)
    flashcards.each_value(&:save) if flashcards.present?
  end

  def initialize(activity)
    @activity = activity
  end

  def flashcards
    (activity.content_object.vocab_chart || []).inject({}) do |default_vocab_words, vc|
      vc.vocab_group.each do |vg|
        # include lesson ID in composite dictionary-entry ID: a few vocab
        # groups appear in multiple lessons
        composite_dictionary_id = [
          activity.lesson_id,
          vg.dictionary_entries.map { |de| de.id }.join(':')
        ].join(':')

        audio_paths = vg.dictionary_entries.map do |de|
          if de.audio.media_item.nil?
            nil
          else
            de.audio.media_item.public_filename
          end
        end

        dv = DefaultVocabularyWord.new(
          audio_paths: audio_paths,
          composite_dictionary_id: composite_dictionary_id,
          definition: vg.definition,
          lesson_id: activity.lesson.id,
          pinyin: vg.pinyin,
          program_id: activity.program.id,
          target: vg.target,
          # The topic will change from Activity to activity,
          # even if it is the same dictionary entry.
          topic: vc.title,
          translation: vg.translation
        )
        default_vocab_words[composite_dictionary_id] = dv
      end
      default_vocab_words
    end
  end

  def vtext
    (activity.content_object.vocab_chart || []).inject([]) do |rows, vc|
      rows << VocabChart.new(vc).data
      vc.vocab_group.each do |vg|
        vg.dictionary_entries.each do |de|
          rows << DictionaryEntry.new(de).data
        end
      end
      rows
    end
  end

  class DictionaryEntry
    extend Forwardable
    attr_reader :dictionary_entry

    def_delegator :@dictionary_entry, :target

    def initialize(dictionary_entry)
      @dictionary_entry = dictionary_entry
    end

    def audio_path
      dictionary_entry.audio&.media_item&.public_filename || ''
    end

    def data
      { target_word: target, audio_path: audio_path }
    end
  end

  class VocabGroup
    extend Forwardable
    attr_reader :vocab_group

    def_delegators :@vocab_group, :target, :translation, :hint, :definition, :pinyin

    def initialize(vocab_group)
      @vocab_group = vocab_group
    end

    def audio_paths
      vocab_group.dictionary_entries.map do |entry_data|
        DictionaryEntry.new(entry_data).audio_path
      end
    end

    def data
      {
        audio_paths: audio_paths,
        definition: definition,
        hint: hint,
        pinyin: pinyin,
        target_word: target,
        translation: translation
      }
    end
  end

  class VocabChart
    attr_reader :vocab_chart

    def initialize(vocab_chart)
      @vocab_chart = vocab_chart
    end

    def target
      vocab_chart.title
    end

    def audio_path
      vocab_chart.title_audio&.media_item&.public_filename || ''
    end

    def data
      { target_word: target, audio_path: audio_path }
    end
  end
end
