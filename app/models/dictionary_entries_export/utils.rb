module DictionaryEntriesExport
  module Utils
    S3_DESTINATION_FOLDER = 'tasks/dictionary_entries_reports/'.freeze
    REGEX = /\\u([0-9a-z]{4})/

    private def content_object(cms_activity_id)
      first_activity_in_program(cms_activity_id, @program_id).content_object
    end

    private def vocabulary_tutorial_data(current_vocabulary_tutorial)
      program_id = @program_id
      unit = current_vocabulary_tutorial.lesson.unit.name
      lesson = current_vocabulary_tutorial.lesson.name
      strand = current_vocabulary_tutorial.strand&.title
      activity_name = current_vocabulary_tutorial.title
      cms_activity_id = current_vocabulary_tutorial.cms_activity_id
      [program_id, unit, lesson, strand, activity_name, cms_activity_id]
    end

    private def act_with_entries(cms_activity_id, dictionary_entry)
      search_string = "//dictionary_entry//id[text()='#{dictionary_entry.id}']"
      activities(cms_activity_id).select do |activity|
        Nokogiri::XML(activity.activity_content.content).at_xpath(search_string).present?
      end
    end

    private def activities(cms_activity_id)
      Activity.where(cms_activity_id:,
                     activity_type: DictionaryEntriesExport::ErrorsExporter::SUPPORTED_ACTIVITY_TYPES)
              .where.not(id: first_activity_in_program(cms_activity_id, @program_id).id)
              .includes(:lesson)
    end

    private def dictionary_entry_data(dictionary_entry)
      word = dictionary_entry.target
      link_to_cms = "https://cms.vhlcentral.com/dictionary_entries/#{dictionary_entry.id}"
      language = dictionary_entry.language
      descriptor = dictionary_entry.descriptor
      translation = dictionary_entry.translation
      machine_word = dictionary_entry.target_for_speech_rec
      audio_url = audio_url(dictionary_entry)
      image_url = image_url(dictionary_entry)
      [word, link_to_cms, language, descriptor, translation, machine_word, audio_url, image_url]
    end

    private def audio_url(dictionary_entry)
      if dictionary_entry.image.present?
        "https://cms.vhlcentral.com/media_items/#{dictionary_entry.audio.media_item_id}"
      else
        ''
      end
    end

    private def image_url(dictionary_entry)
      if dictionary_entry.image.present?
        "https://cms.vhlcentral.com/media_items/#{dictionary_entry.image.media_item_id}"
      else
        ''
      end
    end

    private def activity_data(activity)
      {
        program: activity.program.title,
        lesson: activity.lesson.name,
        strand: activity.strand.title || '',
        activity_title: activity.title,
        cms_activity_id: activity.cms_activity_id
      }
    end

    private def csv_data(current_vocabulary_tutorial, dictionary_entry)
      vocabulary_tutorial_data(current_vocabulary_tutorial) +
      dictionary_entry_data(dictionary_entry)
    end

    private def temp_csv_file
      @temp_csv_file ||= Tempfile.new(@file_name)
    end

    private def first_activity_in_program(cms_activity_id, program_id)
      Activity
        .includes(lesson: { unit: :program })
        .joins(lesson: { unit: :program })
        .where(cms_activity_id:, programs: { id: program_id }).first
    end

    private def upload_file_no_cache(file)
      upload_file(file, cache_control: 'no-cache, no-store, must-revalidate')
    end

    private def dictionary_entries(cms_activity_id)
      activity_type = first_activity_in_program(cms_activity_id, @program_id).activity_type
      entries = case activity_type
                when 'vocabulary_tutorial', 'vocabulary_tutorial_v2'
                  dictionary_entries_for_vocabulary_tutorial(cms_activity_id)
                when 'grouped_vocab'
                  dictionary_entries_for_grouped_vocab(cms_activity_id)
                when 'vocab_list', 'vocab_list_v2'
                  dictionary_entries_for_tutorial_vocab_list(cms_activity_id)
                when 'dictionary_flashcards'
                  dictionary_entries_for_flashcards(cms_activity_id)
                when 'learning_engine'
                  dictionary_entries_for_learning_engine(cms_activity_id)
                when 'reference_activity'
                  dictionary_entries_for_reference_activity(cms_activity_id)
                when 'hotspots'
                  dictionary_entries_for_hotspots(cms_activity_id)
                when 'speech_rec_listen_repeat'
                  dictionary_entries_for_speech_rec_listen_repeat(cms_activity_id)
                else
                  []
                end
      entries.uniq(&:id) || []
    end
  end
end
