# config/initializers/time_formats.rb
Date::DATE_FORMATS[:slash_month_day_long_year] = '%m/%d/%Y'
Date::DATE_FORMATS[:short_ordinal] = ->(date) { date.strftime("%A, %b #{date.day.ordinalize} %-I:%M %p") }
Time::DATE_FORMATS[:short_ordinal] = Date::DATE_FORMATS[:short_ordinal]
