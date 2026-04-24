require 'support/activity_test/activity_data/base_activity'

module ActivityTest
  module ActivityData
    class VocabListV2 < BaseActivity
      attr_accessor :audio_media_items

      def initialize(activity, audio_media_items)
        super(activity, nil)
        self.audio_media_items = audio_media_items
      end

      def vocab_chart(number)
        vocab_charts[number - 1]
      end

      def vocab_charts
        @vocab_charts ||= activity.content_object.vocab_chart.map.with_index(1) do |vocab_chart, chart_number|
          generate_vocab_chart(vocab_chart, chart_number)
        end
      end

      private def generate_vocab_chart(vocab_chart, chart_number)
        entries = vocab_chart.vocab_group.map.with_index(1) do |group, entry_number|
          VocabChartEntry.new(
            entry_number: entry_number,
            translation: group.translation,
            target: group.target,
            hint: group.hint,
            audio_paths: group.audio_paths,
            image_paths: group.image_paths
          )
        end
        VocabChart.new(
          chart_number: chart_number,
          title: vocab_chart.title,
          title_audio: parse_audio_media_link(vocab_chart.title_audio),
          entries: entries
        )
      end

      class VocabChart
        attr_accessor :chart_number, :title, :title_audio, :entries

        def initialize(chart_number:, title:, title_audio:, entries:)
          @chart_number = chart_number
          @title = title
          @title_audio = title_audio
          @entries = entries
        end
      end

      class VocabChartEntry
        attr_accessor :entry_number, :translation, :target, :hint, :audio_paths, :image_paths

        def initialize(entry_number:, translation:, target:, hint:, audio_paths:, image_paths:)
          @entry_number = entry_number
          @translation = translation
          @target = target
          @hint = hint
          @audio_paths = audio_paths
          @image_paths = image_paths
        end
      end

      private def parse_audio_media_link(audio)
        if audio
          id = audio.media_item_id
          media_item = audio_media_items.find { |item| item.id == id }
          if media_item.nil?
            raise ArgumentError, "Unable to find media_item_audio(id: #{id})"
          end
          media_item
        end
      end
    end
  end
end
