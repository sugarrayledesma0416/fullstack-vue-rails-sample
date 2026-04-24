module DictionaryEntriesExport
  class DictionaryEntriesReport
    include Radner::FilesS3Bucket
    include DictionaryEntriesExport::Utils
    include DictionaryEntriesExport::ErrorsExporter

    attr_reader :file_name, :file_path, :errors

    HEADERS = %w[ program_id unit lesson strand activity_name
                  cms_activity_id word cms_link language descriptor
                  translation machine_word audio_url image_url in_other_activities ].freeze

    def initialize(program_id:, cms_activity_ids:)
      @program_id = program_id
      @cms_activity_ids = cms_activity_ids
      @file_name = "#{program_id}-#{cms_activity_ids.join('-')}.csv"
      @file_path = File.join(S3_DESTINATION_FOLDER, @file_name)
      @temp_file_path = "/tmp/#{@file_name}"
      @errors = []
    end

    def generate_csv_file
      CSV.open(@temp_file_path, 'wb', write_headers: true, headers: HEADERS) do |csv|
        @cms_activity_ids.each do |cms_activity_id|
          current_vocabulary_tutorial = first_activity_in_program(cms_activity_id, @program_id)
          next unless current_vocabulary_tutorial

          dictionary_entries(cms_activity_id).each do |dictionary_entry|
            act_data = act_with_entries(cms_activity_id, dictionary_entry).map do |activity|
              activity_data(activity)
            end.compact

            # Convert to JSON to handle Unicode characters, then back to array
            act_data = JSON.parse(act_data.to_json.gsub(REGEX) { |s| [$1.to_i(16)].pack('U') })

            csv_data = csv_data(current_vocabulary_tutorial, dictionary_entry) + (act_data || [])
            csv << csv_data
          end
        end
      end
    rescue StandardError => e
      @errors << { step: 'generating_content', message: e }
    end

    def delete_temp_csv_file
      temp_csv_file.close
      temp_csv_file.unlink
      FileUtils.rm_f(@temp_file_path)
    rescue StandardError => e
      @errors << { step: 'deleting_temp_file', message: e }
    end

    def upload_csv_file
      upload_file_no_cache(File.open(@temp_file_path))
    rescue StandardError => e
      @errors << { step: 'uploading_file', message: e }
    end

    def csv_exists_in_s3?
      file_exists?(@file_path)
    end

    private def dictionary_entries_for_vocabulary_tutorial(cms_activity_id)
      content_object(cms_activity_id).say_it.flat_map(&:dictionary_entries) +
      content_object(cms_activity_id).listen_and_repeat.flat_map(&:dictionary_entries) +
      content_object(cms_activity_id).match.flat_map(&:ordered_dictionary_entries)
    end

    private def dictionary_entries_for_grouped_vocab(cms_activity_id)
      content_object(cms_activity_id).grouped_vocabulary.flat_map do |group_vocab|
        group_vocab.groups.flat_map(&:dictionary_entries)
      end
    end

    private def dictionary_entries_for_tutorial_vocab_list(cms_activity_id)
      content_object(cms_activity_id).vocab_chart.flat_map do |chart|
        chart.vocab_group.flat_map(&:dictionary_entries)
      end
    end

    private def dictionary_entries_for_flashcards(cms_activity_id)
      content_object(cms_activity_id).dictionary_entries
    end

    private def dictionary_entries_for_learning_engine(cms_activity_id)
      content_object(cms_activity_id).items.flat_map do |item|
        case item
        when MaestroActivityEngine::ActivityContent::LearningEngine::ListenAndRepeat
          item.dictionary_entries
        when MaestroActivityEngine::ActivityContent::LearningEngine::Identify
          item.dictionary_entries + item.dictionary_entries_from_groups.to_a
        when MaestroActivityEngine::ActivityContent::LearningEngine::SayIt
          item.dictionary_entries
        else
          []
        end
      end
    end

    private def dictionary_entries_for_reference_activity(cms_activity_id)
      content = content_object(cms_activity_id)
      if content.respond_to?(:items) && content.items.present?
        content.items.flat_map do |item|
          item.respond_to?(:dictionary_entries) ? Array(item.dictionary_entries) : []
        end
      elsif content.respond_to?(:dictionary_entries)
        Array(content.dictionary_entries)
      else
        []
      end
    end

    private def dictionary_entries_for_hotspots(cms_activity_id)
      content_object(cms_activity_id).scene.flat_map(&:terms).flat_map(&:dictionary_entry)
    end

    private def dictionary_entries_for_speech_rec_listen_repeat(cms_activity_id)
      content_object(cms_activity_id).items.flat_map do |item|
        item.respond_to?(:dictionary_entry) ? Array(item.dictionary_entry) : []
      end
    end
  end
end
