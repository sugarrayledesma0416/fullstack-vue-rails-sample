describe Week do
  describe ".week_containing" do
    context "for default start_day of SUNDAY" do
      it "should return an object extended by Week" do
        date = Date.civil(2006, 01, 02)
        week_date = Week.week_containing(date)

        expect(week_date).to be_a(Week)
      end

      it "should return a week starting at the sunday before the date" do
        date = Date.civil(2006, 01, 02)
        week_date = Week.week_containing(date)

        expect(week_date.wday).to eql Week::SUNDAY
      end

      it "should return the given date if given a sunday" do
        date = Date.civil(2006, 01, 01)
        week_date = Week.week_containing(date)

        expect(week_date).to eql date
        expect(week_date.wday).to eql Week::SUNDAY
      end

      it "should return a date less than 7 days ago" do
        5.upto(20) do |day|
          date = Date.civil(2006, 01, day)
          week_date = Week.week_containing(date)

          expect(date - week_date).to be < 7
          expect(week_date.wday).to eql Week::SUNDAY
        end
      end
    end

    context "for start day of MONDAY" do
      it "should return a monday" do
        date = Date.civil(2006, 01, 02)
        week_date = Week.week_containing(date, Week::MONDAY)

        expect(week_date.wday).to eql Week::MONDAY
      end

      it "should return the given date if given a monday" do
        date = Date.civil(2006, 01, 02)
        week_date = Week.week_containing(date, Week::MONDAY)

        expect(week_date).to eql date
        expect(week_date.wday).to eql Week::MONDAY
      end

      it "should return a date less than 7 days ago" do
        5.upto(20) do |day|
          date = Date.civil(2006, 01, day)
          week_date = Week.week_containing(date, Week::MONDAY)

          expect(date - week_date).to be < 7
          expect(week_date.wday).to eql Week::MONDAY
        end
      end
    end

    context "for a start day of SATURDAY" do
      it "should return a saturday" do
        date = Date.civil(2006, 01, 8)
        week_date = Week.week_containing(date, Week::SATURDAY)

        expect(week_date.wday).to eql Week::SATURDAY
      end

      it "should return the given date if given a saturday" do
        date = Date.civil(2006, 01, 7)
        week_date = Week.week_containing(date, Week::SATURDAY)

        expect(week_date).to eql date
        expect(week_date.wday).to eql Week::SATURDAY
      end

      it "should return a date less than 7 days ago" do
        5.upto(20) do |day|
          date = Date.civil(2006, 01, day)
          week_date = Week.week_containing(date, Week::SATURDAY)

          expect(date - week_date).to be < 7
          expect(week_date.wday).to eql Week::SATURDAY
        end
      end
    end

    context "when given a string" do
      it "should convert to a date and proceed" do
        week_date = Week.week_containing("2006-01-01")
        expect(week_date).not_to be_nil
        expect(week_date).to be_a Date
        expect(week_date).to be_a(Week)
      end
    end
  end

  describe '#week_index' do
    it 'returns the position of the week relative to the given starting date' do
      week = Week.week_containing(Date.today)
      expect(week.week_index(week - 7)).to eq(2)
    end
  end

  describe "#up_to" do
    it "should include the start week" do
      start_week = Week.week_containing(Date.civil(2006, 01, 01))
      end_week = Week.week_containing(Date.civil(2006, 01, 01))

      included_weeks = []
      start_week.up_to(end_week) do |current_week|
        included_weeks << current_week
      end

      expect(included_weeks).to include start_week
    end

    it "should include the end week" do
      start_week = Week.week_containing(Date.civil(2006, 01, 01))
      end_week = Week.week_containing(Date.civil(2006, 01, 22))

      included_weeks = []
      start_week.up_to(end_week) do |current_week|
        included_weeks << current_week
      end

      expect(included_weeks).to include end_week
    end

    it "should yield objects extended by Week" do
      start_week = Week.week_containing(Date.civil(2006, 01, 01))
      end_week = Week.week_containing(Date.civil(2006, 01, 22))

      start_week.up_to(end_week) do |current_week|
        expect(current_week).to be_a(Week)
      end
    end

    it "should yield distinct objects" do
      start_week = Week.week_containing(Date.civil(2006, 01, 01))
      end_week = Week.week_containing(Date.civil(2006, 01, 22))

      included_weeks = []
      start_week.up_to(end_week) do |current_week|
        included_weeks << current_week
      end

      expect(included_weeks.length).to be > 1
      expect(included_weeks.uniq.length).to be > 1
    end
  end

  describe "#days" do
    it "should return 7 days, starting with the first day of the week" do
      week = Week.week_containing(Date.civil(2006, 01, 01))
      expect(week.days).to eql([Date.civil(2006, 01, 01), Date.civil(2006, 01, 02), Date.civil(2006, 01, 03),
                            Date.civil(2006, 01, 04), Date.civil(2006, 01, 05), Date.civil(2006, 01, 06),
                            Date.civil(2006, 01, 07)])
    end
  end

  describe '#alt_label' do
    let(:week_date) { Week.week_containing(Time.zone.now) }

    context 'when label is intended for an open course' do
      it 'returns the week date range without year' do
        expected_label = "#{week_date.strftime('%b')}. #{week_date.day} - " \
                         "#{(week_date + 6).strftime('%b')}. #{(week_date + 6).day}"
        expect(week_date.alt_label(for_open_course = true)).to eq expected_label
      end
    end

    context 'when label is not intended for an open course' do
      it 'returns the week date range including the year' do
        expected_label = "#{week_date.strftime('%b')}. #{week_date.day} #{week_date.year} - " \
                         "#{(week_date + 6).strftime('%b')}. #{(week_date + 6).day} #{(week_date + 6).year}"
        expect(week_date.alt_label(for_open_course = false)).to eq expected_label
      end
    end
  end
end
