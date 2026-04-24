describe EventWeek do
  before(:each) do
    @sunday = Date.new(2010,03,28)
    @saturday = @sunday+6
    @focus = double(Focus, :start_date => 1.month.ago.to_date,
                           :end_date => 3.months.from_now.to_date)
  end

  context "#jd_week" do
    it "gives the same week number from Sunday to Saturday" do
      @sunday.upto(@saturday) do |day|
        expect(EventWeek.jd_week(day)).to eq(EventWeek.jd_week(@sunday))
      end
    end

    it "gives the previous week for the Saturday before a Sunday" do
      expect(EventWeek.jd_week(@sunday - 1)).to eq(EventWeek.jd_week(@sunday) - 1)
    end

    it "gives the next week for the Sunday following a Sunday" do
      expect(EventWeek.jd_week(@sunday + 7)).to eq(EventWeek.jd_week(@sunday) + 1)
    end
  end

  context "#start_date_of_jd_week" do
    it "should return the sunday for the given week" do
      jd_week = EventWeek.jd_week(Date.new(2010,03,24))
      first_day_of_week = EventWeek.start_date_of_jd_week(jd_week)
      expect(first_day_of_week.class).to eq(Date)
      expect(first_day_of_week.wday).to  be(0)
    end
  end

  context "#each" do

    it "iterates from Sunday to Saturday for the week specified" do
      date = Date.new(2010,3,30)
      week_number = EventWeek.jd_week(date)
      week = EventWeek.new(week_number, @focus, date)
      expected_day = 0
      week.each do |day|
        expect(day.date.wday).to eq(expected_day)
        expected_day += 1
      end
      expect(expected_day).to eq(7)
    end

    it "bridges a year for the last week of a year that doesn't end on Saturday" do
      date = Date.new(2010,12,31)
      week_number = EventWeek.jd_week(date)
      week = EventWeek.new(week_number, @focus, date)
      first_year = nil
      last_year = nil
      week.each do |day|
        first_year ||= day.date.year
        last_year = day.date.year
      end
      expect(last_year - first_year).to eq(1)
    end

  end

end
