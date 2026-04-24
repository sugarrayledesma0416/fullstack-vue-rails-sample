FactoryBot.define do
  factory :chat_enable_setting do
    start_date { 2.months.ago }
    end_date { 1.months.from_now }
    start_time do
      Time.local(0, 0,  9, 1, 1, 2012, Time.now.wday, Time.now.yday, Time.now.isdst, 'EST')
    end
    end_time do
      Time.local(0, 0, 17, 1, 1, 2012, Time.now.wday, Time.now.yday, Time.now.isdst, 'EST')
    end
    days_of_week { 0x3E }
  end
end
