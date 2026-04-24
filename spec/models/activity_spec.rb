describe Activity, core: true do
  include RspecJsContentHelpers
  include ActivityXmlContentHelper

  def copy_xml(src, dest)
    FileUtils.makedirs(File.dirname(dest))
    FileUtils.cp src, dest
  end

  let(:activity) { build(:activity) }

  describe 'scopes' do
    # program_with_toc_entries factory creates toc structure with 3 units/lessons
    let(:program_1) { create(:program_with_toc_entries) }
    let(:program_2) { create(:program_with_toc_entries) }

    # Activities in program_1
    let!(:activity_1) { create(:activity, lesson_id: program_1.lessons.first.id) }
    let!(:activity_2) { create(:activity, lesson_id: program_1.lessons.last.id) }

    describe 'hidden' do
      let(:instructor) { create(:instructor) }
      let(:student) { create(:student) }
      let(:sh_course) { create(:course) }

      context 'when student' do
        it 'returns all activities when there are no hidden course_library_activity' do
          expect(described_class.hidden(student, sh_course).count).to eq(2)
        end

        it 'does not return activity_1 which has a hidden course_library_activity' do
          create(:course_library_activity, course: sh_course, activity: activity_1, hidden: true)
          expect(described_class.hidden(student, sh_course).count).to eq(1)
        end

        it 'does not return activity_1 or 2 which both have a hidden course_library_activity' do
          create(:course_library_activity, course: sh_course, activity: activity_1, hidden: true)
          create(:course_library_activity, course: sh_course, activity: activity_2, hidden: true)
          expect(described_class.hidden(student, sh_course).count).to eq(0)
        end
      end

      context 'when instructor' do
        it 'returns all activities when there are no hidden course_library_activity' do
          expect(described_class.hidden(instructor, sh_course).count).to eq(2)
        end

        it 'returns all activities when activity_1 has a hidden course_library_activity' do
          create(:course_library_activity, course: sh_course, activity: activity_1, hidden: true)
          expect(described_class.hidden(instructor, sh_course).count).to eq(2)
        end

        it 'returns all activities when both activity_1 and 2 have a hidden course_library_activity' do
          create(:course_library_activity, course: sh_course, activity: activity_1, hidden: true)
          create(:course_library_activity, course: sh_course, activity: activity_2, hidden: true)
          expect(described_class.hidden(instructor, sh_course).count).to eq(2)
        end
      end
    end

    describe 'by_program' do
      it 'returns only activities from the specified program' do
        # Activities not in selected program
        create(:activity, lesson_id: program_2.lessons.first.id)
        create(:activity, lesson_id: program_2.lessons.last.id)

        expect(described_class.by_program(program_1.id).map(&:id))
          .to eq([activity_1.id, activity_2.id])
      end
    end

    describe 'unlisted' do
      it 'returns only activities with a nil toc location and component name "Unlisted"' do
        # Activity without a toc location, not in "Unlisted" component
        create(:activity, toc_location: nil)

        # Activity with toc location and in the "Unlisted" component
        create(:activity, toc_location: 1, component_name: 'Unlisted')

        # Expected:
        # Activity with nil toc location and in the "Unlisted" component
        activity_unlisted = create(:activity, toc_location: nil, component_name: 'Unlisted')

        expect(described_class.unlisted.map(&:id)).to eq([activity_unlisted.id])
      end
    end

    describe 'has_toc_location' do
      it 'returns only activities with a toc location' do
        # Activity without a toc location
        create(:activity, toc_location: nil)

        expect(described_class.has_toc_location.map(&:id)).to eq([activity_1.id, activity_2.id])
      end
    end

    describe 'has_toc_location_plus_unlisted' do
      it 'returns activities with a toc_location plus nil toc_location in "Unlisted" component' do
        # Activity without a toc location, not in "Unlisted" component
        create(:activity, toc_location: nil)

        # Activity with nil toc location and in the "Unlisted" component
        activity_unlisted = create(:activity, toc_location: nil, component_name: 'Unlisted')

        expect(described_class.has_toc_location_plus_unlisted.map(&:id).length).to eq(3)
        expect(described_class.has_toc_location_plus_unlisted.map(&:id)).to include(activity_1.id)
        expect(described_class.has_toc_location_plus_unlisted.map(&:id)).to include(activity_2.id)
        expect(described_class.has_toc_location_plus_unlisted.map(&:id)).to include(activity_unlisted.id)
      end
    end
  end

  describe 'callbacks' do
    describe 'after commit' do
      it 'triggers notify_update when activity is created' do
        allow(activity).to receive(:notify_update)
        activity.save!
        expect(activity).to have_received(:notify_update)
      end

      it 'triggers update_gradebook when activity is updated' do
        activity.save!
        allow(activity).to receive(:update_gradebook)
        activity.title = 'Loco Pronuncuacion'
        activity.save!
        expect(activity).to have_received(:update_gradebook)
      end

      it 'triggers notify_deletion for a destroyed activity' do
        activity.save!
        allow(activity).to receive(:notify_deletion)
        activity.destroy
        expect(activity).to have_received(:notify_deletion)
      end
    end
  end

  describe 'behaviors' do
    it 'is attemptable' do
      expect(build_stubbed(:activity)).to be_a(Attemptable)
    end

    it 'is a scorable sorter' do
      expect(build_stubbed(:activity)).to be_a(ScorableSorter)
    end
  end

  describe 'notifications' do
    let(:lesson)   { create(:lesson_with_toc_entries, label: 'Lesson 1') }
    let(:strand)   { create(:toc_entry) }
    let(:activity) { build_stubbed(:activity, lesson:, toc_location: strand) }
    let(:section)  { create(:section) }
    let(:student)  { create(:student) }

    it 'allows ChangedEarnedScoreNotifications to be dispatched via association extension' do
      activity.notifications.dispatch('ChangedEarnedScore', { section:, user: student,
                                                              old_points_earned: 10.0,
                                                              new_points_earned: 40.0,
                                                              points_possible: 70 })
      notification = activity.notifications.first
      expect(notification.class).to eql ChangedEarnedScoreNotification
      expect(notification.activity_id).to eql activity.id
      expect(notification.user).to eql student
      expect(notification.section).to eql section
    end
  end

  describe '#create_changed_earned_points_notification' do
    it 'dispatches a new ChangedEarnedScoreNotification, passing the specified params' do
      activity = build_stubbed(:activity, lesson: nil)
      section  = build_stubbed(:section)
      student  = build_stubbed(:student)
      params = { section:, user: student, old_points_earned: 10.0,
                 new_points_earned: 40.0, points_possible: 70 }
      expect(activity.notifications).to receive(:dispatch).with('ChangedEarnedScore',
                                                                hash_including(params))
      activity.create_changed_earned_points_notification(params)
    end
  end

  it 'creates a new instance given valid attributes' do
    expect do
      allow_any_instance_of(Activity).to receive(:content_object).and_return nil
      activity = create(:activity)
      expect(activity.errors.empty?).to eql(true)
    end.to change(Activity, :count)
  end

  it 'requires cms_revision_id' do
    expect do
      activity = build(:activity, cms_revision_id: nil)
      activity.save
      expect(activity.errors[:cms_revision_id]).not_to be_nil
    end.not_to change(Activity, :count)
  end

  describe 'saving denormalized data values on create' do
    let(:parser) do
      double(
        'MaestroActivityEngine::ActivityParser',
        class: MaestroActivityEngine::ActivityParser,
        errors: {},
        warnings: []
      )
    end

    def mock_parser(content_object)
      allow(parser).to receive(:parse).and_return(content_object)
      allow(MaestroActivityEngine::ActivityParser).to receive(:create_parser).and_return(parser)
    end

    it 'sets activity_type from content object' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
        activity_type: 'open_ended',
        grading_method: 'instructor',
        has_vhl_image: true,
        points_possible: 40,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: true,
        references: []
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)
      expect(activity.content_object.references).to eq([])
    end

    it 'returns references from content object' do
      reference = double('MaestroActivityEngine::ActivityContent::Reference::Base')
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
        activity_type: 'open_ended',
        grading_method: 'instructor',
        has_vhl_image: true,
        points_possible: 40,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: true,
        references: [reference]
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)
      expect(activity.activity_type).to eql('open_ended')
      expect(activity.content_object.references).to eq([reference])
    end

    context 'when setting points_possible' do
      let(:activity) { create(:activity, activity_type:) }

      before do
        mock_parser(content_object)
      end

      context 'when the activity is not a smart_book activity' do
        let(:activity_type) { 'open_ended' }
        let(:content_object) do
          double(
            'MaestroActivityEngine::ActivityContent',
            class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
            activity_type:,
            grading_method: 'instructor',
            has_vhl_image: true,
            points_possible: 40,
            content_summary: '',
            has_rubric?: false,
            max_attempts: 1,
            submittable?: true,
            randomizable?: true
          )
        end

        it 'sets the points_possible from the content object' do
          allow(content_object).to receive(:has_image?).and_return(true)
          expect(activity.points_possible).to eq(40)
        end

        it 'sets points_possible to 1 if submittable is false' do
          allow(content_object).to receive(:has_image?).and_return(true)
          allow(content_object).to receive(:submittable?).and_return(false)
          allow(content_object).to receive(:points_possible).and_return(0)
          expect(activity.points_possible).to eq(1)
        end
      end

      context 'when the activity is a smart_book activity,' do
        let(:activity_type) { 'smart_book' }
        let(:content_object) do
          double(
            'MaestroActivityEngine::ActivityContent',
            class: 'MaestroActivityEngine::ActivityContent::SmartBookContent',
            activity_type:,
            grading_method: 'instructor',
            has_vhl_image: true,
            points_possible: 40,
            content_summary: '',
            has_rubric?: false,
            max_attempts: 1,
            submittable?: true,
            randomizable?: true
          )
        end

        it 'sets the points_possible from the content object' do
          allow(content_object).to receive(:has_image?).and_return(true)
          expect(activity.points_possible).to eq(40)
        end

        it 'sets points_possible to 1 if submittable is false' do
          allow(content_object).to receive(:has_image?).and_return(true)
          allow(content_object).to receive(:submittable?).and_return(false)
          allow(content_object).to receive(:points_possible).and_return(0)
          expect(activity.points_possible).to eq(1)
        end
      end

      context 'when the activity has a rubric' do
        let(:activity_type) { 'solo_video_recording' }
        let(:content_object) do
          # 90 points: max rubric points for solo_video_recording_with_rubric.xml
          xml = File.new('spec/fixtures/xml/solo_video_recording_with_rubric.xml')
          content_object_from_xml(xml)
        end

        it 'sets the points possible from the max rubric points' do
          expect(activity.points_possible).to eq 90
        end
      end
    end

    it 'sets the content_summary from the content object' do
      activity = build_activity('../fixtures/xml/open_ended.xml')
      activity.save!
      expect(activity.content_summary).to eq(open_ended: 4)
    end

    it 'sets grading_method from content object' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
        activity_type: 'open_ended',
        grading_method: 'instructor',
        has_vhl_image: true,
        points_possible: 40,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: true
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)
      expect(activity.grading_method).to eql('instructor')
    end

    it 'sets minutes_to_complete' do
      activity = build_activity('../fixtures/xml/open_ended.xml')
      activity.save!
      expect(activity.minutes_to_complete).to eq 8
    end

    context 'when the activity type changes' do
      include FakeFS::SpecHelpers

      it 'updates the denormalized activity_type, minutes_to_complete, and points_possible' do
        FakeFS::FileSystem.clone File.join(Rails.root, 'spec/fixtures')
        FakeFS::FileSystem.clone File.join('datafiles',
                                           "#{Rails.env}#{ENV.fetch('TEST_ENV_NUMBER', nil)}")

        example_xml = File.join(Rails.root, 'spec/fixtures/xml/open_ended.xml')
        activity = build(:activity, cms_revision_id: 123_456)
        destination = File.join(activity.content_filepath)
        copy_xml(example_xml, destination)
        activity.save

        expect(activity.activity_type).to eq 'open_ended'
        expect(activity.points_possible).to eq 40
        expect(activity.minutes_to_complete).to eq 8

        activity = Activity.last
        activity.cms_revision_id += 1

        example_xml = File.join(Rails.root, 'spec/fixtures/xml/multiple_choice.xml')
        destination = File.join(activity.content_filepath)
        copy_xml(example_xml, destination)
        activity.save

        expect(activity.activity_type).to eq 'multiple_choice'
        expect(activity.points_possible).to eq 8
        expect(activity.minutes_to_complete).to eq 4
      end
    end

    context 'when activity is an assessment and has a strand,' do
      it 'sets singular_label to the singular_label of the strand' do
        strand = create(:toc_entry)
        allow(strand).to receive(:singular_label).and_return('expected_label')
        lesson = create(:lesson, toc_entries: [strand])
        concept = create(:concept, assessment: true)
        activity = create(
          :activity,
          lesson:,
          toc_location: strand.location,
          concept:
        )
        expect(activity.singular_label).to eql 'expected_label'
      end
    end

    context 'when activity is not an assessment,' do
      it 'does not change singular_label from the default' do
        strand = create(:toc_entry)
        allow(strand).to receive(:singular_label).and_return('some_other_label')
        lesson = create(:lesson, toc_entries: [strand])
        concept = create(:concept, assessment: false)
        activity = create(
          :activity,
          lesson:,
          toc_location: strand.location,
          concept:
        )
        expect(activity.singular_label).to eql 'activity'
      end
    end

    context 'when activity does not have a strand,' do
      it 'does not change singular_label from the default' do
        strand = create(:toc_entry)
        allow(strand).to receive(:singular_label).and_return('some_other_label')
        lesson = create(:lesson, toc_entries: [strand])
        concept = create(:concept, assessment: true)

        activity = create(:activity, toc_location: nil, lesson:, concept:)
        expect(activity.singular_label).to eq 'activity'
      end
    end

    it 'sets randomizable from content object' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::ExamContent',
        activity_type: 'exam',
        grading_method: 'instructor',
        has_vhl_image: true,
        points_possible: 40,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)
      expect(activity.randomizable).to be(false)
    end
  end

  describe '#a11y_issues' do
    let(:activity) { build_stubbed(:activity) }
    let(:issues) { { AccessibilityIssue: 1 } }
    let(:content) do
      instance_double('MaestroActivityEngine::ActivityContent::Content',
                      a11y_issues: issues)
    end

    it 'returns an empty hash when content_object is nil.' do
      allow(activity).to receive(:content_object).and_return nil
      expect(activity.a11y_issues).to eql({})
    end

    it 'returns the accesibility issues if the content object is not nil.' do
      allow(activity).to receive(:content_object).and_return(content)
      expect(activity.a11y_issues).to eql(issues)
    end
  end

  describe '#has_sub_activities?' do
    let(:content_object) do
      instance_double(MaestroActivityEngine::ActivityContent::Content)
    end

    let(:activity) { build_stubbed(:activity) }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
    end

    it 'is true when the content object has sub activities' do
      allow(content_object).to receive(:activities).and_return([1])

      expect(activity).to have_sub_activities
    end

    it 'is false when the content object has no sub activities' do
      allow(content_object).to receive(:activities).and_return([])

      expect(activity).not_to have_sub_activities
    end
  end

  describe '#standards_test' do
    let(:activity) { build(:activity) }
    let(:exam) { build(:activity, activity_type: 'exam') }
    let(:standards_exam) { build(:activity, activity_type: 'exam') }

    before do
      allow(activity).to receive(:questions).and_return(
        [double('Question'), double('Question'), double('Question')]
      )
      allow(exam).to receive(:questions).and_return(
        [double('Question'), double('Question'), double('Question')]
      )
      allow(standards_exam).to receive(:questions).and_return(
        [
          double('Question', question_guid: 'question-guid-1'),
          double('Question', question_guid: 'question-guid-2'),
          double('Question', question_guid: 'question-guid-3')
        ]
      )
    end

    it 'returns true when an exam has question_guids assigned' do
      expect(standards_exam).to be_standards_test
    end

    it 'returns false for an exam with no question_guids' do
      expect(exam).not_to be_standards_test
    end

    it 'returns false for a "regular" activity' do
      expect(activity).not_to be_standards_test
    end
  end

  describe '#proficiency_assessment?' do
    let(:proficiency_assessment_concept) { create(:concept, name: 'Proficiency Assessment') }
    let(:prog_monitor_assessment_concept) { create(:concept, name: 'Progress Monitoring Assessment') }
    let(:activity) { build(:activity) }
    let(:exam) { build(:activity, activity_type: 'exam') }
    let(:proficiency_assessment) { build(:activity, activity_type: 'exam', concept: proficiency_assessment_concept) }
    let(:prog_monitor_assessment) { build(:activity, activity_type: 'exam', concept: prog_monitor_assessment_concept) }

    before do
      allow(activity).to receive(:questions).and_return(
        [ double('Question'), double('Question'), double('Question') ]
      )
      allow(exam).to receive(:questions).and_return(
        [ double('Question'), double('Question'), double('Question') ]
      )
      allow(prog_monitor_assessment).to receive(:questions).and_return(
        [
          double('Question', question_guid: 'question-guid-4'),
          double('Question', question_guid: 'question-guid-5'),
          double('Question', question_guid: 'question-guid-6')
        ]
      )
      allow(proficiency_assessment).to receive(:questions).and_return(
        [
          double('Question', question_guid: 'question-guid-1'),
          double('Question', question_guid: 'question-guid-2'),
          double('Question', question_guid: 'question-guid-3')
        ]
      )
    end

    it 'returns true when a standards exam is a proficiency assessment' do
      expect(proficiency_assessment).to be_proficiency_assessment
    end

    it 'returns false for a standards exam that is not a proficiency assessment' do
      expect(prog_monitor_assessment).to_not be_proficiency_assessment
    end

    it 'returns false for a non-standards exam' do
      expect(exam).to_not be_proficiency_assessment
    end

    it 'returns false for a "regular" activity' do
      expect(activity).to_not be_proficiency_assessment
    end
  end

  describe '#has_study_plan?' do
    it 'returns true with a diagnostic_v2 activity type' do
      diagnostic_v2_activity = create(:activity, activity_type: 'diagnostic_v2')
      expect(diagnostic_v2_activity.has_study_plan?).to be true
    end

    it 'returns true with a study_plan_practice_test activity type' do
      study_plan_pt_activity = create(:activity, activity_type: 'study_plan_practice_test')
      expect(study_plan_pt_activity.has_study_plan?).to be true
    end

    it 'returns false with non diagnostic v2 or study plan practice test type' do
      open_ended_activity = create(:activity, activity_type: 'open_ended')
      expect(open_ended_activity.has_study_plan?).to be false
    end
  end

  describe '#has_summative_study_plan?' do
    context 'with a Diagnostic V2 summative activity' do
      let(:diagnostic_v2_activity) { create(:activity, activity_type: 'diagnostic_v2') }
      let(:content_object) { instance_double('ContentObject') }

      before do
        allow(diagnostic_v2_activity).to receive(:content_object).and_return(content_object)
      end

      it 'returns true when there are formative activities' do
        allow(content_object).to receive(:formative_activities).and_return([{}])
        expect(diagnostic_v2_activity.has_summative_study_plan?).to be true
      end

      it 'returns false when there are not formative activities' do
        allow(content_object).to receive(:formative_activities).and_return([])
        expect(diagnostic_v2_activity.has_summative_study_plan?).to be false
      end
    end

    it 'returns true with a Study Plan Practice Test activity' do
      activity = create(:activity, activity_type: 'study_plan_practice_test')
      expect(activity.has_summative_study_plan?).to be true
    end

    it 'returns false when it is not in the list of study plan activities' do
      activity = create(:activity, activity_type: 'open_ended')
      expect(activity.has_summative_study_plan?).to be false
    end
  end

  describe '#has_composition_activities?' do
    let(:activity) { create(:activity) }
    let(:sub_activity_1) { MaestroActivityEngine::ActivityContent::FillInTheBlanksContent.new }
    let(:sub_activity_2) { MaestroActivityEngine::ActivityContent::CompositionContent.new }
    let(:content_object) { double('ContentObject') }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
    end

    it 'returns true when there is a composition activity' do
      allow(content_object).to receive(:activities).and_return([sub_activity_1, sub_activity_2])
      expect(activity.has_composition_activities?).to eql(true)
    end

    it 'returns false when there is not a composition activity' do
      allow(content_object).to receive(:activities).and_return([sub_activity_1])
      expect(activity.has_composition_activities?).to eql(false)
    end
  end

  describe '#available_in_course?' do
    let(:activity) { create(:activity, component_name: 'Practice') }
    let(:program) { build_stubbed(:program) }
    let(:course) { build_stubbed(:course, program:) }

    it "returns false when the activity's component is not in the course's components" do
      expect(program).to receive(:components).and_return([])
      expect(activity.available_in_course?(course)).to be_falsey
    end

    it "returns true when the activity's component is contained in the course's components" do
      expect(program).to receive(:components).and_return(['Practice'])
      expect(activity.available_in_course?(course)).to be_truthy
    end
  end

  describe '#items_count' do
    let(:activity) { build_stubbed(:activity) }

    it 'returns the sum of all the individual sub activity counts, if content summary is available' do
      allow(activity).to receive(:content_summary).and_return({ open_ended: 4, recording: 2 })
      expect(activity.items_count).to eql(6)
    end
  end

  describe '#content_summary' do
    it 'returns a frequency count hash for the question types in the activity' do
      # fixture creates content object with 4 open ended questions
      activity = build_activity('../fixtures/xml/open_ended.xml')
      activity.save!
      expect(activity.content_summary).to eq({ open_ended: 4 })
    end

    it 'returns an empty hash if there is no content summary for an activity' do
      activity = Activity.new
      expect(activity.content_summary).to eq({})
    end
  end

  describe '#question_summary' do
    let(:activity) { build_stubbed(:activity) }

    it 'discards dictionary_entries summary' do
      content_summary = { open_ended: 4, recording: 2, dictionary_entries: 'word 1, word 2' }
      allow(activity).to receive(:content_summary).and_return(content_summary)
      content_summary.delete(:dictionary_entries)
      expect(activity.question_summary).to eq(content_summary)
    end
  end

  describe '#question_summary_count' do
    let(:activity) { build_stubbed(:activity) }

    it 'does not count dictionary_entries summary' do
      content_summary = { open_ended: 4, recording: 2, dictionary_entries: 'word 1, word 2' }
      allow(activity).to receive(:content_summary).and_return(content_summary)
      content_summary.delete(:dictionary_entries)
      expect(activity.question_summary_count).to eql(6)
    end
  end

  describe '#dictionary_words_list' do
    let(:activity) { build_stubbed(:activity) }

    it 'returns dictionary_entries summary only' do
      content_summary = { open_ended: 4, recording: 2, dictionary_entries: 'word 1, word 2' }
      allow(activity).to receive(:content_summary).and_return(content_summary)
      expected_word_list = content_summary[:dictionary_entries]
      expect(activity.dictionary_words_list).to eq(expected_word_list)
    end
  end

  describe '#max_attempts' do
    it 'returns the maximum attempts for the activity' do
      # fixture creates content object with 4 open ended questions
      activity = build_activity('../fixtures/xml/open_ended.xml')
      activity.save!
      expect(activity.max_attempts).to eql 1
    end
  end

  describe '#submittable' do
    it 'returns whether or not the activity is submittable' do
      # fixture creates content object with 4 open ended questions
      activity = build_activity('../fixtures/xml/open_ended.xml')
      activity.save!
      expect(activity.submittable?).to be_truthy
    end
  end

  describe '#partner_chat?' do
    let(:activity) { build_stubbed(:activity, activity_type: 'partner_chat') }

    it 'returns true if the activity is a partner chat activity' do
      expect(activity.partner_chat?).to eq(true)
    end

    it 'returns true if the activity is a info gap partner chat activity' do
      allow(activity).to receive(:activity_type).and_return('info_gap_partner_chat')
      expect(activity.partner_chat?).to eq(true)
    end

    it 'returns true if the activity is a info gap partner chat v2 activity' do
      allow(activity).to receive(:activity_type).and_return('info_gap_partner_chat_v2')
      expect(activity.partner_chat?).to eq(true)
    end

    it 'returns false if the activity is not a partner chat activity' do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(activity.partner_chat?).to eq(false)
    end
  end

  describe '#solo_video_recording?' do
    let(:activity) do
      build_stubbed(:activity, activity_type: 'solo_video_recording')
    end

    it 'returns true if the activity is a solo video recording activity' do
      expect(activity.solo_video_recording?).to eq(true)
    end

    it 'returns false if the activity is not a solo video recording activity' do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(activity.solo_video_recording?).to eq(false)
    end
  end

  describe '#show_rubric?' do
    context 'when activity has a rubric' do
      let(:rubric_activity) do
        build_stubbed(:activity, activity_type: 'solo_video_recording', has_rubric: true)
      end

      it 'returns true when activity is in the rubric type list' do
        allow(rubric_activity).to receive(:activity_type).and_return('solo_video_recording')
        expect(rubric_activity.show_rubric?).to be true
      end

      it 'returns false when activity is not in the rubric type list' do
        allow(rubric_activity).to receive(:activity_type).and_return('no_in_list')
        expect(rubric_activity.show_rubric?).to be false
      end
    end

    it 'returns false when activity has no rubric' do
      no_rubric_activity = build_stubbed(:activity, activity_type: 'solo_video_recording',
                                                    has_rubric: false)
      allow(no_rubric_activity).to receive(:activity_type).and_return('solo_video_recording')
      expect(no_rubric_activity.show_rubric?).to be false
    end
  end

  describe '#english?' do
    let(:spanish_activity) { create(:activity) }
    let(:english_activity) { create(:activity) }
    let(:english_program) { create(:program, language_code: 'en') }

    it 'returns true if the activity program language code is english' do
      allow(english_activity).to receive(:program).and_return(english_program)
      expect(english_activity.english?).to eq(true)
    end

    it 'returns false if the activity program language code is not english' do
      expect(spanish_activity.english?).to eq(false)
    end

    context 'when the activity is a question bank' do
      let!(:question_bank_topic_english) { create(:question_bank_topic, language: 'english') }
      let!(:question_bank_topic_spanish) { create(:question_bank_topic, language: 'spanish') }
      let(:json) do
        File.read(
          File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
        )
      end

      let!(:question_bank_english) do
        create(
          :question_bank,
          content_json: json,
          question_bank_topic: question_bank_topic_english,
          upload_filename: 'fake_file.csv'
        )
      end

      let!(:question_bank_spanish) do
        create(
          :question_bank,
          content_json: json,
          question_bank_topic: question_bank_topic_spanish,
          upload_filename: 'fake_file.csv'
        )
      end

      it 'returns true if the question bank topic language is english' do
        expect(question_bank_english.english?).to eq(true)
      end

      it 'returns false if the question bank topic language is not english' do
        expect(question_bank_spanish.english?).to eq(false)
      end
    end
  end

  describe '#group_chat?' do
    let(:activity) { build_stubbed(:activity, activity_type: 'group_chat') }

    it 'returns true if the activity is a group chat activity' do
      expect(activity.group_chat?).to eq(true)
    end

    it 'returns false if the activity is not a group_chat activity' do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(activity.group_chat?).to eq(false)
    end
  end

  describe '#chat_or_recording?' do
    it 'returns true if the activity is a partner chat activity' do
      activity = build_stubbed(:activity, activity_type: 'partner_chat')
      expect(activity.chat_or_recording?).to eq(true)
    end

    it 'returns true if the activity is a virtual chat activity' do
      activity = build_stubbed(:activity, activity_type: 'virtual_chat')
      expect(activity.chat_or_recording?).to eq(true)
    end

    it 'returns true if the activity is a video virtual chat activity' do
      activity = build_stubbed(:activity, activity_type: 'video_virtual_chat')
      expect(activity.chat_or_recording?).to eq(true)
    end

    it 'returns true if the activity is a recording_v2 activity' do
      activity = build_stubbed(:activity, activity_type: 'recording_v2')
      expect(activity.chat_or_recording?).to eq(true)
    end

    it 'returns true if the activity is a solo video recording activity' do
      activity = build_stubbed(:activity, activity_type: 'solo_video_recording')
      expect(activity.chat_or_recording?).to eq(true)
    end

    it 'returns false if the activity is not a chat or recording activity' do
      activity = build_activity('../fixtures/xml/open_ended.xml')
      expect(activity.chat_or_recording?).to eq(false)
    end

    it 'returns true if the activity is a multipart with a solo video recording activity' do
      multipart_activity = build_activity('../fixtures/xml/exam_activity_with_solo_video.xml')
      multipart_activity.save!
      expect(multipart_activity.chat_or_recording?).to eq(true)
    end

    it 'returns false if the activity is a multi_type without a solo video recording activity' do
      multipart_activity = build_activity('../fixtures/xml/exam.xml')
      multipart_activity.save!
      expect(multipart_activity.chat_or_recording?).to eq(false)
    end
  end

  describe '#multi_type?' do
    let(:activity) { build_stubbed(:activity, activity_type: 'multi_type') }

    it 'returns true if the activity is a multi type activity' do
      expect(activity).to be_multi_type
    end

    it 'returns false if the activity is not a multi_type activity' do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(activity).not_to be_multi_type
    end
  end

  describe '#has_standards?' do
    it 'returns true if the activity has standards' do
      activity = build_stubbed(:activity)
      standard_asset = build_stubbed(:standard_asset)
      standard = create(:standard)
      allow(activity).to receive(:standard_asset).and_return(standard_asset)
      standard_alignment = create(:standard_alignment, standard_asset:,
                                                       vendor_standard_guid: standard.vendor_guid)
      expect(activity.has_standards?).to be(true)
    end

    it 'returns false if the activity does not have standards' do
      no_standard_activity = build_stubbed(:activity)
      no_standard_asset = build_stubbed(:standard_asset)
      allow(no_standard_activity).to receive(:no_standard_asset).and_return(no_standard_asset)
      expect(no_standard_activity.has_standards?).to be(false)
    end
  end

  describe '#direction_line' do
    it 'returns nil if the content_object has no direction line' do
      activity = create(:activity)
      content = double('MaestroActivityEngine::ActivityContent',
                       class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent')
      allow(content).to receive(:dl).and_return(nil)
      allow(activity).to receive(:content_object).and_return(content)
      expect(activity.direction_line).to be_nil
    end

    it 'returns the direction line from the content_object as html' do
      doc = Nokogiri::XML::Document.new
      dl = Nokogiri::XML::Node.new('dl', doc)
      b = Nokogiri::XML::Node.new('b', doc)
      b.content = 'direction line'
      dl.add_child(b)
      activity = create(:activity)
      content = double('MaestroActivityEngine::ActivityContent',
                       class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent')
      allow(content).to receive(:dl).and_return(dl)
      allow(activity).to receive(:content_object).and_return(content)
      expect(activity.direction_line).to eql '<b>direction line</b>'
    end
  end

  describe '#media_lookup' do
    let(:activity_content_prefix) { MaestroActivityEngine::ActivityContent }

    let(:activity_1_content_object) do
      instance_double(
        activity_content_prefix::RecordingV2Content,
        audio_links: [],
        image_links: [],
        references: [],
        video_links: []
      )
    end

    let(:activity_2_content_object) do
      instance_double(
        activity_content_prefix::RecordingV2Content,
        audio_links: [],
        image_links: [],
        references: [],
        video_links: []
      )
    end

    let(:exam_content_object) do
      instance_double(
        activity_content_prefix::ExamContent,
        activities: [activity_1_content_object, activity_2_content_object],
        activity_type: 'exam'
      )
    end

    let(:text_ref) { activity_content_prefix::Reference::Text.new }

    let(:activity) { described_class.new({ activity_type: 'exam' }) }

    before do
      allow(activity).to receive(:content_object).and_return(exam_content_object)
    end

    context 'with activities with image references,' do
      let(:image_media_item_1) { build_stubbed(:media_item_image) }
      let(:image_media_item_2) { build_stubbed(:media_item) }

      let(:image_link_1) do
        instance_double(MediaLink, media_item: image_media_item_1)
      end

      let(:image_link_2) do
        instance_double(MediaLink, media_item: image_media_item_2)
      end

      let(:image_ref_1) do
        activity_content_prefix::Reference::Image.new(image: image_link_1)
      end

      let(:image_ref_2) do
        activity_content_prefix::Reference::Image.new(image: image_link_2)
      end

      before do
        allow(activity_1_content_object).to receive(:references)
          .and_return([image_ref_1, image_ref_2])
        allow(activity_2_content_object).to receive(:references)
          .and_return([image_ref_2, text_ref])
      end

      it 'returns a de-duped hash of media item ids and their public filenames ' \
         'from any image references in the sub-activities of an exam' do
        expect(activity.media_lookup).to eq(
          image_media_item_1.id => {
            src: image_media_item_1.public_filename, transcript: nil
          },
          image_media_item_2.id => {
            src: image_media_item_2.public_filename, transcript: nil
          }
        )
      end

      it 'ignores any references without a media link or with media links ' \
         'that have no media item' do
        allow(image_ref_1).to receive(:image).and_return(nil)
        allow(image_ref_2.image).to receive(:media_item).and_return(nil)

        expect(activity.media_lookup).to eq({})
      end

      context 'with subactivities with video links,' do
        let(:video_media_item_1) { build_stubbed(:media_item_video) }
        let(:video_media_item_2) { build_stubbed(:media_item) }

        let(:video_link_1) do
          instance_double(MediaLink, media_item: video_media_item_1)
        end

        let(:video_link_2) do
          instance_double(MediaLink, media_item: video_media_item_2)
        end

        before do
          allow(activity_1_content_object).to receive(:references)
            .and_return([])
          allow(activity_2_content_object).to receive(:references)
            .and_return([])
          allow(activity_1_content_object).to receive(:video_links)
            .and_return([video_link_1])
          allow(activity_2_content_object).to receive(:video_links)
            .and_return([video_link_2])
        end

        it 'returns a hash of media item ids and their public filenames from ' \
           'any video links in the questions of the sub-activities of an exam' do
          expect(activity.media_lookup).to eq(
            video_media_item_1.id => {
              src: video_media_item_1.public_filename, transcript: nil
            },
            video_media_item_2.id => {
              src: video_media_item_2.public_filename, transcript: nil
            }
          )
        end

        it 'ignores any media links from questions that have no media item' do
          allow(video_link_2).to receive(:media_item).and_return(nil)

          expect(activity.media_lookup).to eq(
            video_media_item_1.id => {
              src: video_media_item_1.public_filename, transcript: nil
            }
          )
        end
      end

      context 'with subactivities with image links,' do
        before do
          allow(activity_1_content_object).to receive(:references)
            .and_return([])
          allow(activity_2_content_object).to receive(:references)
            .and_return([])
          allow(activity_1_content_object).to receive(:image_links)
            .and_return([image_link_1])
          allow(activity_2_content_object).to receive(:image_links)
            .and_return([image_link_2])
        end

        it 'returns a hash of media item ids and their public filenames from ' \
           'any image links in the questions of the sub-activities of an exam' do
          expect(activity.media_lookup).to eq(
            image_media_item_1.id => {
              src: image_media_item_1.public_filename, transcript: nil
            },
            image_media_item_2.id => {
              src: image_media_item_2.public_filename, transcript: nil
            }
          )
        end

        it 'ignores any media links from questions that have no media item' do
          allow(image_link_2).to receive(:media_item).and_return(nil)

          expect(activity.media_lookup).to eq(
            image_media_item_1.id => {
              src: image_media_item_1.public_filename, transcript: nil
            }
          )
        end
      end

      context 'with subactivities with model references containing images' do
        let(:model_body) do
          Nokogiri::XML(
            "<body><span lang='en'><i>You</i><i> </i><i>see:</i>" \
            "</span><image id='#{image_media_item_1.id}' /></body>"
          )
        end

        let(:model_ref) do
          activity_content_prefix::Reference::Model.new(
            body: model_body
          )
        end

        before do
          MaestroActivityEngine::ActivityParser.linked_media_item_class = linked_media_class
          allow(linked_media_class).to receive(:new).with(
            hash_including(desired_media_item_id: image_media_item_1.id.to_s)
          ).and_return(image_link_1)
          allow(activity_1_content_object).to receive(:references)
            .and_return([model_ref])
          allow(image_ref_1).to receive(:image).and_return(nil)
          allow(image_ref_2.image).to receive(:media_item).and_return(nil)
        end

        it 'returns a hash of media item ids and their public filenames from ' \
           'any image links in the body of the model reference' do
          expect(activity.media_lookup).to eq(
            image_media_item_1.id => {
              src: image_media_item_1.public_filename, transcript: nil
            }
          )
        end
      end
    end

    context 'with activities with audio references or model references ' \
            'with audio,' do
      let(:audio_media_item_1) { build_stubbed(:media_item_audio) }
      let(:audio_media_item_2) { build_stubbed(:media_item) }
      let(:audio_media_item_3) { build_stubbed(:media_item_audio) }

      let(:model_body) do
        Nokogiri::XML(
          '<body><span lang="en"><i>You</i><i> </i><i>see:</i></span></body>'
        )
      end

      let(:audio_ref_1) do
        activity_content_prefix::Reference::Audio.new(
          audio: instance_double(MediaLink, media_item: audio_media_item_1)
        )
      end

      let(:audio_ref_2) do
        activity_content_prefix::Reference::Audio.new(
          audio: instance_double(MediaLink, media_item: audio_media_item_2)
        )
      end

      let(:model_ref) do
        activity_content_prefix::Reference::Model.new(
          audio: instance_double(MediaLink, media_item: audio_media_item_3),
          body: model_body
        )
      end

      before do
        allow(activity_1_content_object).to receive(:references)
          .and_return([audio_ref_1, audio_ref_2, model_ref])
        allow(activity_2_content_object).to receive(:references)
          .and_return([audio_ref_2, text_ref])
      end

      it 'returns a de-duped hash of media item ids and their public filenames ' \
         'from any audio references or model references with audio in the ' \
         'sub-activities of an exam' do
        expect(activity.media_lookup).to eq(
          audio_media_item_1.id => {
            src: audio_media_item_1.public_filename, transcript: nil
          },
          audio_media_item_2.id => {
            src: audio_media_item_2.public_filename, transcript: nil
          },
          audio_media_item_3.id => {
            src: audio_media_item_3.public_filename, transcript: nil
          }
        )
      end

      it 'ignores any references without a media link or with media links ' \
         'that have no media item' do
        allow(audio_ref_1).to receive(:audio).and_return(nil)
        allow(audio_ref_2.audio).to receive(:media_item).and_return(nil)
        allow(model_ref).to receive(:audio).and_return(nil)

        expect(activity.media_lookup).to eq({})
      end
    end

    context 'with activities with video references,' do
      let(:video_media_item_1) { build_stubbed(:media_item_video) }
      let(:video_media_item_2) { build_stubbed(:media_item) }

      let(:video_ref_1) do
        activity_content_prefix::Reference::Video.new(
          video: instance_double(MediaLink, media_item: video_media_item_1)
        )
      end

      let(:video_ref_2) do
        activity_content_prefix::Reference::Video.new(
          video: instance_double(MediaLink, media_item: video_media_item_2)
        )
      end

      before do
        allow(activity_1_content_object).to receive(:references)
          .and_return([video_ref_1, video_ref_2])
        allow(activity_2_content_object).to receive(:references)
          .and_return([video_ref_2, text_ref])
      end

      it 'returns a de-duped hash of media item ids and their public filenames ' \
         'from any video references in the sub-activities of an exam' do
        expect(activity.media_lookup).to eq(
          video_media_item_1.id => {
            src: video_media_item_1.public_filename, transcript: nil
          },
          video_media_item_2.id => {
            src: video_media_item_2.public_filename, transcript: nil
          }
        )
      end

      it 'ignores any references without a media link or with media links ' \
         'that have no media item' do
        allow(video_ref_1).to receive(:video).and_return(nil)
        allow(video_ref_2.video).to receive(:media_item).and_return(nil)

        expect(activity.media_lookup).to eq({})
      end
    end
  end

  describe '#instructor_graded?' do
    let(:activity) { create(:activity) }
    let(:parser) do
      double(
        'MaestroActivityEngine::ActivityParser',
        class: MaestroActivityEngine::ActivityParser,
        errors: {},
        warnings: [],
        parse: nil
      )
    end

    context 'when activity does not have content' do
      it 'does not raise an error and returns false' do
        allow(activity).to receive(:content_summary).and_return({})
        expect(activity).not_to be_instructor_graded
      end
    end

    context 'when activity has content' do
      let(:content) do
        double(
          'MaestroActivityEngine::ActivityContent',
          class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
          activity_type: '',
          grading_method: 'instructor',
          has_vhl_image: true,
          points_possible: 10,
          content_summary: '',
          has_rubric?: false,
          max_attempts: 1,
          submittable?: true,
          randomizable?: false
        )
      end

      before do
        allow(content).to receive(:has_image?).and_return(true)
        allow(parser).to receive(:parse).and_return(content)
        allow(MaestroActivityEngine::ActivityParser).to receive(:create_parser).and_return(parser)
      end

      context 'when activity is of a gradable type' do
        Activity::GRADABLE_ACTIVITY_TYPES.each do |activity_type|
          context "when activity is #{activity_type}" do
            it 'returns true' do
              allow(content).to receive(:activity_type) { activity_type }
              expect(activity).to be_instructor_graded
            end
          end
        end
      end

      context 'when activity is not of a gradable type' do
        before do
          allow(activity).to receive(:activity_type).and_return('multi-type')
        end

        Activity::GRADABLE_QUESTION_TYPES.each do |question_type|
          context "when activity contains #{question_type} questions" do
            it 'returns true' do
              allow(activity).to receive(:content_summary) { { question_type => 2, drop_down: 6 } }
              expect(activity).to be_instructor_graded
            end
          end
        end

        context 'when activity does not have gradable-type questions' do
          it 'returns false' do
            allow(content).to receive(:has_image?).and_return(true)
            allow(activity).to receive(:content_summary).and_return({ drop_down: 6 })
            expect(activity).not_to be_instructor_graded
          end
        end
      end
    end
  end

  describe '#instructor_gradable?' do
    let(:parser) do
      double(
        'MaestroActivityEngine::ActivityParser',
        class: MaestroActivityEngine::ActivityParser,
        errors: {},
        warnings: []
      )
    end

    def mock_parser(content_object)
      allow(parser).to receive(:parse).and_return(content_object)
      allow(MaestroActivityEngine::ActivityParser).to receive(:create_parser).and_return(parser)
    end

    it 'returns true if activity is instructor graded' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
        activity_type: 'open_ended',
        points_possible: 10,
        grading_method: 'instructor',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)

      expect(activity).to be_instructor_gradable
    end

    it 'returns false if activity is recording' do # temporary until we can handle recording activities
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::RecordingContent',
        activity_type: 'recording',
        points_possible: 10,
        grading_method: 'instructor',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      mock_parser(content_object)
      activity = build_stubbed(:activity)

      expect(activity).not_to be_instructor_gradable
    end

    it 'returns true if activity is recording_v2' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::RecordingV2Content',
        activity_type: 'recording_v2',
        points_possible: 10,
        grading_method: 'instructor',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)

      expect(activity).to be_instructor_gradable
    end

    it 'returns true if activity is mixed auto-graded and instructor graded' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::MultiType',
        activity_type: 'multi_type',
        points_possible: 50,
        grading_method: 'mixed',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)

      expect(activity).to be_instructor_gradable
    end

    it 'returns false unless activity is instructor graded or mixed' do
      content_object = double(
        'MaestroActivityEngine::ActivityContent',
        class: 'MaestroActivityEngine::ActivityContent::MapContent',
        activity_type: 'map',
        points_possible: 0,
        grading_method: 'auto',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity)

      expect(activity).not_to be_instructor_gradable
    end

    it 'does not error and returns false if content_object is nil' do
      allow(parser).to receive(:parse).and_return(nil)
      allow(MaestroActivityEngine::ActivityParser).to receive(:create_parser).and_return(parser)
      activity = create(:activity)
      expect(activity).not_to be_instructor_gradable
    end
  end

  describe '#strictness?' do
    let(:parser) do
      double(
        'MaestroActivityEngine::ActivityParser',
        class: MaestroActivityEngine::ActivityParser,
        errors: {},
        warnings: []
      )
    end

    def mock_parser(content_object)
      allow(parser).to receive(:parse).and_return(content_object)
      allow(MaestroActivityEngine::ActivityParser).to receive(:create_parser).and_return(parser)
    end

    it 'returns true if activity is fill in the blanks' do
      content_object = double(
        'MaestroActivityEngine::ActivityParser',
        class: 'MaestroActivityEngine::ActivityContent::FillInTheBlanksContent',
        activity_type: 'fill_in_the_blanks',
        points_possible: 10,
        grading_method: 'auto',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      allow(content_object).to receive(:has_image?).and_return(true)
      mock_parser(content_object)
      activity = create(:activity, activity_type: 'fill_in_the_blanks')
      expect(activity.strictness?).to be true
    end

    it 'returns false if activity is not fill in the blanks' do
      content_object = double(
        'MaestroActivityEngine::ActivityParser',
        class: 'MaestroActivityEngine::ActivityContent::OpenEndedContent',
        activity_type: 'open_ended',
        points_possible: 10,
        grading_method: 'instructor',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: 1,
        submittable?: true,
        randomizable?: false
      )
      mock_parser(content_object)
      activity = build_stubbed(:activity, activity_type: 'open_ended')
      expect(activity.strictness?).to be false
    end

    it 'returns true if activity is interactive_video with a diagnotic' do
      content_object = double(
        'MaestroActivityEngine::ActivityParser',
        class: 'MaestroActivityEngine::ActivityContent::InteractiveVideoContent',
        activity_type: 'interactive_video',
        points_possible: 1,
        grading_method: 'auto',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: nil,
        submittable?: false,
        randomizable?: false,
        has_diagnostic?: true
      )
      mock_parser(content_object)
      activity = build_stubbed(:activity, activity_type: 'interactive_video')
      expect(activity.strictness?).to be true
    end

    it 'returns false if activity is interactive_video without a diagnotic' do
      content_object = double(
        'MaestroActivityEngine::ActivityParser',
        class: 'MaestroActivityEngine::ActivityContent::InteractiveVideoContent',
        activity_type: 'interactive_video',
        points_possible: 1,
        grading_method: 'auto',
        has_vhl_image: true,
        content_summary: '',
        has_rubric?: false,
        max_attempts: nil,
        submittable?: false,
        randomizable?: false,
        has_diagnostic?: false
      )
      mock_parser(content_object)
      activity = build_stubbed(:activity, activity_type: 'interactive_video')
      expect(activity.strictness?).to be false
    end
  end

  describe '#read_only=' do
    it 'sets the read_only instance variable' do
      activity = build_stubbed(:activity)
      expect(activity).not_to be_read_only
      activity.read_only = true
      expect(activity).to be_read_only
    end
  end

  describe '#read_only?' do
    it 'returns false by default' do
      activity = build_stubbed(:activity)
      activity.read_only = nil
      expect(activity).not_to be_read_only
    end

    it 'returns true if read_only is true' do
      activity = build_stubbed(:activity)
      activity.read_only = true
      expect(activity).to be_read_only
    end
  end

  describe '#not_gradable_or_completable?' do
    context 'when an activity is gradable' do
      it 'returns it returns false' do
        allow(activity).to receive(:gradable?).and_return(true)
        expect(activity.not_gradable_or_completable?).to be_falsey
      end
    end

    context 'when an activity is not gradable' do
      before do
        allow(activity).to receive(:gradable?).and_return(false)
      end

      context 'when it is completable' do
        it 'returns false' do
          activity.activity_type = 'hotspots'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'learning_engine'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'quick_check_multiple_choice'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'quick_check_drag_and_drop'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'quick_check_word_ordering'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'quick_check_category_matching'
          expect(activity.not_gradable_or_completable?).to be_falsey
          activity.activity_type = 'vocabulary_tutorial'
          expect(activity.not_gradable_or_completable?).to be_falsey
        end
      end

      context 'when it is not completable' do
        it 'returns true' do
          activity.activity_type = 'enhanced_reading'
          expect(activity.not_gradable_or_completable?).to be_truthy
        end
      end
    end
  end

  describe '#sub_strand' do
    it "returns the sub strand for the activity's TOC Location in the lesson" do
      allow_any_instance_of(Activity).to receive(:content_object).and_return nil
      sub_strand = build_stubbed(:toc_entry)
      lesson = build_stubbed(:lesson)
      activity = create(:activity, lesson:, toc_location: sub_strand.location)
      expect(lesson).to receive(:substrand_for_toc_location).with(sub_strand.location.to_i).and_return(sub_strand)
      expect(activity.sub_strand).to eql sub_strand
    end
  end

  describe '#strand' do
    it "returns the strand for the activity's TOC Location in the lesson" do
      allow_any_instance_of(Activity).to receive(:content_object).and_return nil
      strand = build_stubbed(:toc_entry)
      lesson = build_stubbed(:lesson)
      activity = create(:activity, lesson:, toc_location: strand.location)
      expect(lesson).to receive(:strand_for_toc_location).with(strand.location.to_i).and_return(strand)
      expect(activity.strand).to eql strand
    end
  end

  describe '#lesson_and_strand_label' do
    context 'when the activity has both a strand and a lesson' do
      it 'returns the lesson label and the strand title separated by a pipe' do
        strand = create(:toc_entry, title: 'contextos')

        lesson = create(:lesson, label: 'Lesson 1', toc_entries: [strand],
                        unit: create(:unit))
        activity = create(:activity, lesson:, toc_location: strand.location)
        expect(activity.lesson_and_strand_label).to eql('Lesson 1 | contextos')
      end
    end
  end

  describe '#lesson_strand_label' do
    context 'when there is a strand' do
      it 'returns the activity lesson display name and strand name' do
        allow_any_instance_of(Activity).to receive(:content_object).and_return nil
        strand = create(:toc_entry)

        lesson = create(:lesson, label: 'short_name', toc_entries: [strand],
                                 unit: create(:unit))
        allow(lesson).to receive(:program).and_return(build_stubbed(:program))

        activity = create(:activity, lesson:, toc_location: strand.location)
        expect(activity.lesson_strand_label).to eql strand.name
      end
    end

    context 'when there is no strand,' do
      it 'returns an empty string' do
        strand = create(:toc_entry)
        lesson = create(:lesson, toc_entries: [strand])
        activity = create(:activity, lesson:, toc_location: nil)
        expect(activity.lesson_strand_label).to eql('')
      end
    end
  end

  describe '#reviewable_by_all_questions?' do
    it 'asks its content object whether it is reviewable' do
      activity = build_stubbed(:activity)
      allow(activity).to receive(:content_object)
        .and_return(double('ContentObject', reviewable_by_all_questions?: true))
      expect(activity.content_object).to receive(:reviewable_by_all_questions?)
      activity.reviewable_by_all_questions?
    end
  end

  describe '<=>' do
    let(:activity_1) { build_stubbed(:activity) }
    let(:activity_2) { build_stubbed(:activity) }

    it 'calls compare method' do
      expect(activity_1).to receive(:compare).with(activity_1, activity_2)
      activity_1 <=> activity_2
    end

    it 'sorts put activity_1 before activity_2 if toc locations differ' do
      lesson = create(:lesson_with_toc_entries, unit: create(:unit))

      toc_entry_1 = lesson.toc_entries[0]
      toc_entry_2 = lesson.toc_entries[1]

      activity_1 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_1.location)
      activity_2 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_2.location)

      expect(activity_1 <=> activity_2).to eql(-1)
      expect(activity_2 <=> activity_1).to eql(1)
    end

    it 'puts activity_1 before activity_2 if toc_location_ranks differ' do
      lesson = create(:lesson_with_toc_entries, unit: create(:unit))

      toc_entry_1 = lesson.toc_entries[0]

      activity_1 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_1.location, toc_location_rank: 1)
      activity_2 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_1.location, toc_location_rank: 2)

      expect(activity_1 <=> activity_2).to eql(-1)
      expect(activity_2 <=> activity_1).to eql(1)
    end

    it 'evaluates to 0 if lesson, toc_location and rank are the same' do
      lesson = create(:lesson_with_toc_entries, unit: create(:unit))

      toc_entry_1 = lesson.toc_entries[0]

      activity_1 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_1.location, toc_location_rank: 1)
      activity_2 = build_stubbed(:activity, lesson:,
                                            toc_location: toc_entry_1.location, toc_location_rank: 1)

      expect(activity_1 <=> activity_2).to eql(0)
    end

    it 'sorts activity_1 before activity_2 if units are the same but lesson ranks differ' do
      lesson_1 = create(:lesson_with_toc_entries, rank: 1, unit: create(:unit))
      lesson_2 = create(:lesson_with_toc_entries, rank: 2, unit: create(:unit))

      toc_entry_1 = lesson_1.toc_entries[0]
      toc_entry_2 = lesson_2.toc_entries[0]

      activity_1 = build_stubbed(:activity, lesson: lesson_1,
                                            toc_location: toc_entry_1.location, toc_location_rank: 1)
      activity_2 = build_stubbed(:activity, lesson: lesson_2,
                                            toc_location: toc_entry_2.location, toc_location_rank: 1)

      expect(activity_1 <=> activity_2).to eql(-1)
      expect(activity_2 <=> activity_1).to eql(1)
    end

    it 'sorts activity_1 before activity_2 if unit ranks differ' do
      unit_1 = create(:unit, rank: 1)
      lesson_1 = create(:lesson_with_toc_entries, rank: 0, unit: unit_1)

      unit_2 = create(:unit, rank: 2)
      lesson_2 = create(:lesson_with_toc_entries, rank: 0, unit: unit_2)

      toc_entry_1 = lesson_1.toc_entries[0]
      toc_entry_2 = lesson_2.toc_entries[0]

      activity_1 = build_stubbed(:activity, lesson: lesson_1,
                                            toc_location: toc_entry_1.location, toc_location_rank: 1)
      activity_2 = build_stubbed(:activity, lesson: lesson_2,
                                            toc_location: toc_entry_2.location, toc_location_rank: 1)

      expect(activity_1 <=> activity_2).to eql(-1)
      expect(activity_2 <=> activity_1).to eql(1)
    end
  end

  describe '#assessment?' do
    it 'returns true when activity belongs to an assessment strand' do
      lesson = create(:lesson_with_toc_entries, rank: 1)
      concept = create(:concept, assessment: true)
      toc_entry = lesson.toc_entries[0]
      toc_entry.assessment = true
      activity = create(:activity, lesson:, toc_location: toc_entry.location,
                                   toc_location_rank: 1, concept:)
      expect(activity).to be_assessment
    end

    it "returns false when activity doesn't belong to an assessment strand" do
      concept = create(:concept, assessment: false)
      activity = create(:activity, concept:)
      expect(activity).not_to be_assessment
    end
  end

  describe '#exam?' do
    it 'returns true when activity_type is an exam' do
      lesson = create(:lesson_with_toc_entries, rank: 1)
      concept = create(:concept, assessment: true)
      toc_entry = lesson.toc_entries[0]
      activity = create(:activity, lesson:, toc_location: toc_entry.location,
                                   toc_location_rank: 1, concept:, activity_type: 'exam')
      expect(activity).to be_exam
    end

    it 'returns false when activity_type is not an exam' do
      lesson = create(:lesson_with_toc_entries, rank: 1)
      concept = create(:concept, assessment: true)
      toc_entry = lesson.toc_entries[0]
      activity = create(:activity, lesson:, toc_location: toc_entry.location,
                                   toc_location_rank: 1, concept:, activity_type: 'open_ended')
      expect(activity).not_to be_exam
    end
  end

  describe '#recording_v2?' do
    it 'returns true when activity type is recording_v2' do
      activity = create(:activity, activity_type: 'recording_v2')

      expect(activity).to be_recording_v2
    end

    it 'returns false when activity type is not recording_v2' do
      activity = create(:activity, activity_type: 'open_ended')

      expect(activity).not_to be_recording_v2
    end
  end

  describe '#has_bonus?' do
    let(:activity_with_bonus) { build_activity('../fixtures/xml/diagnostic_with_bonus.xml') }
    let(:multi_type_activity) { build_activity('../fixtures/xml/multi_type.xml') }
    let(:open_ended_activity) { build_activity('../fixtures/xml/open_ended.xml') }

    it 'returns true for a multi-type with a bonus activity' do
      activity_with_bonus.save
      expect(activity_with_bonus.has_bonus?).to be_truthy
    end

    it 'returns false for a multi-type with no bonus activities' do
      multi_type_activity.save
      expect(multi_type_activity.has_bonus?).to be_falsey
    end

    it 'returns false for single type activities' do
      open_ended_activity.save
      expect(open_ended_activity.has_bonus?).to be_falsey
    end
  end

  describe '#filename_from_revision_id' do
    it 'supports long revision ids' do
      filename = Activity.filename_from_revision_id(123_456_789)
      expect(filename).to include('123')
    end
  end

  describe '#is_owner?' do
    let(:instructor) { build_stubbed(:instructor) }

    context 'when activity is not instructor created' do
      it 'is false' do
        activity = build_stubbed(:activity, instructor_id: instructor.id)
        expect(activity.is_owner?(instructor)).to be_falsey
      end
    end

    context 'when activity is instructor created' do
      let(:activity) do
        build_stubbed(:instructor_created_activity_with_non_db_attrs, instructor_id: instructor.id)
      end

      it 'is true when the passed instructor created the activity' do
        expect(activity.is_owner?(instructor)).to be_truthy
      end

      it 'is false when the passed instructor did not create the activity' do
        another_instructor = double(Instructor, id: instructor.id + 1)
        expect(activity.is_owner?(another_instructor)).to be_falsey
      end
    end
  end

  describe '#instructor_created?' do
    context 'when the instance is not of the InstructorCreatedActivity class' do
      it 'is true if instructor_revision_id is not null' do
        instance = described_class.new(instructor_revision_id: 123)

        expect(instance).to be_instructor_created
      end

      it 'is false if instructor_revision_id is null' do
        instance = described_class.new(instructor_revision_id: nil)

        expect(instance).not_to be_instructor_created
      end

      it 'is false if instructor_revision_id is an empty string' do
        instance = described_class.new(instructor_revision_id: '')

        expect(instance).not_to be_instructor_created
      end
    end

    it 'is true if instructor_revision_id is null but the instance is ' \
       'of InstructorCreatedActivity class' do
      instance = InstructorCreatedActivity.new(instructor_revision_id: nil)

      expect(instance).to be_instructor_created
    end
  end

  describe '#question_bank?' do
    context 'when the instance is not of the QuestionBank class' do
      it 'is true if question_bank_revision_id is not null' do
        instance = described_class.new(question_bank_revision_id: 123)

        expect(instance).to be_question_bank
      end

      it 'is false if question_bank_revision_id is null' do
        instance = described_class.new(question_bank_revision_id: nil)

        expect(instance).not_to be_question_bank
      end

      it 'is false if question_bank_revision_id is an empty string' do
        instance = described_class.new(question_bank_revision_id: '')

        expect(instance).not_to be_question_bank
      end
    end

    it 'is true if question_bank_revision_id is null but the instance is ' \
       'of QuestionBank class' do
      instance = QuestionBank.new(question_bank_revision_id: nil)

      expect(instance).to be_question_bank
    end
  end

  describe '#lang_code' do
    context 'when the activity is a question bank' do
      let(:json) do
        File.read(
          File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
        )
      end

      it 'returns the language code of the associated question bank topic' do
        bank_topic = create(:question_bank_topic, language: 'french')
        bank = create(:question_bank, content_json: json, question_bank_topic: bank_topic)

        expect(bank.lang_code).to eq('fr')
      end
    end

    context 'when the activity is not a question bank' do
      it 'returns the language code of the associated program' do
        spanish_activity = create(:activity)
        spanish_program = create(:program, language_code: 'es')
        allow(spanish_activity).to receive(:program).and_return(spanish_program)

        expect(spanish_activity.lang_code).to eq('es')
      end
    end
  end

  describe '#revision_id' do
    it 'returns cms_revision_id if activity has no instructor_revision_id ' \
       'and no question_bank_revision_id' do
      activity = build_stubbed(
        :activity,
        cms_revision_id: 123,
        instructor_revision_id: nil,
        question_bank_revision_id: nil
      )
      expect(activity.revision_id).to eq(activity.cms_revision_id)
    end

    it 'returns the instructor_revision_id of the activity if it has one ' \
       'and has no question_bank_revision_id' do
      activity = build_stubbed(
        :activity,
        cms_revision_id: 123,
        instructor_revision_id: 456,
        question_bank_revision_id: nil
      )
      expect(activity.revision_id).to eq(activity.instructor_revision_id)
    end

    it 'returns the question_bank_revision_id of the activity if it has one' do
      activity = build_stubbed(
        :activity,
        cms_revision_id: 123,
        instructor_revision_id: 456,
        question_bank_revision_id: 789
      )
      expect(activity.revision_id).to eq(activity.question_bank_revision_id)
    end
  end

  describe '#filepath_from_revision_id' do
    context 'when M3 is a live server' do
      it 'does not include datafiles or the rails env in the directory name' do
        allow(Rails.env).to receive(:live?).and_return(true)
        filepath = Activity.filepath_from_revision_id(1)
        expect(filepath).not_to include("datafiles/#{Rails.env}")
      end
    end

    context 'when M3 is NOT a live server' do
      before do
        allow(Rails.env).to receive(:live?).and_return(false)
      end

      it 'includes the rails env in the directory name' do
        filepath = Activity.filepath_from_revision_id(1, instructor_created = false, cdn = false)
        expect(filepath).to include(Rails.env)
      end

      it 'returns the remote filepath if cdn is true' do
        filepath = Activity.filepath_from_revision_id(1, instructor_created = false, cdn = true)
        expect(filepath).not_to include("datafiles/#{Rails.env}")
      end
    end

    it 'returns a directory name of activities when instructor_created arg is false' do
      filepath = Activity.filepath_from_revision_id(1, instructor_created = false)
      expect(filepath).to match(%r{activities/})
    end

    it 'returns a directory name of instructor_activities when instructor_created arg is true' do
      filepath = Activity.filepath_from_revision_id(1, instructor_created = true)
      expect(filepath).to match(%r{instructor_activities/})
    end
  end

  describe '#find_by_cms_activity_id_in_program' do
    let(:program) { create(:program) }
    let(:lesson) { create(:lesson, unit: create(:unit, program:)) }
    let(:cms_activity_id) { (rand * 10_000).to_i }

    it 'returns nil when there is no activity with the specified cms_activity_id in the specified program,' do
      other_program = create(:program)
      other_program_lesson = create(:lesson, unit: create(:unit, program: other_program))
      activity = create(:activity, lesson: other_program_lesson,
                                   cms_activity_id:)
      expect(Activity.find_by_cms_activity_id_in_program(cms_activity_id, program.id)).to be_nil
    end

    context 'when there are multiple activities with the same cms activity id' do
      context 'in different programs,' do
        it 'returns only the activity in the specified program' do
          this_program_activity = create(:activity, lesson:,
                                                    cms_activity_id:)

          other_program = create(:program)
          other_program_lesson = create(:lesson,
                                        unit: create(:unit, program: other_program))
          other_program_activity = create(:activity, lesson: other_program_lesson,
                                                     cms_activity_id:)

          result = Activity.find_by_cms_activity_id_in_program(cms_activity_id, program.id)
          expect(result).not_to eql other_program_activity
          expect(result).to eql this_program_activity
        end
      end

      context 'in the same program,' do
        it 'returns only one of the activities' do
          other_lesson_in_this_program = create(:lesson,
                                                unit: create(:unit, program:))
          this_program_activity_1 = create(:activity, lesson:,
                                                      cms_activity_id:)
          this_program_activity_2 = create(:activity, lesson: other_lesson_in_this_program,
                                                      cms_activity_id:)

          result = Activity.find_by_cms_activity_id_in_program(cms_activity_id, program.id)
          expect(result).to be_an Activity
          expect([this_program_activity_1, this_program_activity_2]).to include result
        end

        context 'and one is deleted' do
          it 'returns the activity that is not deleted' do
            other_lesson_in_this_program = create(:lesson,
                                                  unit: create(:unit, program:))
            this_program_activity_1 = create(:activity, lesson:,
                                                        cms_activity_id:,
                                                        toc_location: nil)
            this_program_activity_2 = create(:activity, lesson:,
                                                        cms_activity_id:)

            result = Activity.find_by_cms_activity_id_in_program(cms_activity_id, program.id)
            expect(result).to eq this_program_activity_2
          end
        end

        context 'and one is unlisted and the other deleted' do
          it 'returns the unlisted activity' do
            this_program_activity_1 = create(:activity, lesson:,
                                                        cms_activity_id:,
                                                        toc_location: nil)
            this_program_activity_2 = create(:activity, lesson:,
                                                        cms_activity_id:,
                                                        toc_location: nil,
                                                        component_name: 'Unlisted')

            result = Activity.find_by_cms_activity_id_in_program(cms_activity_id, program.id)
            expect(result).to eq this_program_activity_2
          end
        end
      end
    end
  end

  describe '#find_by_type_and_id' do
    let(:activity) { double(Activity, id: 123) }

    context 'when type is Activity' do
      it 'uses the Activity model finder' do
        expect(Activity).to receive(:find_by_id).with(activity.id).and_return(activity)
        Activity.find_by_type_and_id(activity.id, 'Activity')
      end
    end

    context 'when type is unknown' do
      it 'raises an error' do
        expect { Activity.find_by_type_and_id(789, 'OtherType') }
          .to raise_error('Unknown activity type OtherType')
      end
    end

    context 'when specified activity type is valid, but id does not match' do
      it 'is nil' do
        expect(Activity.find_by_type_and_id(1, 'ExternalActivity')).to be_nil
      end
    end
  end

  describe '#label' do
    it 'returns the title' do
      activity = create(:activity, title: 'title of an awesome activity')
      expect(activity.label).to eql 'title of an awesome activity'
    end
  end

  describe '#strand_and_title_label' do
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, toc_entries: [strand]) }

    it 'returns the strand name and activity title' do
      allow(lesson).to receive(:program).and_return(build_stubbed(:program))

      activity = create(:activity, lesson:, toc_location: strand.location)
      expect(activity.strand_and_title_label).to eql "#{strand.name.capitalize}: #{activity.title}"
    end

    it 'degrades gracefully if strand is nil' do
      activity = create(:activity, lesson:)
      expect(activity.strand_and_title_label).to eq(activity.title)
    end
  end

  describe '#column_index' do
    it 'returns the activity id in string form' do
      activity = create(:activity)
      expect(activity.column_index).to eql("a#{activity.id}")
    end
  end

  describe '#instructor_graded_questions' do
    before do
      fixture_file = File.join(File.dirname(__FILE__), '../fixtures/xml/open_ended.xml')
      parser = MaestroActivityEngine::ActivityParser.create_parser(File.new(fixture_file),
                                                                   linked_media_class)
      @content = parser.parse
      @activity = build_stubbed(:activity, activity_type: 'open_ended')
      allow(@activity).to receive(:content_object).and_return(@content)
    end

    it 'returns an array of instructor graded questions' do
      results = @activity.instructor_graded_questions
      expect(results).to be_a(Array)
      expect(results.first).to be_a(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
    end

    it 'does not return other question types' do
      @content.items << double(MaestroActivityEngine::ActivityContent::MultipleChoice::Item)
      results = @activity.instructor_graded_questions
      results.each do |question|
        expect(question).to be_a(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
      end
    end

    it 'does not return references' do
      @content.items << double(MaestroActivityEngine::ActivityContent::Reference::Base)
      results = @activity.instructor_graded_questions
      results.each do |question|
        expect(question).to be_a(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
      end
    end

    context 'with multi_type activities' do
      before do
        fixture_file = File.join(File.dirname(__FILE__), '../fixtures/xml/multi_type_with_oe.xml')
        parser = MaestroActivityEngine::ActivityParser.create_parser(File.new(fixture_file),
                                                                     linked_media_class)
        @content = parser.parse
        @activity = build_stubbed(:activity, activity_type: 'multi_type')
        allow(@activity).to receive(:content_object).and_return(@content)
      end

      it 'returns only the intructor gradable questions' do
        results = @activity.instructor_graded_questions
        expect(results).to be_a(Array)
        expect(results.count).to eql 4
        results.each do |question|
          expect(question).to be_a(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
        end
      end

      context 'when it contains table activities' do
        let(:content_prefix) { MaestroActivityEngine::ActivityContent }
        let(:fixture) do
          File.new('spec/fixtures/xml/multi_type_with_table_activities.xml')
        end

        let(:parser) do
          MaestroActivityEngine::ActivityParser.create_parser(
            fixture,
            linked_media_class
          )
        end

        let(:content) { parser.parse }
        let(:activity) { build_stubbed(:activity, activity_type: 'multi_type') }

        before do
          allow(activity).to receive(:content_object).and_return(content)
        end

        it 'returns wols from inline_open_ended tables' do
          results = activity.instructor_graded_questions

          expect(results.count).to eq(2)
          results.all? do |question|
            expect(question).to be_a(
              content_prefix::Question::InlineOpenEndedContent::WriteOnLine
            )
          end
        end
      end
    end

    context 'with recording_v2 activities' do
      let(:fixture_file) do
        File.join(File.dirname(__FILE__), '../fixtures/xml/recording_v2.xml')
      end
      let(:content_object) do
        MaestroActivityEngine::ActivityParser.create_parser(
          File.new(fixture_file), linked_media_class
        ).parse
      end
      let(:activity) do
        build_stubbed(:activity, activity_type: 'recording_v2').tap do |activity|
          allow(activity).to receive(:content_object).and_return(content_object)
        end
      end

      it 'returns only questions for the activity' do
        questions = activity.instructor_graded_questions
        expect(questions.count).to eq(3)
        expect(questions).to all(
          be_a(MaestroActivityEngine::ActivityContent::Recording::Question)
        )
      end
    end

    context 'with virtual_chat activities' do
      let(:activity) { build_stubbed(:activity, activity_type: 'virtual_chat') }

      before do
        fixture_file = File.join(File.dirname(__FILE__), '../fixtures/xml/virtual_chat.xml')
        parser = MaestroActivityEngine::ActivityParser.create_parser(File.new(fixture_file),
                                                                     linked_media_class)
        content = parser.parse
        allow(activity).to receive(:content_object).and_return(content)
      end

      it 'returns only questions for the activity' do
        results = activity.instructor_graded_questions
        expect(results.count).to eql 1
        results.each do |question|
          expect(question).to be_a(MaestroActivityEngine::ActivityContent::VirtualChat::Item)
        end
      end
    end

    context 'with table activities' do
      let(:activity) do
        build_stubbed(:activity, activity_type: 'table_activity')
      end

      before do
        fixture_file = 'spec/fixtures/xml/table_inline_oe.xml'
        parser = MaestroActivityEngine::ActivityParser.create_parser(
          File.new(fixture_file),
          linked_media_class
        )
        content = parser.parse

        allow(activity).to receive(:content_object).and_return(content)
        allow(activity).to receive(:content_summary).and_return({ inline_open_ended: 1 })
      end

      it 'returns only wols for the activity' do
        results = activity.instructor_graded_questions
        expect(results.count).to eq(4)
        results.each do |question|
          expect(question).to be_a(
            MaestroActivityEngine::ActivityContent::Question::InlineOpenEndedContent::WriteOnLine
          )
        end
      end
    end
  end

  describe '#question_like_items' do
    before do
      @activity = build_stubbed(:activity)
    end

    context 'activities without sub activities' do
      context 'content with questions' do
        before do
          @content_object = double('ContentObject', activities: [])
          allow(@content_object).to receive(:questions).and_return(['question_1'])
          allow(@activity).to receive(:content_object).and_return(@content_object)
        end

        it 'requests the correct question' do
          questions = @activity.question_like_items
          expect(questions).not_to be_nil
          expect(questions).not_to be_empty
          expect(questions.first[:questions]).to eql(['question_1'])
        end
      end

      context 'content without questions method' do
        before do
          @content_object = double('ContentObject', activities: [])

          @item_1 = double('Item_1')
          @item_2 = double('Item_2', question_number: 1)

          allow(@content_object).to receive(:items).and_return([@item_1, @item_2])
          allow(@activity).to receive(:content_object).and_return(@content_object)
        end

        it 'requests the correct question' do
          questions = @activity.question_like_items
          expect(questions).not_to be_nil
          expect(questions).not_to be_empty
          expect(questions.first[:questions]).to eql([@item_2])
        end
      end
    end

    context 'activities with sub activities' do
      context 'content with questions' do
        before do
          @content_object_1 = double('ContentObject')
          @content_object_2 = double('ContentObject')

          allow(@content_object_1).to receive(:questions).and_return(['question_1'])
          allow(@content_object_2).to receive(:questions).and_return(['question_2'])

          @content_object = double('ContentObject',
                                   activities: [@content_object_1, @content_object_2])

          allow(@activity).to receive(:content_object).and_return(@content_object)
        end

        it 'requests the correct question' do
          questions = @activity.question_like_items
          expect(questions).not_to be_nil
          expect(questions).not_to be_empty
          expect(questions.first[:questions]).to eql(['question_1'])
          expect(questions.last[:questions]).to eql(['question_2'])
        end
      end

      context 'content without questions method' do
        before do
          @content_object_1 = double('ContentObject')
          @content_object_2 = double('ContentObject')

          @item_1_1 = double('Item_1')
          @item_1_2 = double('Item_2', question_number: 1)

          @item_2_1 = double('Item_1', question_number: 2)
          @item_2_2 = double('Item_2')

          allow(@content_object_1).to receive(:items).and_return([@item_1_1, @item_1_2])
          allow(@content_object_2).to receive(:items).and_return([@item_2_1, @item_2_2])

          @content_object = double('ContentObject',
                                   activities: [@content_object_1, @content_object_2])

          allow(@activity).to receive(:content_object).and_return(@content_object)
        end

        it 'requests the correct question' do
          questions = @activity.question_like_items
          expect(questions).not_to be_nil
          expect(questions).not_to be_empty
          expect(questions.first[:questions]).to eql([@item_1_2])
          expect(questions.last[:questions]).to eql([@item_2_1])
        end
      end
    end
  end

  describe '#activity_content' do
    let(:activity) { build(:activity) }

    context 'when instructor revision id is nil' do
      it 'returns a CmsActivityContent object' do
        activity.instructor_revision_id = nil
        activity.save
        expect(activity.activity_content).to be_a CmsActivityContent
      end

      it 'passes the program to CmsActivityContent#new' do
        expect(CmsActivityContent)
          .to receive(:new)
          .with(any_args, activity.program)
          .and_call_original

        activity.instructor_revision_id = nil
        activity.save
      end
    end

    it 'returns an InstructorActivityContent object when instructor_revision_id is not nil' do
      activity.instructor_revision_id = 1234
      activity.save
      expect(activity.activity_content).to be_a InstructorActivityContent
    end
  end

  describe '#ensure_correct_version' do
    let(:other_revision_id) { 123 }
    let(:current_revision_id) { 456 }

    context 'when the activity is not gradable,' do
      let(:activity) { create(:activity, cms_revision_id: current_revision_id) }

      before do
        allow(activity).to receive(:gradable?).and_return(false)
        allow(activity.activity_content).to receive(:parse_content)
      end

      it 'does not change the cms_revision_id' do
        activity.ensure_correct_version(other_revision_id)

        expect(activity.cms_revision_id).to eq(current_revision_id)
      end

      it 'does not load content from the specified revision' do
        activity.ensure_correct_version(other_revision_id)

        expect(activity.activity_content).not_to have_received(:parse_content)
      end
    end

    context 'when the activity is gradable,' do
      context 'when the activity is instructor created,' do
        let(:activity) do
          create(:activity, instructor_revision_id: current_revision_id)
        end

        before do
          allow(activity).to receive(:gradable?).and_return(true)
          allow(activity.activity_content).to receive(:parse_content)
        end

        context 'when current revision is the same as desired revision,' do
          it 'does not change the instructor_revision_id' do
            activity.ensure_correct_version(current_revision_id)

            expect(activity.instructor_revision_id).to eq(current_revision_id)
          end

          it 'does not load reload content' do
            activity.ensure_correct_version(current_revision_id)

            expect(activity.activity_content).not_to have_received(:parse_content)
          end
        end

        context 'when current revision is different from desired revision,' do
          let(:new_activity_content) do
            instance_double(
              InstructorActivityContent,
              parse_content: nil,
              content_object: Struct.new(:has_rubric?).new(true)
            )
          end

          before do
            allow(activity).to receive(:activity_content)
              .and_return(new_activity_content)
          end

          it 'changes the instructor_revision_id' do
            activity.ensure_correct_version(other_revision_id)

            expect(activity.instructor_revision_id).to eq other_revision_id
          end

          it 'reloads content' do
            activity.ensure_correct_version(other_revision_id)

            expect(new_activity_content).to have_received(:parse_content)
          end
        end
      end

      context 'when the activity comes from cms,' do
        it 'does not load reload content if the current revision is the ' \
           'same as the desired revision' do
          activity = create(:activity, cms_revision_id: current_revision_id)
          allow(activity).to receive(:gradable?).and_return(true)

          expect(activity.activity_content).not_to receive(:parse_content)
          activity.ensure_correct_version(current_revision_id)
          expect(activity.cms_revision_id).to eq current_revision_id
        end

        it 'loads content if the current revision is different than the ' \
           'desired revision' do
          activity = create(:activity, cms_revision_id: current_revision_id)
          allow(activity).to receive(:gradable?).and_return(true)
          new_activity_content = double(
            CmsActivityContent,
            content_object: Struct.new(:has_rubric?).new(false),
            parse_content: nil
          )
          allow(activity).to receive(:activity_content).and_return(new_activity_content)
          activity.ensure_correct_version(other_revision_id)
          expect(activity.cms_revision_id).to eq other_revision_id
        end

        it 'sets the has_rubric flag if the current revision is different than the ' \
           'desired revision' do
          activity = create(:activity, cms_revision_id: current_revision_id)
          new_activity_content = double(
            CmsActivityContent,
            content_object: Struct.new(:has_rubric?).new(true),
            parse_content: nil
          )
          allow(activity).to receive(:gradable?).and_return(true)
          allow(activity).to receive(:activity_content).and_return(new_activity_content)

          activity.ensure_correct_version(other_revision_id)
          expect(activity).to be_has_rubric
        end
      end

      it 'extends the PreviousRevision module' do
        activity = create(:activity, cms_revision_id: current_revision_id)
        new_activity_content = double(
          CmsActivityContent,
          content_object: Struct.new(:has_rubric?).new(false),
          parse_content: nil
        )
        allow(activity).to receive(:gradable?).and_return(true)
        allow(activity).to receive(:activity_content).and_return(new_activity_content)
        expect(activity).to receive(:extend).with(Activity::PreviousRevision)
        activity.ensure_correct_version(other_revision_id)
      end
    end
  end

  describe '.assigments_on_same_day' do
    let(:activity) { create(:activity) }

    it 'empties array if they are no matching assignments' do
      due_date = Time.now.to_date
      assignment = create(:assignment, assignable: create(:activity), due_date:)
      expect(activity.assigments_on_same_day([assignment], due_date)).to eql []
    end

    it 'returns the assignments that match the activity and day' do
      due_date = Time.now.to_date
      assignment = create(:assignment, assignable: activity, due_date:)
      expect(activity.assigments_on_same_day([assignment], due_date)).to eql [assignment]
    end

    it 'empties array if they activity matches but not the date' do
      due_date = Time.now.to_date
      assignment = create(:assignment, assignable: activity, due_date:)
      expect(activity.assigments_on_same_day([assignment], (due_date + 1.day))).to eql []
    end
  end

  describe '#list_header' do
    before do
      @activity = build_stubbed(:activity)
    end

    context 'with a lesson' do
      before do
        @toc_location = 'quux'
        @lesson = build_stubbed(:lesson)
        allow(@lesson).to receive(:display_name).and_return('lesson foo')
        allow(@activity).to receive(:lesson).and_return(@lesson)
        allow(@activity).to receive(:toc_location).and_return(@toc_location)
      end

      context 'with a strand' do
        before do
          @strand = double('Strand', name: 'strand bar')
          allow(@lesson).to receive(:strand_for_toc_location).with(@toc_location).and_return(@strand)
        end

        context 'with a substrand' do
          before do
            @substrand = double('SubStrand', name: 'substrand baz')
            allow(@lesson).to receive(:substrand_for_toc_location).with(@toc_location).and_return(@substrand)
          end

          it 'returns the lesson, strand and substrand' do
            expect(@activity.list_header).to eql "#{@lesson.display_name} | #{@strand.name} | #{@substrand.name}"
          end
        end

        context 'without a substrand' do
          before do
            allow(@lesson).to receive(:substrand_for_toc_location).and_return(nil)
          end

          it 'returns the lesson and strand' do
            expect(@activity.list_header).to eql "#{@lesson.display_name} | #{@strand.name}"
          end
        end
      end

      context 'without a strand' do
        before do
          allow(@lesson).to receive(:strand_for_toc_location).and_return(nil)
          allow(@lesson).to receive(:substrand_for_toc_location).and_return(nil)
        end

        it 'returns the lesson' do
          expect(@activity.list_header).to eql "#{@lesson.display_name}"
        end
      end
    end

    context 'without a lesson' do
      before do
        allow(@activity).to receive(:lesson).and_return(nil)
      end

      it 'returns an empty string' do
        expect(@activity.list_header).to be_blank
      end
    end
  end

  describe '.humanize_activity_type' do
    it 'converts audio_hotspots' do
      expect(described_class.humanize_activity_type('audio_hotspots')).to eql('Talking picture')
    end

    it 'converts tutorial_vocab' do
      expect(described_class.humanize_activity_type('tutorial_vocab')).to eq('Tutorial vocabulary')
      expect(described_class.humanize_activity_type('tutorial_vocab_html5')).to eq('Tutorial vocabulary')
    end

    it 'strips out _same and _v2 and humanizes' do
      expect(described_class.humanize_activity_type('drop_down_same')).to eql('Drop down')
      expect(described_class.humanize_activity_type('video_V2')).to eql('Video')
    end

    it 'converts solo_video_recording' do
      expect(described_class.humanize_activity_type('solo_video_recording')).to eq 'Video Recording'
    end
  end

  describe '#partner_chat?' do
    let(:activity) { build_stubbed(:activity, activity_type: 'partner_chat') }

    it 'returns true if the activity is a partner chat activity' do
      expect(activity).to be_partner_chat
    end

    it 'returns false if the activity is not a partner chat activity' do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(activity).not_to be_partner_chat
    end
  end

  describe '#composition?' do
    let(:activity) { build_stubbed(:activity) }

    it "is true when activity type is 'composition'" do
      allow(activity).to receive_messages(activity_type: 'composition')
      expect(activity).to be_composition
    end

    it 'is false when activity from another type' do
      allow(activity).to receive_messages(activity_type: 'some_type')
      expect(activity).not_to be_composition
    end
  end

  describe '.find_all_by_toc_location' do
    it 'raises an exception' do
      expect { Activity.find_all_by_toc_location(2) }
        .to raise_error 'Activity.find_all_by_toc_location cannot be called, please use Services::TocActivityList.all_by_toc_location'
    end
  end

  describe '#first_page' do
    let(:activity) { build(:activity) }

    it 'is nil if page attribute is nil' do
      expect(activity.first_page).to be_nil
    end

    it 'is nil if page attribute is blank' do
      activity.page = ''

      expect(activity.first_page).to be_nil
    end

    context 'with no vtext prefix' do
      it 'returns the page attribute if it has no dashes' do
        activity.page = '123'

        expect(activity.first_page).to eq('123')
      end

      it 'returns the first element of the page attribute if it has dashes' do
        activity.page = '12-34'

        expect(activity.first_page).to eq('12')
      end
    end

    context 'with a vtext prefix' do
      it 'returns the page attribute without the vtext prefix if it has no dashes' do
        activity.page = 'v1(123)'

        expect(activity.first_page).to eq('123')
      end

      it 'returns the first element of the page attribute without the vtext ' \
         'prefix if it has dashes' do
        activity.page = 'v10(12-34)'

        expect(activity.first_page).to eq('12')
      end
    end
  end

  describe '#page_range' do
    let(:activity) { build(:activity) }

    it 'returns empty string if page attribute is nil' do
    end

    it 'returns empty string if page attribute is empty' do
    end

    context 'with no vtext prefix' do
      it 'returns the page attribute if it has no dashes' do
        activity.page = '123'

        expect(activity.page_range).to eq('123')
      end

      it 'returns the page attribute if it has dashes' do
        activity.page = '12-34'

        expect(activity.page_range).to eq('12-34')
      end
    end

    context 'with a vtext prefix' do
      it 'returns the page attribute without the vtext prefix if it has no dashes' do
        activity.page = 'v1(123)'

        expect(activity.page_range).to eq('123')
      end

      it 'returns the page attribute without the vtext prefix if it has dashes' do
        activity.page = 'v10(12-34)'

        expect(activity.page_range).to eq('12-34')
      end
    end
  end

  describe '#icon' do
    let(:activity) { build(:activity_with_program) }

    it 'returns the icon field value as is if program is not VOL' do
      activity[:icon] = 'foo,textbook,bar'
      allow(activity.program).to receive(:vista_online_learning).and_return(false)
      expect(activity.icon).to eq 'foo,textbook,bar'
    end

    it 'prepends "vol_" to "textbook" if program is VOL' do
      activity[:icon] = 'foo,textbook,bar'
      allow(activity.program).to receive(:vista_online_learning).and_return(true)
      expect(activity.icon).to eq 'foo,vol_textbook,bar'
    end

    it 'returns "" if the icon field value is nil' do
      activity[:icon] = nil
      expect(activity.icon).to eq ''
    end
  end

  describe '#is_shared_copy?' do
    let(:school) { create(:school) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
    let(:unit) { create(:unit, program:) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:igc_activity) do
      create(:instructor_created_activity, lesson:, toc_entry_id: strand.location)
    end
    let(:shared_activity) do
      create(:instructor_created_activity, lesson:, toc_entry_id: strand.location)
    end
    let(:shared_library_activity) do
      create(:shared_library_activity,
             activity_id: shared_activity.id,
             source_activity: igc_activity,
             school:)
    end

    before do
      create(:concept, lesson:, program:, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
    end

    it 'returns true if the activity is an approved shared igc' do
      shared_library_activity
      shared_library_activity.is_shared = true
      shared_library_activity.save
      expect(shared_activity.is_shared_copy?).to be true
    end

    it 'returns false if the activity is not an approved shared igc' do
      shared_library_activity
      expect(shared_activity.is_shared_copy?).to be false
    end

    it 'returns false if the activity is not a shared igc' do
      expect(igc_activity.is_shared_copy?).to be_falsey
    end
  end

  describe '#is_shared_source?' do
    let(:school) { create(:school) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
    let(:unit) { create(:unit, program:) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:igc_activity) do
      create(:instructor_created_activity, lesson:, toc_entry_id: strand.location)
    end
    let(:shared_library_activity) do
      create(:shared_library_activity,
             source_activity: igc_activity,
             school:)
    end

    before do
      create(:concept, lesson:, program:, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
    end

    it 'returns true if the activity was shared' do
      shared_library_activity
      shared_library_activity.is_shared = true
      shared_library_activity.save
      expect(igc_activity.is_shared_source?).to be true
    end

    it 'returns false if the activity is pending to approve' do
      shared_library_activity
      expect(igc_activity.is_shared_source?).to be false
    end
  end

  describe '#is_pending_share?' do
    let(:school) { create(:school) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
    let(:unit) { create(:unit, program:) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:igc_activity) do
      create(:instructor_created_activity, lesson:, toc_entry_id: strand.location)
    end
    let(:shared_library_activity) do
      create(:shared_library_activity,
             source_activity: igc_activity,
             school:)
    end

    before do
      create(:concept, lesson:, program:, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
    end

    it 'returns true if the activity is pending approval' do
      shared_library_activity
      expect(igc_activity.is_pending_share?).to be true
    end

    it 'returns false if the activity has not been requested to share' do
      expect(igc_activity.is_pending_share?).to be false
    end
  end

  describe '#santillana?' do
    let(:activity) { build_stubbed(:activity, activity_type:) }

    context "when activity type is 'smart_book'" do
      let(:activity_type) { 'smart_book' }

      it 'returns true' do
        expect(activity).to be_santillana
      end
    end

    context "when activity type is 'static_book'" do
      let(:activity_type) { 'static_book' }

      it 'returns true' do
        expect(activity).to be_santillana
      end
    end

    context 'when activity type is another type' do
      let(:activity_type) { 'some_type' }

      it 'returns false' do
        expect(activity).not_to be_santillana
      end
    end
  end

  describe '#student_display_title' do
    it 'returns the lesson display name and concept name if a student title is not set' do
      activity.student_title = nil
      expect(activity.student_display_title).to eq("#{activity.lesson_display_name} | #{activity.concept_name}")
    end

    it 'returns the student title if a student title is set' do
      activity.student_title = 'Student title'
      expect(activity.student_display_title).to eq(activity.student_title)
    end
  end

  describe '#includes_solo_video_recording?' do
    context 'when the activity is a single activity' do
      let(:solo_video_activity) do
        act = build_activity('../fixtures/xml/solo_video_recording.xml')
        act.save!
        act
      end
      let(:partner_chat_activity) do
        act = build_activity('../fixtures/xml/partner_chat.xml')
        act.save!
        act
      end

      it 'returns true when the activity is solo video recording' do
        expect(solo_video_activity.includes_solo_video_recording?).to be true
      end

      it 'returns false when the activity is not solo video recording' do
        expect(partner_chat_activity.includes_solo_video_recording?).to be false
      end
    end

    context 'when the activity is a multipart activity' do
      let(:multi_type_activity_with_svr) do
        act = build_activity('../fixtures/xml/multi_type_activity_with_solo_video.xml')
        act.save!
        act
      end
      let(:exam_activity) do
        act = build_activity('../fixtures/xml/exam_with_multiple_answer.xml')
        act.save!
        act
      end

      it 'returns true when the activity includes a solo video recording subactivity' do
        expect(multi_type_activity_with_svr.includes_solo_video_recording?).to be true
      end

      it 'returns false when the activity does not include a solo video recording subactivity' do
        expect(exam_activity.includes_solo_video_recording?).to be false
      end
    end
  end

  describe '#solo_video_recording_or_included_in_multipart_activity?' do
    let(:solo_video_activity) { create(:activity, activity_type: 'solo_video_recording') }
    let(:partner_chat_activity) { create(:activity, activity_type: 'partner_chat') }

    it 'is true when the activity is a solo video recording' do
      expect(solo_video_activity).to be_solo_video_recording_or_included_in_multipart_activity
    end

    it 'is false when the activity is different from solo video recording or multipart' do
      partner_chat_file = File.join(
        File.dirname(__FILE__),
        '../fixtures/xml/partner_chat.xml'
      )
      parser = MaestroActivityEngine::ActivityParser.create_parser(
        File.new(partner_chat_file),
        linked_media_class
      )
      content = parser.parse
      allow(partner_chat_activity).to receive(:content_object).and_return(content)

      expect(partner_chat_activity).not_to(
        be_solo_video_recording_or_included_in_multipart_activity
      )
    end

    context 'when the activity is a multi_type activity' do
      let(:multi_type_activity) { create(:activity, activity_type: 'multi_type') }

      context 'with a solo video recording activity' do
        before do
          multi_type_with_solo_video_file = File.join(
            File.dirname(__FILE__),
            '../fixtures/xml/multi_type_activity_with_solo_video.xml'
          )
          parser = MaestroActivityEngine::ActivityParser.create_parser(
            File.new(multi_type_with_solo_video_file),
            linked_media_class
          )
          content = parser.parse
          allow(multi_type_activity).to receive(:content_object).and_return(content)
        end

        it 'is true' do
          multi_type_activity.save!
          expect(multi_type_activity).to be_solo_video_recording_or_included_in_multipart_activity
        end
      end

      context 'with an activity different from solo video recording' do
        before do
          multi_type_with_oe_file = File.join(
            File.dirname(__FILE__),
            '../fixtures/xml/multi_type_with_oe.xml'
          )
          parser = MaestroActivityEngine::ActivityParser.create_parser(
            File.new(multi_type_with_oe_file),
            linked_media_class
          )
          content = parser.parse
          allow(multi_type_activity).to receive(:content_object).and_return(content)
        end

        it 'is false' do
          expect(multi_type_activity).not_to(
            be_solo_video_recording_or_included_in_multipart_activity
          )
        end
      end
    end

    context 'when the activity is an exam activity' do
      let(:exam_activity) { create(:activity, activity_type: 'exam') }

      context 'with a solo video recording activity' do
        before do
          exam_with_solo_video_file = File.join(
            File.dirname(__FILE__),
            '../fixtures/xml/exam_activity_with_solo_video.xml'
          )
          parser = MaestroActivityEngine::ActivityParser.create_parser(
            File.new(exam_with_solo_video_file),
            linked_media_class
          )
          content = parser.parse
          allow(exam_activity).to receive(:content_object).and_return(content)
        end

        it 'is true' do
          exam_activity.save!
          expect(exam_activity).to be_solo_video_recording_or_included_in_multipart_activity
        end

        it 'returns include_video_recording? with true' do
          expect(exam_activity.include_video_recording?).to be_truthy
        end

        it 'returns include_audio_recording? with false' do
          expect(exam_activity.include_audio_recording?).to be_falsey
        end
      end

      context 'with an activity different from solo video recording' do
        before do
          exam_with_multiple_answer_file = File.join(
            File.dirname(__FILE__),
            '../fixtures/xml/exam_with_multiple_answer.xml'
          )
          parser = MaestroActivityEngine::ActivityParser.create_parser(
            File.new(exam_with_multiple_answer_file),
            linked_media_class
          )
          content = parser.parse
          allow(exam_activity).to receive(:content_object).and_return(content)
        end

        it 'is false' do
          expect(exam_activity).not_to be_solo_video_recording_or_included_in_multipart_activity
        end
      end
    end
  end

  describe '#include_audio_recording? and #include_video_recording?' do
    context 'when the activity is an exam activity with audio recording' do
      let(:exam_activity) { create(:activity, activity_type: 'exam') }

      context 'with a recording_v2' do
        before do
          exam_with_recording_v2 = File.join(
            File.dirname(__FILE__),
            '../fixtures/xml/recording_v2.xml'
          )
          parser = MaestroActivityEngine::ActivityParser.create_parser(
            File.new(exam_with_recording_v2),
            linked_media_class
          )
          content = parser.parse
          allow(exam_activity).to receive(:content_object).and_return(content)
        end

        it 'returns include_audio_recording? with true' do
          expect(exam_activity.include_audio_recording?).to be_truthy
        end

        it 'returns include_video_recording? with false' do
          expect(exam_activity.include_video_recording?).to be_falsey
        end
      end
    end
  end

  describe '#requires_chat?' do
    let(:non_chat_activity) { described_class.new(activity_type: 'foo') }
    let(:pchat_activity) { described_class.new(activity_type: 'partner_chat') }

    it 'returns false when the activity is not a chat type activity' do
      non_chat_activity = described_class.new(activity_type: 'foo')
      expect(non_chat_activity.requires_chat?).to be false
    end

    it 'returns true when the activity is a partner chat' do
      expect(pchat_activity.requires_chat?).to be true
    end

    it 'returns true when the activity is a group chat' do
      group_chat_activity = described_class.new(activity_type: 'group_chat')
      expect(group_chat_activity.requires_chat?).to be true
    end

    it 'returns true when the activity is an info_gap' do
      info_gap_activity = described_class.new(activity_type: 'info_gap_partner_chat')
      expect(info_gap_activity.requires_chat?).to be true
    end

    it 'returns true when the activity is an info_gap_partner_chat_v2' do
      info_gap_v2_activity = described_class.new(activity_type: 'info_gap_partner_chat_v2')
      expect(info_gap_v2_activity.requires_chat?).to be true
    end
  end
end

describe Activity::PreviousRevision do
  let(:activity) { build_stubbed(:activity) }
  let(:content_object) do
    double('ActivityContent', grading_method: 'robomatic',
                              activity_type: 'real_easy',
                              points_possible: '1 million')
  end

  before do
    allow(activity).to receive(:content_object).and_return(content_object)
    activity.extend(Activity::PreviousRevision)
  end

  describe '#grading_method' do
    it 'obtains the grading method from the content_object' do
      expect(activity.grading_method).to eq(content_object.grading_method)
    end
  end

  describe '#activity_type' do
    it 'obtains the activity type from the content_object' do
      expect(activity.activity_type).to eq(content_object.activity_type)
    end
  end

  describe '#points_possible' do
    it 'obtains the points possible from the content_object' do
      expect(activity.points_possible).to eq(content_object.points_possible)
    end
  end

  describe '#hidden?' do
    let(:sh_course) { create(:course) }
    let(:sh_activity) { create(:activity) }

    context 'when no course_library_activity has been created for that activity' do
      it 'should return false' do
        expect(sh_activity.hidden?(sh_course)).to eq(false)
      end
    end

    context 'when a course_library_activity has been created for that activity and it is hidden' do
      let(:shown_activity_course_library_activity) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: true) }

      it 'should return true' do
        shown_activity_course_library_activity
        expect(sh_activity.hidden?(sh_course)).to eq(true)
      end
    end

    context 'when a course_library_activity has been created for that activity and it is not hidden' do
      let(:shown_activity_course_library_activity) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: false) }

      it 'should return false' do
        shown_activity_course_library_activity
        expect(sh_activity.hidden?(sh_course)).to eq(false)
      end
    end

    context 'when multiple course_library_activities have been created for that activity and the last is not hidden' do
      let(:shown_activity_course_library_activity) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: true) }
      let(:shown_activity_course_library_activity2) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: false) }

      it 'should return false' do
        shown_activity_course_library_activity
        shown_activity_course_library_activity2
        expect(sh_activity.hidden?(sh_course)).to eq(false)
      end
    end

    context 'when multiple course_library_activities have been created for that activity and the last is hidden' do
      let(:shown_activity_course_library_activity) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: false) }
      let(:shown_activity_course_library_activity2) { create(:course_library_activity, course: sh_course, activity: sh_activity, hidden: true) }

      it 'should return false' do
        shown_activity_course_library_activity
        shown_activity_course_library_activity2
        expect(sh_activity.hidden?(sh_course)).to eq(true)
      end
    end
  end

  describe '#creator_name' do
    let(:instructor) do
      create(:instructor, first_name: 'Lolita',
                          last_name: 'Stake',
                          archived: false)
    end
    let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
    let(:unit) { create(:unit, program:) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:igc_activity) do
      create(:instructor_created_activity, lesson:,
                                           toc_entry_id: strand.location,
                                           instructor_id: instructor.id)
    end

    before do
      create(:concept, lesson:, program:, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
    end

    it 'returns the full name of the activity author' do
      expect(igc_activity.creator_name).to eq('Lolita Stake')
    end

    it 'returns the full name of the activity author even if their user record is archived' do
      igc_activity
      instructor.update!(archived: true)
      expect(igc_activity.creator_name).to eq('Lolita Stake')
    end
  end
end
