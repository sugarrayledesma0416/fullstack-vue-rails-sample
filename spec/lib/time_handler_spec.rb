describe TimeHandler do
  include TimeHandler

  describe '#date_time_from_parts' do
    it 'return the date time and zone correctly' do
      date = Time.parse("2014-03-01")
      time = Time.parse("10:12:13")
      zone = "Central Time (US & Canada)"
      date_time = date_time_from_parts(date, time, zone)
      expect(date_time.strftime("%Y-%m-%d")).to eql("2014-03-01")
      expect(date_time.strftime("%H:%M:%S")).to eql("10:12:13")
      expect(date_time.zone).to eql('CST')
    end
  end

  describe "#time_for_zone" do
    it "returns date and time relative to the current time zone" do
      Timecop.freeze do
        expect(time_for_zone().to_s).to eql Time.zone.now.to_s
      end
    end

    it "returns date and time relative to the passed time zone" do
      test_tz = 'Pacific Time (US & Canada)'
      expected_value = nil
      in_time_zone(test_tz) { expected_value = Time.zone.now.to_s }
      expect(time_for_zone(test_tz).to_s).to eql expected_value
    end
  end

  describe "#date_for_zone" do
    it "returns date and time relative to the current time zone" do
      expect(date_for_zone().to_s).to eql Time.zone.now.to_date.to_s
    end

    it "returns date and time realtive to the passed time zone" do
      test_tz = 'Sydney'
      expected_value = nil
      in_time_zone(test_tz) { expected_value = Time.zone.now.to_date.to_s }
      expect(date_for_zone(test_tz).to_s).to eql expected_value
    end
  end

end
