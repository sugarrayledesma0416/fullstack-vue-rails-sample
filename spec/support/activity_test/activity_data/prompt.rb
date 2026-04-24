module ActivityTest
  module ActivityData
    class Prompt
      attr_accessor :elements

      def initialize(elements)
        self.elements = elements
      end

      def text_elements
        elements.select { |element| element.is_a?(ActivityTest::ActivityData::PromptText) }
      end

      def image_elements
        elements.select { |element| element.is_a?(ActivityTest::ActivityData::PromptImage) }
      end

      def table
        # it should not have more than one table
        elements.detect { |element| element.is_a?(ActivityTest::ActivityData::PromptTable) }
      end

      def has_table?
        elements.any? { |element| element.is_a?(ActivityTest::ActivityData::PromptTable) }
      end
    end

    class PromptText
      attr_accessor :text

      def initialize(text:)
        @text = text.strip
      end
    end

    class PromptImage
      attr_accessor :image

      def initialize(image:)
        @image = image
      end
    end

    class PromptTable
      attr_accessor :prompts

      def initialize(prompts:)
        @prompts = prompts
      end
    end

    module PromptParser
      private def parse_prompt(prompt)
        Prompt.new(prompt.nil? ? [] : parse_prompt_elements(prompt.children))
      end

      private def parse_prompt_elements(nodes)
        nodes.map do |node|
          if node.text?
            PromptText.new(text: node.content)
          elsif node.element?
            if node.name == 'image'
              parse_prompt_image(node)
            elsif node.name == 'wol'
              # ignore wol elements
            elsif node.name == 'table'
              parse_prompt_table(node)
            elsif node.name == 'i' || node.name == 'b'
              # Italic or bold text
              PromptText.new(text: node.content)
            else
              raise NotImplementedError, "unknown prompt node '#{node.name}'"
            end
          end
        end
      end

      private def parse_prompt_image(node)
        id = Integer(node.attributes['id'].text)
        media_item = media_items.find { |item| item.id == id }
        PromptImage.new(image: media_item)
      end

      private def parse_prompt_table(node)
        PromptTable.new(prompts: node.search('td').map { |n| n.content.strip })
      end
    end
  end
end

