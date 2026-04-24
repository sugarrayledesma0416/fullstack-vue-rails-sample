describe EventMonth do
  before(:each) do
    @focus = double(Focus, :start_date => 1.month.ago.to_date,
                               :end_date => 3.months.from_now.to_date)
  end

  context "next" do
    it "returns a new EventMonth object for the next month in the calendar" do
      month = EventMonth.new(Date.new(2010,3,15), @focus)
      new_month = month.next
      expect(new_month.year).to eq(2010)
      expect(new_month.month).to eq(4)
    end

    it "handles the last month of the year properly" do
      month = EventMonth.new(Date.new(2010,12,15), @focus)
      new_month = month.next
      expect(new_month.year).to eq(2011)
      expect(new_month.month).to eq(1)
    end

  end

  context "#contains?" do
    before(:each) do
      @month = EventMonth.new(Date.new(2010,3,15), @focus)
    end

    it "returns true for all of the days in the month" do
      1.upto(31) do |day|
        expect(@month.contains?(Date.new(2010,3,day))).to be_truthy
      end
    end

    it "returns false for the last day of the previous month" do
      expect(@month.contains?(Date.new(2010,2,28))).to be_falsey
    end

    it "returns false for the first day of the next month" do
      expect(@month.contains?(Date.new(2010,4,1))).to be_falsey
    end

    it "returns false for a day in the month of the previous year" do
      expect(@month.contains?(Date.new(2009,3,15))).to be_falsey
    end

  end

  context "#to_s" do
    it "returns the current month id in the following form YYYY-MM" do
      month = EventMonth.new(Date.new(2010,3,30), @focus)
      expect(month.to_s).to eq("2010-03")
    end

    it "does not add a 0 to two digit months" do
      month = EventMonth.new(Date.new(2010,10,30), @focus)
      expect(month.to_s).to eq("2010-10")
    end
  end

  context "#each" do
    it "iterates over only the day actually in the month" do
      month = EventMonth.new(Date.new(2010,3,30), @focus)
      number_of_days = 0
      month.each do |day|
        number_of_days += 1
        expect(day.date.month).to eq(3)
        expect(day.date.year).to eq(2010)
      end
      expect(number_of_days).to eq(31)
    end
  end

  context "#days" do
    it "return valid number of days for jan " do
      expect(EventMonth.new(Date.new(2010,1,30), @focus).days.count).to eq(31)
    end
    it "return valid number of days for feb" do
      expect(EventMonth.new(Date.new(2010,2,21), @focus).days.count).to eq(28)
    end
    it "return valid number of days for apr" do
      expect(EventMonth.new(Date.new(2010,4,21), @focus).days.count).to eq(30)
    end
  end

  context "#each_week" do

    def number_of_weeks_yielded(month)
      number_of_weeks = 0
      month.each_week do |week|
        number_of_weeks += 1
      end
      number_of_weeks
    end

    it "iterates for all of the weeks in a month that spans 5 weeks" do
      month = EventMonth.new(Date.new(2010,3,30), @focus)
      expect(number_of_weeks_yielded(month)).to eq(5)
    end

    it "iterates for all of the weeks in a month that spans 6 weeks" do
      month = EventMonth.new(Date.new(2010,1,30), @focus)
      expect(number_of_weeks_yielded(month)).to eq(6)
    end

    it "iterates for all of the weeks in a month that spans 4 weeks" do
      month = EventMonth.new(Date.new(2009,2,5), @focus)
      expect(number_of_weeks_yielded(month)).to eq(4)
    end

    it "isn't confused my months that begin on a Sunday" do
      month = EventMonth.new(Date.new(2010,8,5), @focus)
      expect(number_of_weeks_yielded(month)).to eq(5)
    end

    it "isn't confused my months that end on a Saturday" do
      month = EventMonth.new(Date.new(2010,7,5), @focus)
      expect(number_of_weeks_yielded(month)).to eq(5)
    end

  end

end
