describe CourseTimeCalculator do
  let(:course) { double("Course", start_date: start_date, end_date: end_date) }

  describe '.calculate' do
    context 'when course is nil' do
      it 'returns weeks: 0 and days: 0' do
        result = CourseTimeCalculator.calculate(nil)
        expect(result).to eq({ weeks: 0, days: 0 })
      end
    end

    context 'when course has valid start and end dates' do
      let(:start_date) { Date.new(2024, 1, 1) }
      let(:end_date) { Date.new(2024, 1, 15) } # 14 days

      it 'calculates the correct number of weeks and days' do
        result = CourseTimeCalculator.calculate(course)
        expect(result).to eq({ weeks: 2, days: 0 })
      end

      context 'when total days are not an exact multiple of 7' do
        let(:end_date) { Date.new(2024, 1, 17) } # 16 days

        it 'calculates the correct weeks and remaining days' do
          result = CourseTimeCalculator.calculate(course)
          expect(result).to eq({ weeks: 2, days: 2 })
        end
      end
    end
  end

  describe '.formatted_time' do
    context 'when course has 0 weeks and 0 days' do
      it 'formats the time correctly as 0 weeks and 0 days' do
        result = CourseTimeCalculator.formatted_time(nil)
        expect(result).to eq({ weeks: "0 weeks", days: "0 days" })
      end
    end

    context 'when course has 1 week exactly' do
      let(:start_date) { Date.new(2024, 1, 1) }
      let(:end_date) { Date.new(2024, 1, 8) } # 7 days exactly

      it 'formats the time with singular week and no days' do
        result = CourseTimeCalculator.formatted_time(course)
        expect(result).to eq({ weeks: "1 week", days: "0 days" })
      end
    end

    context 'when course has multiple weeks and days' do
      let(:start_date) { Date.new(2024, 1, 1) }
      let(:end_date) { Date.new(2024, 1, 17) } # 16 days

      it 'formats the time with plural weeks and days' do
        result = CourseTimeCalculator.formatted_time(course)
        expect(result).to eq({ weeks: "2 weeks", days: "2 days" })
      end
    end
  end
end
