module Week
  SUNDAY    = 0
  MONDAY    = 1
  TUESDAY   = 2
  WEDNESDAY = 3
  THURSDAY  = 4
  FRIDAY    = 5
  SATURDAY  = 6

  def self.week_containing(date, start_day = SUNDAY)
    date = Date.parse(date) if date.is_a? String

    offset = (date.wday - start_day) % 7

    week = nil
    if offset == 0
      week = date
    else
      week = date - offset
    end
    week.extend(Week)

    week
  end

  # Calculate the number of weeks, starting at 1, between this week
  # and the week containing the given starting date.
  def week_index(start_date)
    (self - Week.week_containing(start_date)).to_i / 7 + 1
  end

  def up_to(other_week)
    iterator = self.dup
    while iterator <= other_week
      yield(iterator.extend(Week))
      iterator+= 7
    end
  end

  def days
    days = []
    0.upto(6) do |offset|
      days << self + offset
    end
    days
  end

  def alt_label(for_open_course)
    space = for_open_course ? '' : ' '
    "#{self.strftime('%b')}. #{self.day} #{for_open_course ? '' : self.year}" \
    "#{space}" \
    "- #{(self + 6).strftime('%b')}. #{(self + 6).day}#{space}#{for_open_course ? '' : (self + 6).year}"
  end
end
