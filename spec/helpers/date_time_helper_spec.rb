describe DateTimeHelper do
  include DateTimeHelper

  describe "#format_date_time, formatting a date/time" do
    context "when there is no zone preference" do
      let(:datetime) { '2009-09-10 5:30:08' }

      it "should support short format" do
        formatted = format_date_time(datetime, format = :short)
        expect(formatted).to eql "09/10/2009"
      end

      it "should support weekday, month ordinal_day format" do
        formatted = format_date_time(datetime, format = :weekday_month_ordinal)
        expect(formatted).to eql "Thursday, September 10th"
      end

      it "support month ordinal_day format" do
        formatted = format_date_time(datetime, format = :month_ordinal)
        expect(formatted).to eql "September 10th"
      end

      it "should support friendly format" do
        formatted = format_date_time(datetime, format = :friendly)
        expect(formatted).to eql "Thu, Sep 10 2009 05:30 AM #{Time.zone.parse(datetime).zone}"
      end

      it "should support long format" do
        formatted = format_date_time(datetime, format = :standard)
        expect(formatted).to eql "Sep 10 2009 05:30 AM"
      end

      it "should support time without zone format" do
        formatted = format_date_time(datetime, format = :time_without_zone)
        expect(formatted).to eql " 5:30 AM"
      end

      it "should support compact date and time" do
        formatted = format_date_time(datetime, format = :compact_date_and_time)
        expect(formatted).to eql "09/10/2009  5:30 AM"
      end

      it' should support a time with a lower-case a.m. or p.m.' do
        formatted = format_date_time(datetime, format = :activity_due_time)
        expect(formatted).to eql " 5:30 a.m." # getting an odd leading space
      end

      it "should support relative day strings (today)" do
        Timecop.travel(datetime) do
          formatted = format_date_time(datetime, :relative_weekday_month_ordinal)
          expect(formatted).to eql '<b>Today</b>, September 10th'
        end
      end

      it "should support relative day strings (tomorrow)" do
        Timecop.travel(datetime) do
          datetime = Date.current + 1.day
          formatted = format_date_time(datetime, :relative_weekday_month_ordinal)
          expect(formatted).to have_text('Tomorrow, September 11th')
        end
      end

      it "should support relative day strings for the TOC(today)" do
        Timecop.travel(datetime) do
          formatted = format_date_time(datetime, :toc_due_date)
          expect(formatted).to eql '<b>Today</b>'
        end
      end

      it "should support relative day strings for the TOC (tomorrow)" do
        Timecop.travel(datetime) do
          datetime = Date.current + 1.day
          formatted = format_date_time(datetime, :toc_due_date)
          expect(formatted).to have_text('Tomorrow')
        end
      end

      it "should supply a d/m/y string for the TOC" do
        Timecop.travel(datetime) do
          datetime = Date.current + 2.days
          formatted = format_date_time(datetime, :toc_due_date)
          expect(formatted).to have_text('Sat 09/12')
        end
      end

      it "should supply a d/m/y string like TOC date plus the time" do
        formatted = format_date_time(datetime, :toc_due_date_with_time)
        expect(formatted).to eql 'Thu 09/10  5:30 AM'
      end

      it "should not change day strings outside of today and tomorrow" do
        Timecop.travel(datetime) do
          datetime = Date.current + 2.days
          formatted = format_date_time(datetime, :relative_weekday_month_ordinal)
          expect(formatted).to have_text('Saturday, September 12th')
          datetime = datetime - 3.days
          formatted = format_date_time(datetime, :relative_weekday_month_ordinal)
          expect(formatted).to have_text('Wednesday, September 9th')
        end
      end

      it "should get today label unbold" do
        Timecop.travel(datetime) do
          formatted = format_date_time(datetime, :toc_due_date_with_time, "Pacific Time (US & Canada)")
          expect(formatted).to eq 'Today  5:30 AM'
        end
      end

      it "uses the current time zone as the default" do
        Time.use_zone('Mountain Time (US & Canada)') do
          datetime = Time.parse('Mon Feb 10 07:51:14 PST 2014')
          expect(format_date_time(datetime, :toc_due_date_with_time)).to eq('Mon 02/10  8:51 AM')
        end
      end
    end

    context "when there is a zone preference" do
      around(:each) do |example|
        Time.use_zone("Eastern Time (US & Canada)") do
          example.run
        end
      end

      context "when datetime passed is is string" do
        let(:datetime) { '2009-09-10 5:30:08' }

        it "should support short format" do
          formatted = format_date_time(datetime, format = :short, "Pacific Time (US & Canada)")
          expect(formatted).to eql "09/10/2009"
        end

        it "should support weekday, month ordinal_day format" do
          formatted = format_date_time(datetime, format = :weekday_month_ordinal, "Pacific Time (US & Canada)")
          expect(formatted).to eql "Thursday, September 10th"
        end

        it "supports month ordinal_day format" do
          formatted = format_date_time(datetime, format = :month_ordinal, "Pacific Time (US & Canada)")
          expect(formatted).to eql "September 10th"
        end

        it "should support friendly format" do
          Timecop.travel(Time.local(*datetime.split(/[\-\/\s\:]/))) do
            formatted = format_date_time(datetime, format = :friendly, "Pacific Time (US & Canada)")
            expected_zone = Time.now.in_time_zone( "Pacific Time (US & Canada)").strftime('%Z')
            expect(formatted).to eql "Thu, Sep 10 2009 05:30 AM #{expected_zone}"
          end
        end

        it "should support long format" do
          formatted = format_date_time(datetime, format = :standard, "Pacific Time (US & Canada)")
          expect(formatted).to eql "Sep 10 2009 05:30 AM"
        end

        it "should support time without zone format" do
          formatted = format_date_time(datetime, format = :time_without_zone, "Pacific Time (US & Canada)")
          expect(formatted).to eql " 5:30 AM"
        end

        it "should support compact date and time" do
          formatted = format_date_time(datetime, format = :compact_date_and_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql "09/10/2009  5:30 AM"
        end


        it' should support a time with a lower-case a.m. or p.m.' do
          formatted = format_date_time(datetime, format = :activity_due_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql " 5:30 a.m." # getting an odd leading space
        end

        it "should support relative day strings (today)" do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to eql '<b>Today</b>, September 10th'
          end
        end

        it "should support relative day strings (tomorrow)" do
          Timecop.travel(datetime) do
            datetime = Date.current + 1.day
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Tomorrow, September 11th')
          end
        end

        it "should support relative day strings for the TOC(today)" do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to eql '<b>Today</b>'
          end
        end

        it "should support relative day strings for the TOC (tomorrow)" do
          Timecop.travel(datetime) do
            datetime = Date.current + 1.day
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Tomorrow')
          end
        end

        it "should supply a d/m/y string for the TOC" do
          Timecop.travel(datetime) do
            datetime = Date.current + 2.days
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Sat 09/12')
          end
        end

        it "should supply a d/m/y string like TOC date plus the time" do
          formatted = format_date_time(datetime, :toc_due_date_with_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql 'Thu 09/10  5:30 AM'
        end

        it "should not change day strings outside of today and tomorrow" do
          Timecop.travel(datetime) do
            datetime = Date.current + 2.days
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Saturday, September 12th')
            datetime = datetime - 3.days
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Wednesday, September 9th')
          end
        end
      end

      context "when datetime passed is of type datetime" do
        let(:datetime) { Time.zone.local('2009','09','10', '5','30', '08') }

        it "should support short format" do
          formatted = format_date_time(datetime, format = :short, "Pacific Time (US & Canada)")
          expect(formatted).to eql "09/10/2009"
        end

        it "should support weekday, month ordinal_day format" do
          formatted = format_date_time(datetime, format = :weekday_month_ordinal, "Pacific Time (US & Canada)")
          expect(formatted).to eql "Thursday, September 10th"
        end

        it "supports weekday, month ordinal_day format" do
          formatted = format_date_time(datetime, format = :month_ordinal, "Pacific Time (US & Canada)")
          expect(formatted).to eql "September 10th"
        end

        it "should support friendly format" do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, format = :friendly, "Pacific Time (US & Canada)")
            expect(formatted).to eql "Thu, Sep 10 2009 02:30 AM PDT"
          end
        end

        it "should support long format" do
          formatted = format_date_time(datetime, format = :standard, "Pacific Time (US & Canada)")
          expect(formatted).to eql "Sep 10 2009 02:30 AM"
        end

        it "should support time without zone format" do
          formatted = format_date_time(datetime, format = :time_without_zone, "Pacific Time (US & Canada)")
          expect(formatted).to eql " 2:30 AM"
        end

        it "should support compact date and time" do
          formatted = format_date_time(datetime, format = :compact_date_and_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql "09/10/2009  2:30 AM"
        end


        it' should support a time with a lower-case a.m. or p.m.' do
          formatted = format_date_time(datetime, format = :activity_due_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql " 2:30 a.m." # getting an odd leading space
        end

        it "should support relative day strings (today)" do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to eql '<b>Today</b>, September 10th'
          end
        end

        it "should support relative day strings (tomorrow)" do
          Timecop.travel(datetime) do
            datetime = Date.current + 1.day
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Tomorrow, September 11th')
          end
        end

        it "should support relative day strings for the TOC(today)" do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to eql '<b>Today</b>'
          end
        end

        it "should support relative day strings for the TOC (tomorrow)" do
          Timecop.travel(datetime) do
            datetime = Date.current + 1.day
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Tomorrow')
          end
        end

        it "should supply a d/m/y string for the TOC" do
          Timecop.travel(datetime) do
            datetime = Date.current + 2.days
            formatted = format_date_time(datetime, :toc_due_date, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Sat 09/12')
          end
        end

        it "should supply a d/m/y string like TOC date plus the time" do
          formatted = format_date_time(datetime, :toc_due_date_with_time, "Pacific Time (US & Canada)")
          expect(formatted).to eql 'Thu 09/10  2:30 AM'
        end

        it "should not change day strings outside of today and tomorrow" do
          Timecop.travel(datetime) do
            datetime = Date.current + 2.days
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Saturday, September 12th')
            datetime = datetime - 3.days
            formatted = format_date_time(datetime, :relative_weekday_month_ordinal, "Pacific Time (US & Canada)")
            expect(formatted).to have_text('Wednesday, September 9th')
          end
        end

        it 'today_or_date format should not change d/m/y strings outside of today' do
          Timecop.travel(datetime) do
            datetime = Date.current - 1.days
            formatted = format_date_time(datetime, :today_or_date)
            expect(formatted).to have_text('Wed 9/9')
            datetime = Date.current + 1.days
            formatted = format_date_time(datetime, :today_or_date)
            expect(formatted).to have_text('Fri 9/11')
          end
        end

        it 'should supply a "Today" string by today_or_date format for today' do
          Timecop.travel(datetime) do
            formatted = format_date_time(datetime, :today_or_date)
            expect(formatted).to have_text('Today')
          end
        end
      end
    end
  end

  describe '#safe_date_string' do
    it 'returns empty string when specified date is nil' do
      expect(safe_date_string(nil)).to eql ''
    end

    it 'returns empty string when specified date is empty string' do
      expect(safe_date_string('')).to eql ''
    end

    it 'returns date formatted as mm/dd/yyyy when specified date is a valid date' do
      expect(safe_date_string(Date.civil(2010, 9, 25))).to eql '09/25/2010'
    end

    it 'returns any specified invalid date as a string' do
      invalid_values = [123456790124567890, '2012-02-31', '02/31/2012', 'abcdefg']
      invalid_values.each do |invalid_value|
        expect(safe_date_string(invalid_value)).to eql invalid_value.to_s
      end
    end
  end
end
