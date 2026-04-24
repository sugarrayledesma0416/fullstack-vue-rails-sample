describe GradebookDeleteScoresSchedulerWorker do
  describe '#perform' do
    it 'schedules gradebook deletion workers for courses within the specified inclusive date range' do
      # don't delete scores for this one
      create(
        :course,
        start_date: Date.new(2020, 06, 01),
        end_date: Date.new(2020, 06, 20),
        allow_past_end_date: true
      )
      targeted_course = create(
        :course,
        start_date: Date.new(2020, 06, 01),
        end_date: Date.new(2020, 06, 22),
        allow_past_end_date: true
      )
      # or this one
      create(
        :course,
        start_date: Date.new(2020, 06, 01),
        end_date: Date.new(2020, 06, 24),
        allow_past_end_date: true
      )
      expect(GradebookDeleteScoresWorker).to receive(:perform_in).with(0, targeted_course.id)
      described_class.new.perform('2020/06/21', '2020/06/23')
    end
  end
end
