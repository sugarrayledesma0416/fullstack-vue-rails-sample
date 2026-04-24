describe SharedActivityViewer do
  let(:activity) { create(:activity) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:ruleset) { create(:scoring_ruleset) }
  let(:assignment) { create(:assignment) }
  let(:attempt) { Attempt.new }
  let(:gradebook_api) { GradebookEngine::GradebookAPI }

  # StudentActivityPresenter is used to test the module functionality
  let(:student_presenter) do
    StudentActivityPresenter.new(activity, student, section)
  end

  let(:instructor_presenter) do
    InstructorActivityPresenter.new(activity, instructor, section, course)
  end

  before do
    allow(assignment).to receive(:scoring_ruleset).and_return(ruleset)
    allow(activity).to receive(:content_summary).and_return(Hash[test: 1])
    allow(activity).to receive(:strand_singular_label).and_return('exam')
    allow(activity).to receive(:notifications_by_user_and_section).and_return([])
  end

  describe '#find_or_create_attempt' do
    before do
      allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
        .and_return(attempt)
    end

    context 'when there is no assignment,' do
      before do
        allow(student_presenter).to receive(:assignment).and_return(nil)
      end

      it 'finds or creates an attempt for the current activity, student, and ' \
         'section, with a nil scoring ruleset' do
        student_presenter.find_or_create_attempt
        expect(Attempt).to have_received(:find_or_create_with_scoring_ruleset)
          .with(student, activity, section.id, nil)
      end

      it 'returns the found or created attempt' do
        expect(student_presenter.find_or_create_attempt).to eql attempt
      end

      it 'sets disable_enhanced_feedback to false for the attempt returned' do
        expect(student_presenter.find_or_create_attempt.disable_enhanced_feedback).to be_falsey
      end
    end

    context 'when there is an assignment,' do
      before do
        allow(assignment).to receive(:disable_enhanced_feedback?).and_return(false)
        allow(student_presenter).to receive(:assignment).and_return(assignment)
      end

      it 'finds or creates an attempt for the current activity, student, ' \
         'section, and the scoring ruleset of that assignment' do
        student_presenter.find_or_create_attempt
        expect(Attempt).to have_received(:find_or_create_with_scoring_ruleset)
          .with(student, activity, section.id, ruleset)
      end

      it 'returns the found or created attempt' do
        expect(student_presenter.find_or_create_attempt).to eql attempt
      end

      context 'when the assignment has enhanced feedback disabled' do
        it 'sets disable_enhanced_feedback to true for the attempt returned' do
          allow(assignment).to receive(:disable_enhanced_feedback?)
            .and_return(true)
          expect(
            student_presenter.find_or_create_attempt.disable_enhanced_feedback
          ).to be_truthy
        end
      end

      context 'when the assignment has enhanced feedback enabled' do
        it 'sets disable_enhanced_feedback to false for the attempt returned' do
          allow(assignment).to receive(:disable_enhanced_feedback?)
            .and_return(false)
          expect(
            student_presenter.find_or_create_attempt.disable_enhanced_feedback
          ).to be_falsey
        end
      end
    end
  end

  describe '#activity_in_study_plan?' do
    it 'is false if activity_in_study_plan attr is not set' do
      expect(student_presenter.activity_in_study_plan?).to be false
    end

    it 'is false if activity_in_study_plan attr is set to false' do
      student_presenter.activity_in_study_plan = false
      expect(student_presenter.activity_in_study_plan?).to be false
    end

    it 'is true if activity_in_study_plan attr is set to true' do
      student_presenter.activity_in_study_plan = true
      expect(student_presenter.activity_in_study_plan?).to be true
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_redirect_to_dashboard` doesn't make sense.
  describe '#redirect_to_dashboard?' do
    it 'is false when current user is an instructor' do
      expect(instructor_presenter.redirect_to_dashboard?).to be_falsey
    end

    context 'with an activity that is not an assessment' do
      before do
        allow(activity).to receive(:assessment?).and_return(false)
      end

      it 'is false for a student enrolled in the current section' do
        allow(student).to receive(:enrolled_in_section?).with(section).and_return(true)
        expect(student_presenter.redirect_to_dashboard?).to be_falsey
      end

      it 'is false for a student not enrolled in the current section' do
        allow(student).to receive(:enrolled_in_section?).with(section).and_return(false)
        expect(student_presenter.redirect_to_dashboard?).to be_falsey
      end
    end

    it 'is true with an assessment for a student not enrolled in ' \
       'the current section' do
      allow(activity).to receive(:assessment?).and_return(true)
      allow(student).to receive(:enrolled_in_section?).with(section).and_return(false)
      expect(student_presenter.redirect_to_dashboard?).to be_truthy
    end

    context 'with an enrolled student and an activity that is an assessment' do
      let(:score) do
        instance_double(GradebookEngine::CurrentScoreAction, pending?: false,
                                                             submitted_at: 1.day.ago)
      end

      before do
        allow(student).to receive(:enrolled_in_section?).with(section).and_return(true)
        allow(activity).to receive(:assessment?).and_return(true)
        allow(student_presenter).to receive(:assignment).and_return(assignment)
        allow(gradebook_api).to receive(:find_score).and_return(score)
      end

      it 'is true when assessment has been submitted and graded but has ' \
         'not been released' do
        allow(assignment).to receive(:shown?).and_return(false)
        expect(student_presenter.redirect_to_dashboard?).to be_truthy
      end

      context 'when the assessment has been released,' do
        before do
          allow(assignment).to receive(:shown?).and_return(true)
        end

        context 'when there is no completed attempt,' do
          before do
            allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
              .and_return(attempt)
            allow(attempt).to receive(:completed?).and_return(false)
          end

          it 'is false if the student has no score' do
            allow(gradebook_api).to receive(:find_score).and_return(nil)
            expect(student_presenter.redirect_to_dashboard?).to be_falsey
          end

          it 'is false if the student has a score that is not graded' do
            allow(score).to receive(:pending?).and_return(true)
            expect(student_presenter.redirect_to_dashboard?).to be_falsey
          end

          it 'is false if the student has a graded score and grades' \
             'have been made available' do
            allow(assignment).to receive(:assessment_grade_available?)
              .and_return(true)
            expect(student_presenter.redirect_to_dashboard?).to be_falsey
          end
        end

        context 'when there is a completed attempt,' do
          before do
            allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
              .and_return(attempt)
            allow(attempt).to receive(:completed?).and_return(true)
          end

          it 'is false if grades have been made available' do
            allow(assignment).to receive(:assessment_grade_available?)
              .and_return(true)
            expect(student_presenter.redirect_to_dashboard?).to be_falsey
          end

          it 'is true if grades have not been made available' do
            allow(assignment).to receive(:assessment_grade_available?)
              .and_return(false)
            expect(student_presenter.redirect_to_dashboard?).to be_truthy
          end
        end
      end

      context 'when attempt completion is specified as false,' do
        it 'is true when the assessment has not been released' do
          allow(assignment).to receive(:shown?).and_return(false)
          expect(
            student_presenter.redirect_to_dashboard?(_activity_complete = false)
          ).to be_truthy
        end

        context 'when the assessment is released,' do
          before do
            allow(assignment).to receive(:shown?).and_return(true)
          end

          it 'is false if the student has no score' do
            allow(gradebook_api).to receive(:find_score).and_return(nil)
            expect(
              student_presenter.redirect_to_dashboard?(_activity_complete = false)
            ).to be_falsey
          end

          it 'is false if the student has a score that is not graded' do
            allow(score).to receive(:pending?).and_return(true)
            expect(
              student_presenter.redirect_to_dashboard?(_activity_complete = false)
            ).to be_falsey
          end

          it 'is false if the student has a graded score and grades' \
             'have been made available' do
            allow(assignment).to receive(:assessment_grade_available?)
              .and_return(true)
            expect(
              student_presenter.redirect_to_dashboard?(_activity_complete = false)
            ).to be_falsey
          end
        end
      end

      context 'when attempt completion is specified as true' do
        it 'is true when the assessment has not been released' do
          allow(assignment).to receive(:shown?).and_return(false)
          expect(
            student_presenter.redirect_to_dashboard?(_activity_complete = true)
          ).to be_truthy
        end

        it 'is true when the assessment is released but grades are not ' \
           'available' do
          allow(assignment).to receive(:shown?).and_return(true)
          allow(assignment).to receive(:assessment_grade_available?)
            .and_return(false)
          expect(
            student_presenter.redirect_to_dashboard?(_activity_complete = true)
          ).to be_truthy
        end

        it 'is false when the assessment is released and grades are available' do
          allow(assignment).to receive(:shown?).and_return(true)
          allow(assignment).to receive(:assessment_grade_available?)
            .and_return(true)
          expect(
            student_presenter.redirect_to_dashboard?(_activity_complete = true)
          ).to be_falsey
        end
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_track_time` doesn't make sense.
  describe '#track_time?' do
    it 'is false if the user is an instructor' do
      expect(instructor_presenter.track_time?).to be_falsey
    end

    it 'is false if the user is a student but the activity is not an assessment' do
      allow(activity).to receive(:assessment?).and_return(false)
      expect(student_presenter.track_time?).to be_falsey
    end

    context 'when the user is a student and the activity is an assessment,' do
      before do
        allow(activity).to receive(:assessment?).and_return(true)
      end

      it 'is false if there is no assignment' do
        allow(student_presenter).to receive(:assignment).and_return(nil)
        expect(student_presenter.track_time?).to be_falsey
      end

      it 'is false if there is an assignment that is not timed' do
        allow(student_presenter).to receive(:assignment).and_return(assignment)
        allow(assignment).to receive(:timed?).and_return(false)
        expect(student_presenter.track_time?).to be_falsey
      end

      context 'with a timed assignment,' do
        before do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:timed?).and_return(true)
        end

        it 'is false if there is no attempt' do
          expect(student_presenter.track_time?).to be_falsey
        end

        context 'with an attempt,' do
          before do
            allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
              .and_return(attempt)
          end

          it 'is false if the attempt is not started' do
            allow(attempt).to receive(:started?).and_return(false)
            expect(student_presenter.track_time?).to be_falsey
          end

          it 'is true if the attempt is started' do
            allow(attempt).to receive(:started?).and_return(true)
            expect(student_presenter.track_time?).to be_truthy
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_time_left` doesn't make sense.  Maybe should have named
  # this method "has_time_left?" instead.
  describe '#time_left?' do
    before do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
        .and_return(attempt)
    end

    it 'is false if attempt has no time left' do
      allow(attempt).to receive(:time_left_in_seconds).and_return(0)
      expect(student_presenter.time_left?).to be_falsey
    end

    it 'is true if attempt has at least one second of time left' do
      allow(attempt).to receive(:time_left_in_seconds).and_return(1)
      expect(student_presenter.time_left?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#timed_assessment?' do
    it 'is false if the user is an instructor' do
      expect(instructor_presenter).not_to be_timed_assessment
    end

    context 'when the user is a student,' do
      it 'is false if the activity is not an assessment' do
        allow(activity).to receive(:assessment?).and_return(false)
        expect(student_presenter).not_to be_timed_assessment
      end

      context 'when the activity is an assessment,' do
        before do
          allow(activity).to receive(:assessment?).and_return(true)
        end

        it 'is false if there is no assignment' do
          allow(student_presenter).to receive(:assignment).and_return(nil)
          expect(student_presenter).not_to be_timed_assessment
        end

        it 'is false if there is an assignment that is not timed' do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:timed?).and_return(false)
          expect(student_presenter).not_to be_timed_assessment
        end

        it 'is true if there is a timed assessment' do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:timed?).and_return(true)
          expect(student_presenter).to be_timed_assessment
        end
      end
    end
  end

  describe '#original_time_limit' do
    it 'returns the assignment time limit in seconds' do
      # Time limit is stored in minutes
      allow(assignment).to receive(:time_limit).and_return(1)
      allow(student_presenter).to receive(:assignment).and_return(assignment)
      expect(student_presenter.original_time_limit).to eq(60)
    end
  end

  describe '#assessment_due_date' do
    it 'returns nil if there is no assignment' do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      expect(student_presenter.assessment_due_date).to be_nil
    end

    it 'returns the due date of the assignment with short day of week' do
      assignment = build_stubbed(:assignment, due_date: Date.new(2017, 5, 2))
      allow(student_presenter).to receive(:assignment).and_return(assignment)
      expect(student_presenter.assessment_due_date).to eq('Tue, May 02, 2017')
    end
  end

  describe '#assessment_due_time' do
    it 'returns nil if there is no assignment' do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      expect(student_presenter.assessment_due_time).to be_nil
    end

    context 'with an assignment,' do
      before do
        section.due_time = '09:00'
        section.time_zone = 'Central Time (US & Canada)'
        assignment = build_stubbed(
          :assignment,
          due_date: Date.new(2017, 5, 2),
          section: section
        )
        allow(student_presenter).to receive(:assignment).and_return(assignment)
      end

      context 'when the user is in the same time zone as the section' do
        it 'returns the assignment due time with no time zone info' do
          student.time_zone = section.time_zone
          expect(student_presenter.assessment_due_time).to eq('09:00 AM')
        end
      end

      context 'when the user is in a different time zone than the section' do
        it "returns the assignment due time displaying section's time zone", test_debt: true do
          pending 'This method seems to be broken. Changing .due_time to ' \
            '.due_date_time seems like it would fix the time zone display'
          student.time_zone = 'Pacific Time (US & Canada)'
          expect(student_presenter.assessment_due_time).to eq('09:00 AM CDT')
        end
      end
    end
  end

  describe '#assessment_display_title' do
    it 'returns the title of the activity' do
      expect(student_presenter.assessment_display_title).to eq(activity.title)
    end
  end

  describe '#activity_component_name' do
    it 'returns the component name when listed' do
      expect(student_presenter.activity_component_name).to eq(
        activity.component_name
      )
    end

    it "returns 'Practice' if unlisted" do
      activity.component_name = 'unlisted'
      expect(student_presenter.activity_component_name).to eq('Practice')
    end
  end

  describe '#assessment_time_limit' do
    before do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
    end

    it 'returns the number of minutes if less than 60' do
      allow(assignment).to receive(:time_limit).and_return(45)
      expect(student_presenter.assessment_time_limit).to eq('45 minutes')
    end

    it 'returns the number of hours and minutes if over 60' do
      allow(assignment).to receive(:time_limit).and_return(75)
      expect(student_presenter.assessment_time_limit).to eq('1 hour 15 minutes')
    end

    it 'returns hours only when minutes are zero' do
      allow(assignment).to receive(:time_limit).and_return(60)
      expect(student_presenter.assessment_time_limit).to eq('1 hour')
    end

    it 'displays plural hours when hours > 1' do
      allow(assignment).to receive(:time_limit).and_return(135)
      expect(student_presenter.assessment_time_limit).to eq('2 hours 15 minutes')
    end
  end

  describe '#has_audio?' do
    it 'is true when the activity icon is audio' do
      allow(activity).to receive(:icon).and_return('audio')
      expect(student_presenter).to have_audio
    end

    it 'is true when the activity icon contains audio' do
      allow(activity).to receive(:icon).and_return('microphone,audio')
      expect(student_presenter).to have_audio
    end

    it 'is false when the activity icon does not contain audio' do
      allow(activity).to receive(:icon).and_return('video')
      expect(student_presenter).not_to have_audio
    end

    it 'is false when the activity icon is blank' do
      allow(activity).to receive(:icon).and_return('')
      expect(student_presenter).not_to have_audio
    end
  end

  describe '#standard_timeout_override' do
    before do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
    end

    it 'returns nil if there are no no detailed assignment settings' do
      allow(assignment).to receive(:assigned_assessment_detail).and_return(nil)
      expect(student_presenter.standard_timeout_override).to be_nil
    end

    it 'returns one hour plus double the time limit specified in detailed ' \
       'assignment settings, in milliseconds' do
      allow(assignment).to receive(:assigned_assessment_detail)
        .and_return(build_stubbed(:assigned_assessment_detail, time_limit: 1))
      expect(student_presenter.standard_timeout_override).to eq(3_720_000)
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_requires_unlocking` doesn't make sense.
  describe '#requires_unlocking?' do
    it 'is false when current user is an instructor' do
      expect(instructor_presenter.requires_unlocking?(nil)).to be_falsey
    end

    context 'when current user is a student,' do
      it 'returns false when activity is not an assessment' do
        allow(activity).to receive(:assessment?).and_return(false)
        expect(student_presenter.requires_unlocking?(nil)).to be_falsey
      end

      context 'with an assessment,' do
        before do
          allow(activity).to receive(:assessment?).and_return(true)
          allow(student_presenter).to receive(:assignment).and_return(assignment)
        end

        # Remove this test when unnecessary assigned_assessment_detail
        # check is removed.
        it 'returns false if there are no assignment details' do
          allow(assignment).to receive(:assigned_assessment_detail)
            .and_return(nil)
          expect(student_presenter.requires_unlocking?(nil)).to be_falsey
        end

        it 'returns false if there are assignment details with no password' do
          # Remove this stub when unnecessary assigned_assessment_detail
          # check is removed.
          allow(assignment).to receive(:assigned_assessment_detail)
            .and_return(build_stubbed(:assigned_assessment_detail))
          allow(assignment).to receive(:has_password?).and_return(false)
          expect(student_presenter.requires_unlocking?(nil)).to be_falsey
        end

        context 'when there are assignment details with a password' do
          before do
            # Remove this stub when unnecessary assigned_assessment_detail
            # check is removed.
            allow(assignment).to receive(:assigned_assessment_detail)
              .and_return(build_stubbed(:assigned_assessment_detail))
            allow(assignment).to receive(:has_password?).and_return(true)
          end

          it 'returns false if the unlocked assessments argument contains ' \
             'the id of the current activity' do
            expect(
              student_presenter.requires_unlocking?([activity.id])
            ).to be_falsey
          end

          it 'returns true if the unlocked assessments argument does not ' \
             'contain the id of the current activity' do
            expect(
              student_presenter.requires_unlocking?([])
            ).to be_truthy
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_requires_interstitial` doesn't make sense.
  describe '#requires_interstitial?' do
    it 'is false when the user is not a student' do
      expect(instructor_presenter.requires_interstitial?(nil)).to be_falsey
    end

    it 'is false when the user is a student but the activity is ' \
       'not an assessment' do
      allow(activity).to receive(:assessment?).and_return(false)
      expect(student_presenter.requires_interstitial?(nil)).to be_falsey
    end

    context 'when user is a student and activity is an assessment' do
      before do
        allow(activity).to receive(:assessment?).and_return(true)
        allow(student_presenter).to receive(:assignment).and_return(assignment)
        allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
          .and_return(attempt)
      end

      it 'is true if there is no started attempt' do
        allow(attempt).to receive(:started?).and_return(false)
        expect(student_presenter.requires_interstitial?(nil)).to be_truthy
      end

      context 'with a started attempt' do
        before do
          allow(attempt).to receive(:started?).and_return(true)
        end

        # Remove this test when unnecessary assigned_assessment_detail
        # check is removed.
        it 'is false if there are no assignment details' do
          allow(assignment).to receive(:assigned_assessment_detail)
            .and_return(nil)
          expect(student_presenter.requires_interstitial?(nil)).to be_falsey
        end

        it 'is false if there are assignment details with no password' do
          # Remove this stub when unnecessary assigned_assessment_detail
          # check is removed.
          allow(assignment).to receive(:assigned_assessment_detail)
            .and_return(build_stubbed(:assigned_assessment_detail))
          allow(assignment).to receive(:has_password?).and_return(false)
          expect(student_presenter.requires_interstitial?(nil)).to be_falsey
        end

        context 'when there are assignment details with a password' do
          before do
            # Remove this stub when unnecessary assigned_assessment_detail
            # check is removed.
            allow(assignment).to receive(:assigned_assessment_detail)
              .and_return(build_stubbed(:assigned_assessment_detail))
            allow(assignment).to receive(:has_password?).and_return(true)
          end

          it 'is false if the unlocked assessments argument contains ' \
             'the id of the current activity' do
            expect(
              student_presenter.requires_interstitial?([activity.id])
            ).to be_falsey
          end

          it 'is true if the unlocked assessments argument does not ' \
             'contain the id of the current activity' do
            expect(
              student_presenter.requires_interstitial?([])
            ).to be_truthy
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_assessment_locked` doesn't make sense
  describe '#assessment_locked?' do
    it 'is false when the current user is an instructor' do
      expect(instructor_presenter.assessment_locked?).to be_falsey
    end

    it 'returns false when current user is a student but the activity ' \
       'is not an assessment' do
      allow(activity).to receive(:assessment?).and_return(false)
      expect(student_presenter.assessment_locked?).to be_falsey
    end

    context 'when user is a student and activity is an assessment' do
      before do
        allow(activity).to receive(:assessment?).and_return(true)
        allow(student_presenter).to receive(:assignment).and_return(assignment)
      end

      # Remove this test when unnecessary assigned_assessment_detail
      # check is removed.
      it 'is false if there are no assignment details' do
        allow(assignment).to receive(:assigned_assessment_detail)
          .and_return(nil)
        expect(student_presenter.assessment_locked?).to be_falsey
      end

      it 'is false if there are assignment details with no password' do
        # Remove this stub when unnecessary assigned_assessment_detail
        # check is removed.
        allow(assignment).to receive(:assigned_assessment_detail)
          .and_return(build_stubbed(:assigned_assessment_detail))
        allow(assignment).to receive(:has_password?).and_return(false)
        expect(student_presenter.assessment_locked?).to be_falsey
      end

      it 'is true when there are assignment details with a password' do
        # Remove this stub when unnecessary assigned_assessment_detail
        # check is removed.
        allow(assignment).to receive(:assigned_assessment_detail)
          .and_return(build_stubbed(:assigned_assessment_detail))
        allow(assignment).to receive(:has_password?).and_return(true)
        expect(student_presenter.assessment_locked?).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#due_time_with_zone' do
    before do
      section.due_time = '09:00'
      section.time_zone = 'Central Time (US & Canada)'
      assignment = build_stubbed(
        :assignment,
        due_date: Date.new(2017, 5, 2),
        section: section
      )
      allow(student_presenter).to receive(:assignment).and_return(assignment)
    end

    context 'when the current time zone is the same as the section time zone' do
      it 'returns the assignment due time with no time zone info' do
        Time.use_zone(section.time_zone) do
          expect(student_presenter.due_time_with_zone).to eq(' 9:00 AM ')
        end
      end
    end

    context 'when current time zone is different than the section time zone' do
      it "returns the assignment due time displaying section's time zone" do
        Time.use_zone('Pacific Time (US & Canada)') do
          expect(student_presenter.due_time_with_zone).to eq(' 9:00 AM CDT')
        end
      end
    end
  end

  describe '#ordinalized_due_date_time' do
    before do
      section.due_time = '09:00'
      section.time_zone = 'Central Time (US & Canada)'
      assignment = build_stubbed(
        :assignment,
        due_date: Date.new(2017, 5, 2),
        section: section
      )
      allow(student_presenter).to receive(:assignment).and_return(assignment)
    end

    context 'when the current time zone is the same as the section time zone' do
      it 'returns the assignment due date and time with no time zone info' do
        Time.use_zone(section.time_zone) do
          expect(student_presenter.ordinalized_due_date_time).to eq('May 2nd  9:00 AM')
        end
      end
    end

    context 'when current time zone is different than the section time zone' do
      it "returns the assignment due date and time displaying section's time zone" do
        Time.use_zone('Pacific Time (US & Canada)') do
          expect(student_presenter.ordinalized_due_date_time).to eq('May 2nd  9:00 AM CDT')
        end
      end
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_activity_gradeable` doesn't make sense.
  describe '#activity_gradable?' do
    let(:category) { build_stubbed(:category) }

    context 'when the activity is gradable,' do
      before do
        allow(activity).to receive(:gradable?).and_return(true)
      end

      context 'when the activity is assigned,' do
        before do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:category).and_return(category)
        end

        it 'returns true when the assignment category is not credit-only' do
          allow(category).to receive(:credit_only?).and_return(false)
          expect(student_presenter.activity_gradable?).to be_truthy
        end

        it 'returns false when the assignment category is credit-only' do
          allow(category).to receive(:credit_only?).and_return(true)
          expect(student_presenter.activity_gradable?).to be_falsey
        end
      end

      it 'returns true when the activity is NOT assigned' do
        allow(student_presenter).to receive(:assignment).and_return(nil)
        expect(student_presenter.activity_gradable?).to be_truthy
      end
    end

    context 'when the activity is NOT gradable' do
      before do
        allow(activity).to receive(:gradable?).and_return(false)
      end

      context 'when the activity is assigned' do
        before do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:category).and_return(category)
        end

        it 'returns false if assigned in a credit-only category' do
          allow(category).to receive(:credit_only?).and_return(true)
          expect(student_presenter.activity_gradable?).to be_falsey
        end

        it 'returns false if assigned in a non-credit-only category' do
          allow(category).to receive(:credit_only?).and_return(false)
          expect(student_presenter.activity_gradable?).to be_falsey
        end
      end

      it 'returns false when the activity is NOT assigned' do
        allow(student_presenter).to receive(:assignment).and_return(nil)
        expect(student_presenter.activity_gradable?).to be_falsey
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#attempts_remaining' do
    let(:attempt_track) { instance_double(AttemptTrack) }

    before do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      allow(Attempt).to receive(:find_or_create_with_scoring_ruleset)
        .and_return(attempt)
      allow(attempt).to receive(:attempt_track).and_return(attempt_track)
    end

    it 'returns the number of attempts from the attempt track' do
      allow(attempt_track).to receive(:remaining).and_return(1)
      expect(student_presenter.attempts_remaining).to eq('1 attempt')
    end

    it 'returns a label for the attempt count with the correct pluralization' do
      allow(attempt_track).to receive(:remaining).and_return(2)
      expect(student_presenter.attempts_remaining).to eq('2 attempts')
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_activity_assigned` doesn't make sense.
  describe '#activity_assigned?' do
    it 'is false if there is no assignment matching the current activity' do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      expect(student_presenter.activity_assigned?).to be_falsey
    end

    it 'is true if there is an assignment for the current activity' do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
      expect(student_presenter.activity_assigned?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_late_work_accepted` doesn't make sense.
  describe '#late_work_accepted?' do
    it 'is false if the activity is not assigned' do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      expect(student_presenter.late_work_accepted?).to be_falsey
    end

    context 'with an assignment,' do
      before do
        allow(student_presenter).to receive(:assignment).and_return(assignment)
      end

      it 'is false if the assignment category does not accept late work' do
        allow(assignment).to receive(:category)
          .and_return(build_stubbed(:category, accept_late_work: false))
        expect(student_presenter.late_work_accepted?).to be_falsey
      end

      it 'is true if the assignment category accepts late work' do
        allow(assignment).to receive(:category)
          .and_return(build_stubbed(:category, accept_late_work: true))
        expect(student_presenter.late_work_accepted?).to be_truthy
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_requires_ajax_submission` doesn't make sense.
  describe '#requires_ajax_submission?' do
    it 'is false when activity is not partner chat or solo video recording' do
      allow(activity).to receive(:partner_chat?).and_return(false)
      expect(student_presenter.requires_ajax_submission?).to be_falsey
    end

    it 'is false when activity is solo video recording' do
      allow(activity).to receive(:solo_video_recording?).and_return(false)
      expect(student_presenter.requires_ajax_submission?).to be_falsey
    end

    it 'is true when activity is partner chat' do
      allow(activity).to receive(:partner_chat?).and_return(true)
      expect(student_presenter.requires_ajax_submission?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#grade_availability_description' do
    before do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
    end

    it 'returns an empty string when assessment grade is available' do
      allow(assignment).to receive(:assessment_grade_available?)
        .and_return(true)
      results = student_presenter.grade_availability_description
      expect(results).to eq('')
    end

    context 'when assessment grade is not available' do
      before do
        allow(assignment).to receive(:shown?).and_return(true)
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(false)
        allow(activity).to receive(:strand_singular_label)
          .and_return('Electric Feel')
      end

      it 'returns a message indicating instructor has not released results' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_release)
        expect(student_presenter.grade_availability_description).to eq(
          'Your instructor has chosen not to allow students to view their ' \
          'full results for this Electric Feel until he/she releases them.  ' \
          'Please try again later.'
        )
      end

      it 'returns a message indicating instructor will release grades ' \
         'when they finish grading all students' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_grading)
        expect(student_presenter.grade_availability_description).to eq(
          'Your instructor has chosen not to allow students to view their ' \
          'full results for this Electric Feel until all students have been ' \
          'graded.  Please try again later.'
        )
      end

      it 'returns a message indicating instructor will release ' \
         'grades on a specific date' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_specific_date)
        allow(assignment).to receive(:grades_available_at)
          .and_return(Date.today)
        expect(student_presenter.grade_availability_description).to eq(
          'Your instructor has chosen not to allow students to view their ' \
          'full results for this Electric Feel until after ' +
          assignment.grades_available_at.strftime(
            "%a, %b #{assignment.grades_available_at.day.ordinalize} %I:%M %p."
          ) + '. Please try again at that time.'
        )
      end

      it 'returns a message indicating grades will be available ' \
         'after the due date' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_due_date)
        allow(assignment).to receive(:due_date)
          .and_return(10.days.from_now.to_date)
        expect(student_presenter.grade_availability_description).to eq(
          'Your instructor has chosen not to allow students to view their ' \
          'full results for this Electric Feel until after ' +
          assignment.due_date.strftime(
            "%a, %b #{assignment.due_date.day.ordinalize} %I:%M %p."
          ) + '. Please try again at that time.'
        )
      end

      it "returns a message indicating grades won't be released" do
        allow(assignment).to receive(:grade_availability)
          .and_return(:never)
        expect(student_presenter.grade_availability_description).to eq(
          'Your instructor has chosen not to allow students to view their ' \
          'full results for this Electric Feel.'
        )
      end
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_assessment_assigned_and_released` doesn't make sense.
  describe '#assessment_assigned_and_released?' do
    context 'with non assessment activity' do
      before do
        allow(activity).to receive(:assessment?).and_return(false)
      end

      it 'returns true if activity is not an assessment' do
        expect(student_presenter.assessment_assigned_and_released?).to be_truthy
      end

      it 'does not prepare a flash text if assessment is released' do
        student_presenter.assessment_assigned_and_released?
        expect(student_presenter.flash_notice).to be_nil
      end
    end

    context 'with an assessment activity,' do
      before do
        allow(activity).to receive(:assessment?).and_return(true)
        allow(activity).to receive(:strand_singular_label).and_return('quiz')
      end

      it 'is false if there is no assignment' do
        allow(student_presenter).to receive(:assignment).and_return(nil)
        expect(student_presenter.assessment_assigned_and_released?).to be_falsey
      end

      context 'with a released assignment,' do
        before do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:shown?).and_return(true)
        end

        it 'returns true' do
          expect(student_presenter.assessment_assigned_and_released?).to be_truthy
        end

        it 'does not set a flash message' do
          student_presenter.assessment_assigned_and_released?
          expect(student_presenter.flash_notice).to be_nil
        end
      end

      context 'with an unreleased assignment,' do
        before do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:shown?).and_return(false)
        end

        it 'returns false' do
          expect(student_presenter.assessment_assigned_and_released?).to be_falsey
        end

        it 'sets a flash message' do
          student_presenter.assessment_assigned_and_released?
          expect(student_presenter.flash_notice).to eq(
            'The quiz you tried to access has not yet been enabled by your ' \
            'instructor.'
          )
        end
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#track_group' do
    it 'returns nil if there is no assignment' do
      allow(student_presenter).to receive(:assignment).and_return(nil)
      expect(student_presenter.track_group).to be_nil
    end

    it 'returns the track group of the assignment if there is one' do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive(:track_group).and_return('Explore')
      expect(student_presenter.track_group).to eq('Explore')
    end
  end

  describe '#video_settings' do
    def read_attrs(settings)
      attrs = %i[allow_popup_translation subtitle_languages transcript_languages]
      attrs.map { |attr| settings.public_send(attr) }
    end

    let(:default_settings) do
      read_attrs(MaestroActivityEngine::VideoSettings.new)
    end

    context 'when an activity is a question bank' do
      let!(:question_bank_topic) { create(:question_bank_topic) }
      let(:json) do
        File.read(
          File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
        )
      end

      let!(:question_bank) do
        create(
          :question_bank,
          content_json: json,
          question_bank_topic: question_bank_topic,
          upload_filename: 'fake_file.csv'
        )
      end

      it 'returns default settings (all enabled)' do
        expect(
          read_attrs(instructor_presenter.video_settings)
        ).to eq(default_settings)
      end
    end

    context 'when user is an instructor,' do
      it 'returns default settings (all enabled)' do
        expect(
          read_attrs(instructor_presenter.video_settings)
        ).to eq(default_settings)
      end
    end

    context 'when user is a grader,' do
      it 'returns default settings (all enabled)' do
        grader = build_stubbed(:grader)
        presenter = StudentActivityPresenter.new(activity, grader, section)
        expect(
          read_attrs(presenter.video_settings)
        ).to eq(default_settings)
      end
    end

    context 'when user is a student,' do
      context 'when user is enrolled in a course,' do
        it 'sets settings based on the current course video configuration' do
          allow(student).to receive(:enrolled_in_section?).with(section).and_return(true)
          expect(
            read_attrs(student_presenter.video_settings)
          ).to eq(
            [
              course.allow_video_popup_translation?,
              course.video_subtitle_languages,
              course.video_transcript_languages
            ]
          )
        end
      end

      context 'when user is not enrolled in a course,' do
        it 'sets settings to only allow foreign subtitles and transcripts ' \
           'with popup translations' do
          allow(student).to receive(:enrolled_in_section?).with(section).and_return(false)
          expect(
            read_attrs(student_presenter.video_settings)
          ).to eq(
            [default_settings.first, 'foreign', 'foreign']
          )
        end
      end
    end

    context 'when assigning is-English setting' do
      it 'sets is_english true if program language is English' do
        allow(activity.program).to receive(:language_code).and_return('en')
        expect(student_presenter.video_settings.is_english).to be(true)
      end

      it 'sets is_english false if program language is not English' do
        expect(student_presenter.video_settings.is_english).to be(false)
      end
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_should_show_answers` doesn't make sense.
  describe '#should_show_answers?' do
    context 'when the activity is an assessment,' do
      before do
        allow(activity).to receive(:assessment?).and_return(true)
      end

      it 'is true if the current user is an instructor' do
        expect(instructor_presenter.should_show_answers?).to be_truthy
      end

      it 'is false if if the current section is nil' do
        presenter = StudentActivityPresenter.new(activity, student, nil)
        expect(presenter.should_show_answers?).to be_falsey
      end

      it 'is false if the assessment is not assigned' do
        allow(student_presenter).to receive(:assignment).and_return(nil)
        expect(student_presenter.should_show_answers?).to be_falsey
      end
    end

    it 'is true when the activity is not an assessment' do
      allow(activity).to receive(:assessment?).and_return(false)
      expect(student_presenter.should_show_answers?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#activity_list_header' do
    let(:lesson) do
      instance_double(
        Lesson,
        activity_list_header: 'Adelante | Lectura',
        display_name: 'Leccion 1',
        in_two_tier_program?: false
      )
    end

    before do
      allow(activity).to receive(:lesson).and_return(lesson)
      allow(activity).to receive(:toc_location).and_return(152_648)
    end

    it 'looks up the activity list header from the lesson' do
      student_presenter.activity_list_header
      expect(lesson).to have_received(:activity_list_header)
        .with(activity.toc_location)
    end

    it 'returns a header with the Lesson | Book Section | Substrand' do
      expect(student_presenter.activity_list_header).to eq(
        'Leccion 1 | Adelante | Lectura'
      )
    end

    it 'returns an empty string when activity has no lesson' do
      allow(activity).to receive(:lesson).and_return(nil)
      expect(student_presenter.activity_list_header).to eq('')
    end

    it 'returns an empty string when activity has no toc_location' do
      allow(activity).to receive(:toc_location).and_return(nil)
      expect(student_presenter.activity_list_header).to eq('')
    end
  end

  describe '#lesson_header' do
    let(:lesson) { instance_double(Lesson, display_name: 'Leccion 1') }

    before do
      allow(activity).to receive(:lesson).and_return(lesson)
    end

    context 'when the activity has no strand or substrand' do
      it 'returns a hash with the lesson display name and nil values for ' \
         'strand and substrand keys' do
        allow(lesson).to receive(:strand_for_toc_location).and_return(nil)
        allow(lesson).to receive(:substrand_for_toc_location).and_return(nil)
        expect(student_presenter.lesson_header).to eq(
          lesson: 'Leccion 1',
          strand: nil,
          substrand: nil
        )
      end
    end

    context 'when the activity has a strand and substrand' do
      it 'returns a hash with the names of the strand and substrand' do
        strand = build_stubbed(:toc_entry)
        substrand = build_stubbed(:toc_entry)
        allow(lesson).to receive(:strand_for_toc_location).and_return(strand)
        allow(lesson).to receive(:substrand_for_toc_location).and_return(substrand)
        expect(student_presenter.lesson_header).to eq(
          lesson: 'Leccion 1',
          strand: strand.name,
          substrand: substrand.name
        )
      end
    end
  end

  describe '#partner_chat_roster' do
    it 'returns a partner chat roster for the user, course, and activity' do
      allow(PartnerChatRoster).to receive(:new)

      student_presenter.partner_chat_roster

      expect(PartnerChatRoster).to have_received(:new)
        .with(student, course, activity)
    end
  end

  describe '#notifications' do
    before do
      allow(activity).to receive(:notifications_by_user_and_section)
        .and_return(['dummy_notification'])
    end

    it 'retrieves notifications for the current user and section from the activity' do
      student_presenter.notifications
      expect(activity).to have_received(:notifications_by_user_and_section)
        .with(student, section)
    end

    it 'returns the retrieved notifications' do
      expect(student_presenter.notifications).to eql ['dummy_notification']
    end
  end

  describe '#randomize_per_student?' do
    it 'is false if the user is an instructor' do
      allow(student_presenter).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive(:randomize_per_student?).and_return(true)
      expect(student_presenter.randomize_assessment?).to be_falsey
    end

    context 'when the user is a student,' do
      it 'is false if the activity is not an assessment' do
        allow(activity).to receive(:assessment?).and_return(false)
        expect(student_presenter.randomize_assessment?).to be_falsey
      end

      context 'when the activity is an assessment,' do
        before do
          allow(activity).to receive(:assessment?).and_return(true)
        end

        it 'is false if there is no assignment' do
          allow(student_presenter).to receive(:assignment).and_return(nil)
          expect(student_presenter.randomize_assessment?).to be_falsey
        end

        it 'is false if there is an assignment that does not allow randomization per student' do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:randomize_per_student?).and_return(false)
          expect(student_presenter.randomize_assessment?).to be_falsey
        end

        it 'is true if there is an assignment allowing randomization per student' do
          allow(student_presenter).to receive(:assignment).and_return(assignment)
          allow(assignment).to receive(:randomize_per_student?).and_return(true)
          expect(student_presenter.randomize_assessment?).to be_truthy
        end
      end
    end
  end

  describe '#answer_key_mode?' do
    it 'returns false by default' do
      expect(student_presenter).not_to be_answer_key_mode
      expect(instructor_presenter).not_to be_answer_key_mode
    end

    it 'does not allow the answey_key_mode parameter in the '\
       'instructor presenter constructor' do
      expect do
        InstructorActivityPresenter.new(
          activity,
          instructor,
          section,
          course,
          answer_key_mode: true
        )
      end.to raise_error('wrong number of arguments (given 5, expected 4)')
    end

    it 'allows the answer_key_mode parameter in the student presenter ' \
       'constructor, and return the given value' do
      presenter = StudentActivityPresenter.new(
        activity,
        instructor,
        section,
        answer_key_mode: true
      )
      expect(presenter).to be_answer_key_mode
    end
  end

  describe '#allow_audio_transcripts?' do
    context 'when allow_audio_transcripts is false' do
      it 'returns true if the user is instructor' do
        expect(instructor_presenter.allow_audio_transcripts?).to be_truthy
      end

      it 'returns false if the user is student' do
        expect(student_presenter.allow_audio_transcripts?).to be_falsey
      end
    end

    context 'when allow_audio_transcripts is true' do
      before do
        section.course.update!(allow_audio_transcripts: true)
      end

      it 'returns true if the user is instructor' do
        expect(instructor_presenter.allow_audio_transcripts?).to be_truthy
      end

      it 'returns true if the user is student' do
        expect(student_presenter.allow_audio_transcripts?).to be_truthy
      end
    end
  end

  describe '#pretest_type' do
    context 'when the activity includes video recording' do
      it 'returns "video"' do
        allow(activity).to receive(:include_video_recording?).and_return(true)
        allow(activity).to receive(:include_audio_recording?).and_return(false)

        expect(student_presenter.pretest_type).to eq('video')
      end
    end

    context 'when the activity includes audio recording' do
      it 'returns "audio"' do
        allow(activity).to receive(:include_video_recording?).and_return(false)
        allow(activity).to receive(:include_audio_recording?).and_return(true)

        expect(student_presenter.pretest_type).to eq('audio')
      end
    end

    context 'when the activity includes neither video nor audio recording' do
      it 'returns nil' do
        allow(activity).to receive(:include_video_recording?).and_return(false)
        allow(activity).to receive(:include_audio_recording?).and_return(false)

        expect(student_presenter.pretest_type).to be_nil
      end
    end
  end
end
