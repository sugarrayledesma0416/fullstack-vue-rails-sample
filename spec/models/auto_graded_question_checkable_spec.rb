describe AutoGradedQuestionCheckable do
  describe '#auto_graded_question?' do
    let(:test_class) do
      Class.new do
        include AutoGradedQuestionCheckable

        attr_accessor :question

        def initialize(question)
          self.question = question
        end

        def auto_graded?
          auto_graded_question?(question)
        end
      end
    end

    let(:mae_prefix) { MaestroActivityEngine::ActivityContent }

    it 'is false if the question is an OpenEnded item' do
      item = mae_prefix::OpenEnded::Item.new

      expect(test_class.new(item)).not_to be_auto_graded
    end

    it 'is false if the question is an InlineOpenEnded item' do
      item = mae_prefix::InlineOpenEnded::Item.new

      expect(test_class.new(item)).not_to be_auto_graded
    end

    it 'is true if the question is a FillInTheBlanks item' do
      item = mae_prefix::FillInTheBlanks::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a DropDown item' do
      item = mae_prefix::DropDown::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a MultipleAnswer item' do
      item = mae_prefix::MultipleAnswer::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a MultipleChoice item' do
      item = mae_prefix::MultipleChoice::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a MultipleChoiceSame item' do
      item = mae_prefix::MultipleChoiceSame::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a TableFillInTheBlank item' do
      item = mae_prefix::TableActivity::TableFillInTheBlank::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is true if the question is a TableDropDown item' do
      item = mae_prefix::TableActivity::TableDropDown::Item.new

      expect(test_class.new(item)).to be_auto_graded
    end

    it 'is false if the question is a TableInlineOpenEnded item' do
      item = mae_prefix::TableActivity::TableInlineOpenEnded::Item.new

      expect(test_class.new(item)).not_to be_auto_graded
    end

    it 'is false if the question is a TrueFalseEnhanced item' do
      item = mae_prefix::TrueFalseEnhanced::Item.new

      expect(test_class.new(item)).not_to be_auto_graded
    end

    context 'when question is a Smartbook response,' do
      let(:item) { Smartbook::Response.new('') }

      it 'is false if the response is instructor-gradeable' do
        allow(item).to receive(:instructor_gradable?).and_return(true)

        expect(test_class.new(item)).not_to be_auto_graded
      end

      it 'is true if the response is not instructor-gradeable' do
        allow(item).to receive(:instructor_gradable?).and_return(false)

        expect(test_class.new(item)).to be_auto_graded
      end
    end
  end
end
