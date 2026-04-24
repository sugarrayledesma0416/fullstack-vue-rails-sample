module AI
  # Formats activity resources into a structured message
  class ActivityReferencesFormatter
    attr_accessor :activity_or_preview

    # @param activity [Activity] The activity to extract resources from
    def initialize(activity)
      self.activity_or_preview = activity
    end

    # Returns a formatted XML string containing all available resources
    # @return [String, nil] The formatted XML or nil if no resources are available
    def format_as_xml
      return nil unless activity_or_preview

      # Create an activity extractor to get all reference data
      extractor = AI::ActivityExtractor.new(activity_or_preview)
      @reference_data = extractor.reference_data

      # Skip if there's no reference data
      return nil if @reference_data.empty?

      # Use Nokogiri::XML::Builder to generate the XML
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.references do
          if @reference_data[:audio_transcripts].present?
            xml.audio_transcripts do
              @reference_data[:audio_transcripts].each do |transcript|
                xml.transcript transcript
              end
            end
          end

          if @reference_data[:dialogue_segments].present?
            xml.dialogue_segments do
              @reference_data[:dialogue_segments].each do |segment|
                xml.segment do
                  xml.speaker segment[:speaker]
                  xml.speech segment[:speech]
                end
              end
            end
          end

          if @reference_data[:email_data].present?
            xml.emails do
              @reference_data[:email_data].each do |email|
                xml.email do
                  xml.from email[:from]
                  xml.subject email[:subject]
                  xml.body email[:body]
                end
              end
            end
          end

          if @reference_data[:headings].present?
            xml.headings do
              @reference_data[:headings].each do |heading|
                xml.heading heading
              end
            end
          end

          if @reference_data[:id_card_data].present?
            xml.id_cards do
              @reference_data[:id_card_data].each do |card|
                xml.card do
                  xml.name card[:name]
                  xml.paragraph card[:paragraph]
                end
              end
            end
          end

          if @reference_data[:image_alt_tags].present?
            xml.image_alt_tags do
              @reference_data[:image_alt_tags].each do |alt_tag|
                xml.alt_tag alt_tag
              end
            end
          end

          if @reference_data[:internet_keywords].present?
            xml.internet_keywords do
              @reference_data[:internet_keywords].each do |keyword|
                xml.keyword do
                  xml.target keyword[:target]
                  xml.base keyword[:base]
                end
              end
            end
          end

          if @reference_data[:list_items].present?
            xml.lists do
              @reference_data[:list_items].each do |list|
                xml.list do
                  xml.header list[:header] if list[:header].present?
                  xml.body list[:body] if list[:body].present?
                end
              end
            end
          end

          if @reference_data[:model_texts].present?
            xml.model_texts do
              @reference_data[:model_texts].each do |model_text|
                xml.model_text do
                  xml.text model_text if model_text.present?
                end
              end
            end
          end

          if @reference_data[:model_v2_texts].present?
            xml.model_v2_texts do
              @reference_data[:model_v2_texts].each do |model_v2_text|
                xml.model_v2_text do
                  xml.language model_v2_text[:language] if model_v2_text[:language].present?
                  xml.header model_v2_text[:header] if model_v2_text[:header].present?
                  xml.content model_v2_text[:content] if model_v2_text[:content].present?
                end
              end
            end
          end

          if @reference_data[:panel_groups].present?
            xml.panel_groups do
              @reference_data[:panel_groups].each do |panel|
                xml.panel do
                  xml.title panel[:title] if panel[:title].present?
                end
              end
            end
          end

          if @reference_data[:paragraphs].present?
            xml.paragraphs do
              @reference_data[:paragraphs].each do |paragraph|
                xml.paragraph paragraph
              end
            end
          end

          if @reference_data[:paragraph_v2_texts].present?
            xml.paragraph_v2_texts do
              @reference_data[:paragraph_v2_texts].each do |paragraph_v2_text|
                xml.paragraph_v2_text do
                  xml.text paragraph_v2_text if paragraph_v2_text.present?
                end
              end
            end
          end

          if @reference_data[:social_media_posts].present?
            xml.social_media_posts do
              @reference_data[:social_media_posts].each do |post|
                xml.post do
                  xml.name post[:name] if post[:name].present?
                  xml.content post[:content] if post[:content].present?
                end
              end
            end
          end

          if @reference_data[:table_xmls].present?
            xml.tables do
              @reference_data[:table_xmls].each do |table_xml|
                xml.table do
                  xml << table_xml
                end
              end
            end
          end

          if @reference_data[:video_transcripts].present?
            xml.video_transcripts do
              @reference_data[:video_transcripts].each do |transcript|
                xml.transcript transcript
              end
            end
          end

          if @reference_data[:vocabulary_items].present?
            xml.vocabulary_items do
              @reference_data[:vocabulary_items].each do |item|
                xml.item do
                  xml.word item[:word] if item[:word].present?
                  xml.definition item[:definition] if item[:definition].present?
                end
              end
            end
          end

          if @reference_data[:character_lists].present?
            xml.character_lists do
              @reference_data[:character_lists].each do |character_list|
                xml.character_list do
                  if character_list[:characters].present?
                    xml.characters do
                      character_list[:characters].each do |character|
                        xml.character do
                          xml.name character[:name]&.squish if character[:name].present?
                          xml.image(id: character[:image][:id]) if character[:image].present?
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          if @reference_data[:wordbank_words_list].present?
            xml.wordbank_words do
              @reference_data[:wordbank_words_list].each do |words|
                xml.words words
              end
            end
          end
        end
      end

      # Return the XML without the declaration line
      builder.to_xml.lines[1..-1].join
    end

    private

    attr_reader :reference_data
  end
end
