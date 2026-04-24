describe AssignmentWeek, :core => true do
  before(:each) do
    @sunday = Date.new(2010,03,28)
    @saturday = @sunday+6
  end

  context "#jd_week" do
    it "gives the same week number from Sunday to Saturday" do
      @sunday.upto(@saturday) do |day|
        expect(AssignmentWeek.jd_week(day)).to eq(AssignmentWeek.jd_week(@sunday))
      end
    end

    it "gives the previous week for the Saturday before a Sunday" do
      expect(AssignmentWeek.jd_week(@sunday - 1)).to eq(AssignmentWeek.jd_week(@sunday) - 1)
    end

    it "gives the next week for the Sunday following a Sunday" do
      expect(AssignmentWeek.jd_week(@sunday + 7)).to eq(AssignmentWeek.jd_week(@sunday) + 1)
    end
  end

  context "#start_date_of_jd_week" do
    it "should return the sunday for the given week" do
      jd_week = AssignmentWeek.jd_week(Date.new(2010,03,24))
      first_day_of_week = AssignmentWeek.start_date_of_jd_week(jd_week)
      expect(first_day_of_week.class).to eql Date
      expect(first_day_of_week.wday).to  be(0)
    end
  end

  context "#each" do

    it "iterates from Sunday to Saturday for the week specified" do
      week_number = AssignmentWeek.jd_week(Date.new(2010,3,30))
      week = AssignmentWeek.new(week_number)
      expected_day = 0
      week.each do |day|
        expect(day.due_date.wday).to eq(expected_day)
        expected_day += 1
      end
      expect(expected_day).to eq(7)
    end

    it "bridges a year for the last week of a year that doesn't end on Saturday" do
      week_number = AssignmentWeek.jd_week(Date.new(2010,12,31))
      week = AssignmentWeek.new(week_number)
      first_year = nil
      last_year = nil
      week.each do |day|
        first_year ||= day.due_date.year
        last_year = day.due_date.year
      end
      expect(last_year - first_year).to eq(1)
    end

  end

end
