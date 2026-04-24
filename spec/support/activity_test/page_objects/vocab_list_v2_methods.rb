require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_vocab_chart(number)
      vocab_chart = @page_object.vocab_chart(number)
      if block_given?
        yield vocab_chart
      else
        vocab_chart
      end
    end

    module VocabListV2Methods
      def select_vocab_list_language_visibility(language)
        id = vocab_list_language_visibility_radio_button_id(language)
        vhl_choose(id, allow_label_click: true)
      end

      def vocab_list_language_visibility_radio_button_id(language)
        case language
        when :target then 'target_language'
        when :translation then 'translation_language'
        when :both then 'both'
        else
          raise NotImplementedError, "Invalid language '#{language}'"
        end
      end

      def vocab_chart(number)
        VocabChartElement.new(self, number)
      end

      # Private methods goes below
      class VocabChartElement
        attr_accessor :chart_number, :page_object

        def initialize(page_object, chart_number)
          @page_object = page_object
          @chart_number = chart_number
        end

        def to_s
          "vocab_chart(#{chart_number})"
        end

        def title
          table = page_object.find_nth_or_fail('table', chart_number - 1, self)
          table.sibling('.c-header-row').find('span[data-audio-src]').text
        end

        def audio_source
          table = page_object.find_nth_or_fail('table', chart_number - 1, self)
          table.sibling('.c-header-row').find('audio source')
        end

        def entry(entry_number)
          VocabChartEntryElement.new(page_object, chart_number, entry_number)
        end
      end

      class VocabChartEntryElement
        attr_accessor :chart_number, :entry_number, :page_object

        def initialize(page_object, chart_number, entry_number)
          @page_object = page_object
          @chart_number = chart_number
          @entry_number = entry_number
        end

        def to_s
          "vocab_chart(#{chart_number}).entry(#{entry_number})"
        end

        def target
          entry_element.text
        end

        def translation
          table = page_object.find_nth_or_fail('table', chart_number - 1, self)
          page_object.element_find_nth_or_fail(table, 'tbody tr td', entry_number - 1, self).text
        end

        def audio(audio_number)
          page_object.element_find_nth_or_fail(
            entry_element, 'audio source', audio_number - 1,
            "#{self}.audio(#{audio_number})"
          )
        end

        private def entry_element
          table = page_object.find_nth_or_fail('table', chart_number - 1, self)
          page_object.element_find_nth_or_fail(table, 'tbody tr th', entry_number - 1, self)
        end
      end
    end
  end
end
