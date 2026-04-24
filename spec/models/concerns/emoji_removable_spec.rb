require 'rails_helper'

describe EmojiRemovable do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Callbacks
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include EmojiRemovable

      attr_accessor :title, :description

      def attributes_to_clean
        [:title, :description]
      end
    end
  end

  let(:instance) { test_class.new }

  describe '#strip_emojis' do
    context 'when text does not contain emojis' do
      it 'returns the text unchanged' do
        text = "Hello World"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Hello World")
      end
    end

    context 'when text contains emoji modifiers' do
      it 'removes emoji skin tone modifiers and cleans spaces' do
        text = "Hello 👋🏻 👋🏼 👋🏽 👋🏾 👋🏿 World"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Hello World")
      end
    end

    context 'when text contains flags' do
      it 'removes country flags and cleans spaces' do
        text = "Countries: 🇺🇸 🇲🇽 🇨🇦 normal text"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Countries: normal text")
      end
    end

    context 'when text contains emoticons' do
      it 'removes emoticons and normalizes spaces' do
        text = "Feeling   😀  😃  😄   😁   today!"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Feeling today!")
      end
    end

    context 'when text contains misc symbols' do
      it 'removes misc symbols and cleans spaces' do
        text = "Symbols: ⭐ ⚡️ ❤️ ☕️ ⭐️ ⚠️ ♻️ ☢️ ☣️ ⚛️  "
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Symbols:")
      end
    end

    context 'when text contains numbers and regular text' do
      it 'preserves numbers and cleans spaces' do
        text = "1.   First  🎯  Test"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("1. First Test")
      end

      it 'preserves decimal numbers and cleans spaces' do
        text = "Average:  98.75%  🎯  "
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Average: 98.75%")
      end
    end

    context 'when text contains HTML' do
      it 'preserves HTML structure and cleans spaces' do
        text = "<p>Hello 👋</p><span>World 🌍</span>"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("<p>Hello</p><span>World</span>")
      end

      it 'preserves HTML attributes and cleans spaces' do
        text = '<div class="test">Content 🎯 </div>'
        instance.title = text
        instance.valid?
        expect(instance.title).to eq('<div class="test">Content</div>')
      end
    end

    context 'when text contains line breaks' do
      it 'preserves line breaks and cleans spaces per line' do
        text = "1. First point 👍\\r\\n2. Second point 🎉  \\r\\n3. Third point 🌟"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("1. First point \\r\\n2. Second point \\r\\n3. Third point")
      end

      it 'handles complex feedback with proper spacing' do
        text = "Feedback:\\r\\n" +
               "1. Introduction 📚\\r\\n" +
               "- Well structured 👍  \\r\\n" +
               "- Clear thesis 💡\\r\\n" +
               "\\r\\n" +
               "2. Main Points:\\r\\n" +
               "* First argument 🎯  \\r\\n" +
               "* Second argument ⭐\\r\\n" +
               "\\r\\n" +
               "Score: 95/100 🏆  "

        expected = "Feedback:\\r\\n" +
                  "1. Introduction \\r\\n" +
                  "- Well structured \\r\\n" +
                  "- Clear thesis \\r\\n" +
                  "\\r\\n" +
                  "2. Main Points:\\r\\n" +
                  "* First argument \\r\\n" +
                  "* Second argument \\r\\n" +
                  "\\r\\n" +
                  "Score: 95/100"

        instance.title = text
        instance.valid?
        expect(instance.title).to eq(expected)
      end
    end

    context 'when text contains special cases' do
      it 'handles strings with only emojis' do
        text = "  🎯  🎨  🎭  "
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("")
      end

      it 'handles multiple consecutive emojis' do
        text = "Start🎯🎨🎭End"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("StartEnd")
      end

      it 'cleans spaces at start and end' do
        text = "  🎯Start Text End🎭  "
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Start Text End")
      end

      it 'preserves single spaces between words' do
        text = "Before 🎯 Middle 🎨 After"
        instance.title = text
        instance.valid?
        expect(instance.title).to eq("Before Middle After")
      end
    end
  end
end
