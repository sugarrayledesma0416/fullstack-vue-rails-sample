describe LessonNavigable do
  let(:program) { build_stubbed(:program) }
  let(:user) { build_stubbed(:instructor) }
  let(:navigable_object) do
    Class.new do
      include LessonNavigable
      attr_reader :current_program, :current_user

      def initialize(program, user)
        @current_program = program
        @current_user = user
      end
    end.new(program, user)
  end
  let(:new_activities_toc_data) do
    {
      display_lesson: rand(1..5),
      toc_location: rand(20..30)
    }
  end
  let(:new_assessments_toc_data) do
    {
      display_lesson: rand(6..10),
      toc_location: rand(40..50)
    }
  end
  let(:new_gradebook_navigation_data) do
    {
      view_by: 'due_date', # or lesson
      week_or_lesson: '1',
      strand: 'contextos',
      category: 'homework',
      grade_display: 'points'
    }
  end

  before do
    # clear the redis cache
    navigable_object.send(
      :cache_manager,
      described_class::TOC_NAVIGATION_KEY
    ).cache_put(program.id.to_s, '{}')
    navigable_object.send(
      :cache_manager,
      described_class::GRADEBOOK_NAVIGATION_KEY
    ).cache_put(program.id.to_s, '{}')
  end

  describe '#load_activities_toc_navigation_data' do
    it 'returns an empty hash if no activities toc data has been stored' do
      expect(navigable_object.load_activities_toc_navigation_data).to eq({})
    end

    it 'returns the stored activities toc data if present' do
      expected_data = { 'my_activity_key' => 1234 }
      navigable_object.update_toc_lesson_navigation(activities_toc_data: expected_data)
      expect(navigable_object.load_activities_toc_navigation_data).to eq expected_data
    end
  end

  describe '#load_assessments_toc_navigation_data' do
    it 'returns an empty hash if no assessments toc data has been stored' do
      expect(navigable_object.load_assessments_toc_navigation_data).to eq({})
    end

    it 'returns the stored assessments toc data if present' do
      expected_data = { 'my_assessment_key' => 5678 }
      navigable_object.update_toc_lesson_navigation(assessments_toc_data: expected_data)
      expect(navigable_object.load_assessments_toc_navigation_data).to eq expected_data
    end
  end

  describe '#update_toc_lesson_navigation' do
    let(:cache_manager) { navigable_object.send(:cache_manager, described_class::TOC_NAVIGATION_KEY) }

    before do
      allow(cache_manager).to receive(:cache_put).and_call_original
    end

    it 'updates the activities toc data if given' do
      navigable_object.update_toc_lesson_navigation(activities_toc_data: new_activities_toc_data)
      expect(navigable_object.load_activities_toc_navigation_data).to eq(
        {
          'display_lesson' => new_activities_toc_data[:display_lesson],
          'toc_location' => new_activities_toc_data[:toc_location]
        }
      )
      expect(cache_manager).to have_received(:cache_put).with(
        program.id.to_s,
        {
          activities_toc_data: new_activities_toc_data,
          assessments_toc_data: {}
        }.to_json,
        LessonNavigable::LESSON_NAVIGABLE_REDIS_TTL
      )
    end

    it 'updates the assessments toc data if given' do
      navigable_object.update_toc_lesson_navigation(assessments_toc_data: new_assessments_toc_data)
      expect(navigable_object.load_assessments_toc_navigation_data).to eq(
        {
          'display_lesson' => new_assessments_toc_data[:display_lesson],
          'toc_location' => new_assessments_toc_data[:toc_location]
        }
      )
      expect(cache_manager).to have_received(:cache_put).with(
        program.id.to_s,
        {
          activities_toc_data: {},
          assessments_toc_data: new_assessments_toc_data
        }.to_json,
        LessonNavigable::LESSON_NAVIGABLE_REDIS_TTL
      )
    end

    it 'updates both the activities and assessments toc data if given' do
      navigable_object.update_toc_lesson_navigation(
        activities_toc_data: new_activities_toc_data,
        assessments_toc_data: new_assessments_toc_data
      )
      expect(navigable_object.load_assessments_toc_navigation_data).to eq(
        {
          'display_lesson' => new_assessments_toc_data[:display_lesson],
          'toc_location' => new_assessments_toc_data[:toc_location]
        }
      )
      expect(navigable_object.load_activities_toc_navigation_data).to eq(
        {
          'display_lesson' => new_activities_toc_data[:display_lesson],
          'toc_location' => new_activities_toc_data[:toc_location]
        }
      )
      expect(cache_manager).to have_received(:cache_put).with(
        program.id.to_s,
        {
          activities_toc_data: new_activities_toc_data,
          assessments_toc_data: new_assessments_toc_data
        }.to_json,
        LessonNavigable::LESSON_NAVIGABLE_REDIS_TTL
      )
    end

    it 'does not update redis if the data has not changed' do
      allow(navigable_object).to receive(:load_activities_toc_navigation_data).and_return(
        {
          'display_lesson' => new_activities_toc_data[:display_lesson],
          'toc_location' => new_activities_toc_data[:toc_location]
        }
      )
      allow(navigable_object).to receive(:load_assessments_toc_navigation_data).and_return(
        {
          'display_lesson' => new_assessments_toc_data[:display_lesson],
          'toc_location' => new_assessments_toc_data[:toc_location]
        }
      )
      navigable_object.update_toc_lesson_navigation(
        activities_toc_data: new_activities_toc_data,
        assessments_toc_data: new_assessments_toc_data
      )
      expect(cache_manager).not_to have_received(:cache_put)
    end

    it 'does not overwrite the gradebook navigation data' do
      navigable_object.update_gradebook_navigation(new_gradebook_navigation_data)
      navigable_object.update_toc_lesson_navigation(activities_toc_data: new_activities_toc_data)
      expect(navigable_object.load_gradebook_navigation_data).to eq(
        {
          'view_by' => new_gradebook_navigation_data[:view_by],
          'week_or_lesson' => new_gradebook_navigation_data[:week_or_lesson],
          'strand' => new_gradebook_navigation_data[:strand],
          'category' => new_gradebook_navigation_data[:category],
          'grade_display' => new_gradebook_navigation_data[:grade_display],
        }
      )
    end
  end

  describe '#update_gradebook_navigation' do
    let(:cache_manager) { navigable_object.send(:cache_manager, described_class::GRADEBOOK_NAVIGATION_KEY) }

    before do
      allow(cache_manager).to receive(:cache_put).and_call_original
    end

    it 'updates the gradebook navigation data' do
      navigable_object.update_gradebook_navigation(new_gradebook_navigation_data)
      expect(navigable_object.load_gradebook_navigation_data).to eq(
        {
          'view_by' => new_gradebook_navigation_data[:view_by],
          'week_or_lesson' => new_gradebook_navigation_data[:week_or_lesson],
          'strand' => new_gradebook_navigation_data[:strand],
          'category' => new_gradebook_navigation_data[:category],
          'grade_display' => new_gradebook_navigation_data[:grade_display],
        }
      )
      expect(cache_manager).to have_received(:cache_put).with(
        program.id.to_s,
        { gradebook_navigation_data: new_gradebook_navigation_data }.to_json,
        LessonNavigable::LESSON_NAVIGABLE_REDIS_TTL
      )
    end

    it 'does not overwrite the toc navigation data' do
      navigable_object.update_toc_lesson_navigation(activities_toc_data: new_activities_toc_data)
      navigable_object.update_gradebook_navigation(new_gradebook_navigation_data)
      expect(navigable_object.load_activities_toc_navigation_data).to eq(
        {
          'display_lesson' => new_activities_toc_data[:display_lesson],
          'toc_location' => new_activities_toc_data[:toc_location]
        }
      )
    end
  end

  describe '#load_gradebook_navigation_data' do
    it 'returns an empty hash if no gradebook data has been stored' do
      expect(navigable_object.load_gradebook_navigation_data).to eq({})
    end

    it 'returns the stored gradebook navigation data if present' do
      expected_data = { 'my_gradebook_key' => 1234 }
      navigable_object.update_gradebook_navigation(expected_data)
      expect(navigable_object.load_gradebook_navigation_data).to eq expected_data
    end
  end
end
