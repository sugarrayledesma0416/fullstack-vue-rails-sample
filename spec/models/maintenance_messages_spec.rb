describe MaintenanceMessage do

  describe "#current_message" do
    it "should return the message set for the current timeframe" do
      message = create(:maintenance_message, :published => true, :start => 1.hour.ago, :end => 1.hour.from_now)
      expect(MaintenanceMessage.current_message).to eq(message)
    end

    it "should return nil if no message is current" do
      create(:maintenance_message, :published => true, :start => 1.hour.from_now, :end => 2.hours.from_now)
      create(:maintenance_message, :published => true, :start => 5.hours.ago, :end => 3.hour.ago)
      expect(MaintenanceMessage.current_message).to be_nil
    end
  end
end
