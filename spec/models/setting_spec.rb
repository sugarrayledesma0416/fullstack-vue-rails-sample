describe Setting do

  describe Setting::Gradebook::CategoryView do
    it "should require a valid category view setting" do
      user = create(:user)
      expected = "Validation failed: Value 'bad_value' is not a valid 'gradebook__category_view'."
      expect{user.set(Setting::Gradebook::CategoryView, :bad_value)}.to raise_error expected
    end

    describe "#default" do
      it "should return 'lessons'" do
        value = Setting.default(Setting::Gradebook::CategoryView)
        expect(value).to eql Setting::Gradebook::CategoryView::LESSONS
      end
    end
  end

  describe Setting::Gradebook::Timeframe do
    it "should require a valid timeframe setting" do
      user = create(:user)
      expected = "Validation failed: Value 'bad_value' is not a valid 'gradebook__timeframe'."
      expect{user.set(Setting::Gradebook::Timeframe, :bad_value)}.to raise_error expected
    end

    describe "#default" do
      it "should return 'current'" do
        value = Setting.default(Setting::Gradebook::Timeframe)
        expect(value).to eql Setting::Gradebook::Timeframe::CURRENT
      end
    end
  end


  describe Setting::Gradebook::GradeDisplayStyle do
    it "should require a valid grade_display_style" do
      user = create(:user)
      expected = "Validation failed: Value 'bad_value' is not a valid 'gradebook__grade_display_style'."
      expect{user.set(Setting::Gradebook::GradeDisplayStyle, :bad_value)}.to raise_error expected
    end

    describe "#default" do
      it "should return 'percentage'" do
        value = Setting.default(Setting::Gradebook::GradeDisplayStyle)
        expect(value).to eql Setting::Gradebook::GradeDisplayStyle::PERCENT
      end
    end
  end

  describe Setting::GradingTasks::GradingStyle do
    it "should require a valid grading_style" do
      user = create(:user)
      expected = "Validation failed: Value 'bad_value' is not a valid 'grading_tasks__grading_style'."
      expect{user.set(Setting::GradingTasks::GradingStyle, :bad_value)}.to raise_error expected
    end

    describe "#default" do
      it "should return 'student_by_student'" do
        value = Setting.default(Setting::GradingTasks::GradingStyle)
        expect(value).to eql Setting::GradingTasks::GradingStyle::BY_STUDENT
      end
    end
  end

  describe Setting::GradingTasks::SpotcheckStyle do
    it "should require a valid spot_check_style" do
      user = create(:user)
      expected = "Validation failed: Value 'bad_value' is not a valid 'grading_tasks__spotcheck_style'."
      expect{user.set(Setting::GradingTasks::SpotcheckStyle, :bad_value)}.to raise_error expected
    end

    describe "#default" do
      it "should return 'random'" do
        value = Setting.default(Setting::GradingTasks::SpotcheckStyle)
        expect(value).to eql Setting::GradingTasks::SpotcheckStyle::RANDOM
      end
    end
  end

  describe Setting::AI::AllowGradingSuggestions do
    let(:user) { create(:user) }

    it 'allows a value of "true"' do
      expect do
        user.set(described_class, :true)
      end.not_to raise_error
    end

    it 'allows a value of "false"' do
      expect do
        user.set(described_class, :false)
      end.not_to raise_error
    end

    it 'does not allow a value other than "true" or "false"' do
      expect do
        user.set(described_class, :other)
      end.to raise_error(
        "Validation failed: Value 'other' is not a valid 'ai__allow_grading_suggestions'."
      )
    end

    it 'defaults to "false"' do
      expect(Setting.default(described_class)).to eq('false')
    end
  end

  describe Setting::AI::EnableGradingSuggestions do
    let(:user) { create(:user) }

    it 'allows a value of "true"' do
      expect do
        user.set(described_class, :true)
      end.not_to raise_error
    end

    it 'allows a value of "false"' do
      expect do
        user.set(described_class, :false)
      end.not_to raise_error
    end

    it 'does not allow a value other than "true" or "false"' do
      expect do
        user.set(described_class, :other)
      end.to raise_error(
        "Validation failed: Value 'other' is not a valid 'ai__enable_grading_suggestions'."
      )
    end

    it 'defaults to "false"' do
      expect(Setting.default(described_class)).to eq('false')
    end
  end
end
