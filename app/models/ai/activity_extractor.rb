module AI
  class ActivityExtractor
    attr_accessor :activity

    def initialize(activity)
      self.activity = activity
    end

    def activity_title
      activity.title.strip_tags.html_decode
    end

    def direction_line
      content&.dl&.text&.strip_tags&.squish
    end

    def language_code
      activity.program.language_code
    end

    def question_by_label(label)
      questions_by_label[label]
    end

    def question_sample_answers(label)
      question_by_label(label)&.sample_answer || []
    end

    def question_prompt(label)
      question_by_label(label)&.prompt&.text&.strip_tags&.squish || ''
    end

    def reference_data
      data = {
        audio_transcripts: audio_transcripts,
        dialogue_segments: dialogue_segments,
        email_data: email_data,
        headings: headings,
        id_card_data: id_card_data,
        image_alt_tags: image_alt_tags,
        internet_keywords: internet_keywords,
        list_items: list_items,
        model_texts: model_texts,
        model_v2_texts: model_v2_texts,
        panel_groups: panel_groups,
        paragraphs: paragraphs,
        paragraph_v2_texts: paragraph_v2_texts,
        social_media_posts: social_media_posts,
        table_xmls: table_xmls,
        video_transcripts: video_transcripts,
        vocabulary_items: vocabulary_items,
        wordbank_words_list: wordbank_words_list,
        character_lists: character_lists
      }

      # Only include keys with non-empty values
      data.reject { |_, value| value.nil? || (value.is_a?(Array) && value.empty?) || (value.is_a?(String) && value.empty?) }
    end

    def chat_configuration
      return {} unless content&.items&.any?

      item = content.items.first
      {
        input_mode: item.input_mode,
        allow_audio_transcript: item.allow_audio_transcript,
        response_count: item.response_count,
        initial_prompt: item.initial_prompt&.strip_tags&.squish,
        ai_instructions: item.ai_instructions&.strip_tags&.squish
      }
    end

    private def audio_references
      references.select { |reference| reference.type == 'audio' }
    end

    private def audio_transcripts
      audio_references.map do |reference|
        reference.audio&.media_item&.transcript&.delete('(/)')&.squish
      end.compact
    end

    private def content
      @content ||= activity.content_object
    end

    private def dialogue_references
      references.select { |reference| reference.type == 'dialogue_v2' }
    end

    private def dialogue_segments
      dialogue_references.flat_map do |reference|
        reference.segments&.map do |segment|
          {
            speaker: segment&.speaker&.content&.strip_tags&.squish,
            speech: segment&.speech&.strip_tags&.squish
          }
        end
      end.compact.flatten
    end

    private def email_references
      references.select { |reference| reference.type == 'email' }
    end

    private def email_data
      email_references.map do |reference|
        {
          from: reference.from_address&.strip_tags&.squish,
          subject: reference.subject&.strip_tags&.squish,
          body: reference.body_paragraphs&.join("\n")&.strip_tags&.squish
        }
      end.compact
    end

    private def heading_references
      references.select { |reference| reference.type == 'heading' }
    end

    private def headings
      heading_references.map do |reference|
        reference.content&.strip_tags&.squish
      end.compact
    end

    private def id_card_references
      references.select { |reference| reference.type == 'id_card' }
    end

    private def id_card_data
      id_card_references.map do |reference|
        reference.cards&.map do |card|
          {
            name: card&.name&.strip_tags&.squish,
            paragraph: card&.paragraphs&.join("\n")&.strip_tags&.squish
          }
        end
      end.compact.flatten
    end

    private def image_references
      references.select { |reference| reference.type == 'image' }
    end

    private def image_alt_tags
      image_references.map do |reference|
        reference.image&.media_item&.alt_tag&.squish
      end.compact
    end

    private def internet_keyword_references
      references.select { |reference| reference.type == 'internet_keywords' }
    end

    private def internet_keywords
      internet_keyword_references.flat_map do |reference|
        reference.keywords&.map do |keyword|
          {
            target: keyword&.dig('target')&.strip_tags&.squish,
            base: keyword&.dig('base')&.strip_tags&.squish
          }
        end
      end.compact
    end

    private def list_references
      references.select { |reference| reference.type == 'list' }
    end

    private def list_items
      list_references.flat_map do |reference|
        {
          header: reference.header&.strip_tags&.squish,
          body: reference.body&.strip_tags&.squish
        }
      end.compact
    end

    private def model_references
      references.select { |reference| reference.type == 'model' }
    end

    private def model_texts
      model_references.map do |reference|
        reference.body&.text&.strip_tags&.squish
      end.compact
    end

    private def model_v2_references
      references.select { |reference| reference.type == 'model_v2' }
    end

    private def model_v2_texts
      model_v2_references.map do |reference|
        {
          language: reference.language,
          header: reference.header&.strip_tags&.squish,
          content: reference.content&.strip_tags&.squish
        }
      end.compact
    end

    private def panel_group_references
      references.select { |reference| reference.type == 'panel_group' }
    end

    private def panel_groups
      panel_group_references.map do |reference|
        reference.panels&.map do |panel|
          { title: panel&.title&.strip_tags&.squish }
        end&.compact
      end.compact.flatten
    end

    private def paragraph_references
      references.select { |reference| reference.type == 'paragraph' }
    end

    private def paragraph_v2_references
      references.select { |reference| reference.type == 'paragraph_v2' }
    end

    private def paragraphs
      paragraph_references.map do |reference|
        reference.paragraph&.strip_tags&.squish
      end.compact
    end

    private def paragraph_v2_texts
      paragraph_v2_references.map do |reference|
        reference&.content&.strip_tags&.squish
      end.compact
    end

    private def questions_by_label
      @questions_by_label ||= content.items.index_by(&:label)
    end

    private def references
      @references ||= content&.references&.reject { |reference| reference.ai_target == 'student_only' }
    end

    private def social_media_references
      references.select { |reference| reference.type == 'social_media' }
    end

    private def social_media_posts
      social_media_references.map do |reference|
        reference.posts&.map do |post|
          {
            name: post&.name&.strip_tags&.squish,
            content: post&.items&.join("\n")&.strip_tags&.squish
          }
        end&.compact
      end.compact.flatten
    end

    private def table_reference
      references.find { |reference| reference.type == 'table' }
    end

    private def table_references
      references.select { |reference| reference.type == 'table' }
    end

    private def table_xml
      table = table_reference
      return nil unless table.present?

      build_table_xml(table)
    end

    private def table_xmls
      table_references.map do |table|
        build_table_xml(table)
      end.compact
    end

    private def build_table_xml(table)
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.table do
          if table.caption
            xml.caption table.caption&.content
          end

          if table.header_rows&.any?
            xml.thead do
              table.header_rows.each do |row|
                xml.tr do
                  row.cells&.each do |cell|
                    xml.th cell&.content
                  end
                end
              end
            end
          end

          if table.body_rows&.any?
            xml.tbody do
              table.body_rows.each do |row|
                xml.tr do
                  row.cells&.each do |cell|
                    xml.td cell&.content
                  end
                end
              end
            end
          end

          if table.footer_rows&.any?
            xml.tfoot do
              table.footer_rows.each do |row|
                xml.tr do
                  row.cells&.each do |cell|
                    xml.td cell&.content
                  end
                end
              end
            end
          end
        end
      end.to_xml.lines[1..-1].join
    end

    private def video_reference
      references.find { |reference| reference.type == 'video' }
    end

    private def video_references
      references.select { |reference| reference.type == 'video' }
    end

    private def video_transcript
      video_reference&.video&.media_item&.transcript&.strip_tags&.squish
    end

    private def video_transcripts
      video_references.map do |reference|
        reference.video&.media_item&.transcript&.strip_tags&.squish
      end.compact
    end

    private def vocabulary_references
      references.select { |reference| reference.type == 'vocabulary_v2' }
    end

    private def vocabulary_items
      vocabulary_references.map do |reference|
        reference&.terms&.map do |term|
          {
            word: term&.dig('target')&.strip_tags&.squish,
            definition: term&.dig('translation')&.strip_tags&.squish
          }
        end&.compact
      end.compact.flatten
    end

    private def wordbank_references
      references.select { |reference| reference.type == 'wordbank' }
    end

    private def wordbank_words_list
      wordbank_references.map do |reference|
        reference.words&.join(', ')
      end.compact
    end

    private def character_list_references
      references.select { |reference| reference.type == 'character_list' }
    end

    private def character_lists
      character_list_references.map do |reference|
        {
          characters: (reference&.characters || []).map do |character|
            {
              name: character&.name&.strip_tags&.squish
            }
          end
        }
      end.compact
    end
  end
end
