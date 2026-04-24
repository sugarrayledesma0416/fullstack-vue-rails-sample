describe EventCalendar do
  let(:start_date) { 1.month.ago.to_date }
  let(:end_date) { 3.months.from_now.to_date }

  let(:calendar_setting) do
    CalendarPresenter::CalendarSettings.new(
      end_date: end_date,
      start_date: start_date,
      type: 'section'
    )
  end

  it 'has an attr accessor for messages' do
    calendar = described_class.new(calendar_setting)
    expect(calendar.messages).to eq([])
    calendar.messages << 'message 1'
    calendar.messages << 'message 2'
    expect(calendar.messages).to eq(['message 1', 'message 2'])
  end

  describe '#months' do
    it 'contains all the months in the range' do
      calendar = described_class.new(calendar_setting)
      expect(calendar.months.size).to eq(5)
    end

    it 'contains only one month if target month provided' do
      target = Date.today
      calendar = described_class.new(calendar_setting, target)
      expect(calendar.months.size).to eq(1)
      expect(calendar.months.first.month).to eq(target.month)
    end

    it 'contains the first month in the range if target month is before start' do
      target = 2.months.ago
      calendar = described_class.new(calendar_setting, target)
      expect(calendar.months.size).to eq(1)
      expect(calendar.months.first.month).to eq(start_date.month)
    end

    it 'contains the last month in range if the target month is after end' do
      target = 4.months.from_now
      calendar = described_class.new(calendar_setting, target)
      expect(calendar.months.size).to eq(1)
      expect(calendar.months.first.month).to eq(end_date.month)
    end
  end

  context 'when focused on a course with varying class days,' do
    let(:course) { build_stubbed(:course) }
    let(:calendar_setting) do
      CalendarPresenter::CalendarSettings.new(
        course: course,
        end_date: course.end_date,
        section_class_days_vary: true,
        start_date: course.start_date,
        type: 'course'
      )
    end

    before do
      allow(course).to receive(:section_class_days_vary?).and_return(true)
    end

    it 'sets a message' do
      calendar = described_class.new(calendar_setting)
      expect(calendar.messages).to contain_exactly(
        'The course schedule varies by section. ' \
        'Select a section to view its schedule.'
      )
    end
  end

  context 'when focused on a course that does not have varying class days,' do
    let(:course) { build_stubbed(:course) }

    let(:calendar_setting) do
      CalendarPresenter::CalendarSettings.new(
        end_date: course.end_date,
        section_class_days_vary: false,
        start_date: course.start_date,
        type: 'course'
      )
    end

    before do
      allow(course).to receive(:section_class_days_vary?).and_return(false)
    end

    it 'does not set a message related to class days' do
      calendar = described_class.new(calendar_setting)
      expect(calendar.messages).to be_empty
    end
  end

  describe '#month' do
    it 'returns the month of the specified target date' do
      target_date = 2.months.from_now
      calendar = described_class.new(calendar_setting, target_date)

      expect(calendar.month).to eq(target_date.month)
    end
  end

  describe '#year' do
    it 'returns the year of the specified target date' do
      target_date = 2.months.from_now
      calendar = described_class.new(calendar_setting, target_date)

      expect(calendar.year).to eq(target_date.year)
    end
  end

  describe '#empty?' do
    it 'returns false if there are any event weeks' do
      calendar = described_class.new(calendar_setting, Date.today + 7)
      expect(calendar).not_to be_empty
    end
  end

  describe '#prev_year_month' do
    it 'returns the previous year/month string' do
      target = Date.today
      calendar = described_class.new(calendar_setting, target)
      expected = "%4d-%02d" % [1.month.ago.year, 1.month.ago.month]
      expect(calendar.prev_year_month).to eq(expected)
    end

    it 'returns nil if previous month is out of range' do
      calendar = described_class.new(calendar_setting, calendar_setting.start_date)
      expect(calendar.prev_year_month).to be_nil
    end
  end

  describe '#next_year_month' do
    it 'returns the next year/month string' do
      target = 2.months.from_now.to_date
      calendar = described_class.new(calendar_setting, target)
      expected = "%4d-%02d" % [3.months.from_now.year, 3.months.from_now.month]
      expect(calendar.next_year_month).to eq(expected)
    end

    it 'returns nil if next month is out of range' do
      calendar = described_class.new(calendar_setting, calendar_setting.end_date)
      expect(calendar.next_year_month).to be_nil
    end
  end

  describe '#this_year_month' do
    it 'returns this year/month string' do
      target = 1.month.from_now
      calendar = described_class.new(calendar_setting, target)
      expected = "#{Date.today.year}-#{'%02d' % Date.today.month}"
      expect(calendar.this_year_month).to eq(expected)
    end

    it 'returns nil if out of range' do
      focus = double(
        Focus,
        end_date: 3.months.from_now.to_date,
        start_date: 1.month.from_now.to_date,
        type: 'section'
      ).as_null_object
      target = 1.month.from_now.to_date
      calendar_setting = CalendarPresenter::CalendarSettings.new(
        end_date: focus.end_date,
        start_date: focus.start_date
      )
      calendar = described_class.new(calendar_setting, target)
      expect(calendar.this_year_month).to be_nil
    end
  end

  describe '#days_of_week' do
    it 'returns a list of the abbreviated days of the week' do
      calendar = described_class.new(calendar_setting, Date.today)
      expected = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
      expect(calendar.days_of_week).to eq(expected)
    end
  end

  describe '#populate_categories' do
    it 'finds all the categories used by assignments' do
      create(:category)
      calendar = described_class.new(calendar_setting, Date.today)
      expect(calendar).to receive(:each_day).and_return([])
      calendar.populate_categories
    end
  end

  describe '.<<' do
    context 'with assignment that are not assessments,' do
      it 'populates the categories array' do
        category = create(:category)
        activity = build_stubbed(:activity)
        allow(activity).to receive(:assessment?).and_return(false)
        assignment = build_stubbed(
          :assignment,
          assignable: activity,
          category: category,
          due_date: Date.today
        )

        category = Category.where(id: category.id)
        allow(Category).to receive(:where).with(
          id: [category.first.id]
        ).and_return(category)
        calendar = described_class.new(calendar_setting, Date.today)
        expect(calendar).to receive(:each_day).and_return([])
        calendar << assignment
        calendar.populate_categories
      end
    end

    context 'with assignment that is related to an assessment,' do
      it 'does not populate the categories array' do
        category = build_stubbed(:category)
        category_with_arr = Category.where(id: [])
        assessment = build_stubbed(:activity)
        allow(assessment).to receive(:assessment?).and_return(true)
        assignment = build_stubbed(
          :assignment,
          assignable: assessment,
          category: category,
          due_date: Date.today
        )
        allow(Category).to receive(:where).with(id: [])
                                          .and_return(category_with_arr)
        calendar = described_class.new(calendar_setting, Date.today)
        expect(calendar).to receive(:each_day).and_return([])
        calendar << assignment
        calendar.populate_categories
      end
    end
  end
end
