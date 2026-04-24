describe DayMinute do
  it 'extends instances of ActiveRecord::TimeWithZone' do
    time = create(:user).created_at

    expect(time.methods).to include :day_minute
  end

  it 'extends instances of DateTime' do
    time = DateTime.civil(2011, 2, 8, 12, 40)

    expect(time.methods).to include :day_minute
  end

  it 'extends instances of Time' do
    time = Time.now

    expect(time.methods).to include :day_minute
  end

  describe '#day_minute' do
    it 'returns a number less than 60 before 1 AM' do
      time = DateTime.civil(2011, 2, 8, 0, 30)

      expect(time.day_minute).to be < 60
    end

    it 'returns a number greater than 60 after 1 AM' do
      time = DateTime.civil(2011, 2, 8, 1, 30)

      expect(time.day_minute).to be > 60
    end
  end
end
