describe AssignmentCalendar, :core => true do

  describe "#empty?" do
    it "returns false if there are any assignment weeks" do
      calendar = AssignmentCalendar.new(Date.today, Date.today+7)
      expect(calendar).not_to be_empty
    end
  end

  describe "each_month" do
    it "should call the block once when only one month in the calendar" do
      calendar = AssignmentCalendar.new(Date.today, Date.today)
      count = 0
      calendar.each_month {|month| count += 1}
      expect(count).to equal(1)
    end
  end

end
