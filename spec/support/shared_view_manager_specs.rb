shared_examples_for 'an object that expects table activity questions' do
  describe '#table_activity?' do
    def build_activity(activity_type)
      build_stubbed(:activity, activity_type: activity_type)
    end

    it 'returns true when the activity is a table activity' do
      allow(view_manager).to receive(:activity)
        .and_return(build_activity('table_activity'))

      expect(view_manager.table_activity?).to be true
    end

    it 'returns false for an inline_open_ended activity' do
      allow(view_manager).to receive(:activity)
        .and_return(build_activity('inline_open_ended'))

      expect(view_manager.table_activity?).to be false
    end
  end

  def build_question(klass)
    instance_double(klass)
  end

  let(:table_inline_oe_class) do
    MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
  end

  let(:table_fib_class) do
    MaestroActivityEngine::ActivityContent::TableActivity::TableFillInTheBlank::Item
  end

  let(:table_drop_down_class) do
    MaestroActivityEngine::ActivityContent::TableActivity::TableDropDown::Item
  end

  let(:inline_oe_class) do
    MaestroActivityEngine::ActivityContent::InlineOpenEnded::Item
  end

  describe '#inline_open_ended_table_question?' do
    it 'returns true for a table inline OE question' do
      question = build_question(table_inline_oe_class)
      allow(question).to receive(:is_a?).with(table_inline_oe_class).and_return(true)

      expect(view_manager.inline_open_ended_table_question?(question)).to be true
    end

    it 'returns false for a table fill in the blank question' do
      question = build_question(table_fib_class)
      allow(question).to receive(:is_a?).with(table_inline_oe_class).and_return(false)

      expect(view_manager.inline_open_ended_table_question?(question)).to be false
    end

    it 'returns false for a table drop down question' do
      question = build_question(table_drop_down_class)
      allow(question).to receive(:is_a?).with(table_inline_oe_class).and_return(false)

      expect(view_manager.inline_open_ended_table_question?(question)).to be false
    end

    it 'returns false for an inline OE question' do
      question = build_question(inline_oe_class)
      allow(question).to receive(:is_a?).with(table_inline_oe_class).and_return(false)

      expect(view_manager.inline_open_ended_table_question?(question)).to be false
    end
  end

  describe '#table_activity_question?' do
    def set_up_question(klass)
      question = build_question(klass)
      expected_state = klass != inline_oe_class
      allow(question).to receive(:is_a?).with(table_inline_oe_class).and_return(expected_state)
      allow(question).to receive(:is_a?).with(table_fib_class).and_return(expected_state)
      allow(question).to receive(:is_a?).with(table_drop_down_class).and_return(expected_state)
      question
    end

    it 'returns true for a table inline OE question' do
      question = set_up_question(table_inline_oe_class)

      expect(view_manager.table_activity_question?(question)).to be true
    end

    it 'returns true for a table fill in the blank question' do
      question = set_up_question(table_fib_class)

      expect(view_manager.table_activity_question?(question)).to be true
    end

    it 'returns true for a table drop down question' do
      question = set_up_question(table_drop_down_class)

      expect(view_manager.table_activity_question?(question)).to be true
    end

    it 'returns false for an inline OE question' do
      question = set_up_question(inline_oe_class)

      expect(view_manager.table_activity_question?(question)).to be false
    end
  end
end
