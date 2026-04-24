describe Gradebook::Submission, :core => true do
  include MockResultsHelper

  before do
    allow_any_instance_of(::Gradebook::Submission).to receive(:update_new_gradebook)
  end

  describe '#submit' do
    let(:content) { MaestroActivityEngine::ActivityContent::Content.new }

    context 'when submitting an unassigned activity' do
      around do |example|
        Timecop.travel(Time.local(2018, 2, 24, 12, 5)) do
          example.run
        end
      end

      let(:student) { create(:student) }
      let(:school) { build_stubbed(:school) }
      let(:course) { build_stubbed(:course, school: school) }
      let(:section) { create(:section, course: course) }
      let(:activity) { create(:activity, max_attempts: 1, submittable: true) }
      let(:submission) { Gradebook::Submission.new(student, section, activity) }

      before do
        allow(activity).to receive(:content_object).and_return(content)

        allow(GradebookEngine::GradebookAPI).to receive(:submit)
        allow(submission).to receive(:attempt_count).and_return(1)
      end

      context 'for the first time' do
        it 'updates the gradebook' do
          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id, anything)
        end

        it 'marks the score action pending if instructor grade is pending' do
          submission.submit(mock_results(10, 0.5, _pending = true))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(pending: true))
        end

        it 'sets points earned, time spent and attempt count' do
          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(points_earned: 5,
                                 time_spent: 0,
                                 attempt_count: 1))
        end
      end

      it 'records the points earned' do
        submission.submit(mock_results(10, 0.5))
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_earned: 5))
      end

      context 'points pending' do
        context 'when instructor graded' do
          it 'sets points pending to the instructor graded points possible' do
            submission.submit(mock_results(11, 0.5, true, 11))
            expect(GradebookEngine::GradebookAPI)
              .to have_received(:submit)
              .with(student.id, section.id, activity.id, section.school_id,
                    hash_including(points_pending: 11))
          end
        end

        context 'when auto graded' do
          it 'sets points pending to 0' do
            submission.submit(mock_results(11, 0.5, false))
            expect(GradebookEngine::GradebookAPI)
              .to have_received(:submit)
              .with(student.id, section.id, activity.id, section.school_id,
                    hash_including(points_pending: 0))
          end
        end
      end

      it 'records the submission time' do
        Timecop.freeze(Time.local(2018, 2, 24, 14, 5)) do
          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(submitted_at: Time.local(2018,2,24,14,5)))
        end
      end

      it 'honors the passed in submission time parameter' do
        Timecop.freeze(Time.local(2018, 2, 24, 8, 5)) do
          submission.submit(mock_results(10, 0.5), Time.local(2018,2,24,12,5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(submitted_at: Time.local(2018,2,24,12,5)))
        end
      end

      it 'stores the time spent in seconds' do
        time_spent =  95
        submission.submit(mock_results(11, 0.5), Time.now, time_spent)
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(time_spent: 95))
      end

      it 'stores the attempt count' do
        submission.submit(mock_results(11, 0.5), Time.now)
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(attempt_count: 1))
      end
    end

    context 'when submitting an assigned activity' do
      let(:student) { create(:student) }
      let(:school) { build_stubbed(:school) }
      let(:program) { build_stubbed(:program) }
      let(:instructor) { build_stubbed(:instructor) }

      let(:course) do
        create(:course, school: school,
                        program: program,
                        owner: instructor,
                        start_date: 6.months.ago,
                        end_date: 6.months.from_now)
      end

      let(:section) { create(:section, :course => course, :instructor => instructor) }
      let(:activity) { create(:activity, :max_attempts => 1, :submittable => true) }
      let(:category) { create(:category, :weighting_percent => 100) }

      let(:lesson) { create(:lesson) }
      let(:unit) { create(:unit, :program_id => 1, :lessons => [lesson]) }
      let(:toc_entry) { create(:toc_entry) }

      let(:submission) { Gradebook::Submission.new(student, section, activity) }

      around do |example|
        Timecop.travel(Time.local(2011, 2, 24, 12, 5)) do
          example.run
        end
      end

      before do
        allow(lesson).to receive(:strand_for_toc_location).and_return(toc_entry)
        allow(lesson).to receive(:program).and_return(program)
        allow(Activity).to receive(:find).and_return(activity)
        allow(activity).to receive(:lesson).and_return(lesson)
        allow(activity).to receive(:program).and_return(program)
        allow(activity).to receive(:content_object).and_return(content)
        section.students << student
        allow(GradebookEngine::GradebookAPI).to receive(:submit)
        allow(submission).to receive(:attempt_count).and_return(1)
      end

      context 'for the first time' do
        it 'updates the gradebook' do
          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id, anything)
        end

        it 'marks the score action pending if instructor grade is pending' do
          submission.submit(mock_results(10, 0.5, _pending = true))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(pending: true))
        end

        it 'sets points earned, time spent and attempt count' do
          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(points_earned: 5,
                                 time_spent: 0,
                                 attempt_count: 1))
        end

        it 'sets points_earned equal to points_possible and pending to false ' \
           'if the activity is normally submittable but has been overridden ' \
           'to be credit_only' do
          activity.content_object.credit_only = true

          submission.submit(mock_results(10, 0.5))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(
              student.id,
              section.id,
              activity.id,
              section.school_id,
              hash_including(points_earned: 10.0, pending: false)
          )
        end

        it 'records the submission time' do
          Timecop.freeze(Time.local(2018, 2, 24, 14, 5)) do
            submission.submit(mock_results(10, 0.5))
            expect(GradebookEngine::GradebookAPI)
              .to have_received(:submit)
              .with(student.id, section.id, activity.id, section.school_id,
                    hash_including(submitted_at: Time.local(2018,2,24,14,5)))
          end
        end

        context 'when an activity is gradable' do
          it 'stores the attempt_count' do
            submission.submit(mock_results(11, 0.5), Time.now)
            expect(GradebookEngine::GradebookAPI)
              .to have_received(:submit)
              .with(student.id, section.id, activity.id, section.school_id,
                    hash_including(attempt_count: 1))
          end
        end

        context 'when an activity is not gradable' do
          it 'stores the attempt_count' do
            submission.submit(mock_results(11, 0.5), Time.now)
            expect(GradebookEngine::GradebookAPI)
              .to have_received(:submit)
              .with(student.id, section.id, activity.id, section.school_id,
                    hash_including(attempt_count: 1))
          end
        end

        it 'marks pending if instructor grade is pending' do
          submission.submit(mock_results(10, 0.5, _pending = true))
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(pending: true))
        end

        context 'points pending' do
          context 'when instructor graded' do
            it 'sets points pending to the instructor graded points possible' do
              submission.submit(mock_results(11, 0.5, true, 11))
              expect(GradebookEngine::GradebookAPI)
                .to have_received(:submit)
                .with(student.id, section.id, activity.id, section.school_id,
                      hash_including(points_pending: 11))
            end
          end

          context 'when auto graded' do
            it 'sets points pending to 0' do
              submission.submit(mock_results(11, 0.5, false))
              expect(GradebookEngine::GradebookAPI)
                .to have_received(:submit)
                .with(student.id, section.id, activity.id, section.school_id,
                      hash_including(points_pending: 0))
            end
          end
        end
      end
    end

    context 'when an activity has been revised with different points_possible' do
      let(:student) { create(:student) }
      let(:section) { create(:section) }
      let(:activity) { create(:activity, points_possible: 10, activity_type: 'open_ended') }
      let(:submission) { Gradebook::Submission.new(student, section, activity) }
      let(:results) { double('Results', total_points_possible: 50, score: 30, instructor_graded_score_pending?: false) }
      
      before do
        allow(activity).to receive(:content_object).and_return(content)
        allow(GradebookEngine::GradebookAPI).to receive(:submit)
        allow(submission).to receive(:attempt_count).and_return(1)
      end

      it 'passes points_possible to GradebookAPI.submit' do
        submission.submit(results)
        
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_possible: 50))
      end

      it 'ensures points_possible is included in the settings hash' do
        submission.submit(results)
        
        # Verify that points_possible is actually included in the settings
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit) do |user_id, section_id, activity_id, school_id, settings|
            expect(settings).to include(:points_possible)
            expect(settings[:points_possible]).to eq(50)
          end
      end

      it 'uses the correct points_possible from results' do
        # Create new results with different points_possible
        new_results = double('Results', total_points_possible: 25, score: 20, instructor_graded_score_pending?: false)
        
        submission.submit(new_results)
        
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_possible: 25))
      end

      it 'handles zero points_possible correctly' do
        zero_results = double('Results', total_points_possible: 0, score: 0.0, instructor_graded_score_pending?: false)
        
        submission.submit(zero_results)
        
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_possible: 0))
      end

      it 'handles decimal points_possible correctly' do
        decimal_results = double('Results', total_points_possible: 7.5, score: 5.5, instructor_graded_score_pending?: false)
        
        submission.submit(decimal_results)
        
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_possible: 7.5))
      end

      it 'preserves other settings when points_possible is included' do
        submission.submit(results)
        
        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit) do |user_id, section_id, activity_id, school_id, settings|
            # Verify that other important settings are still included
            expect(settings).to include(:points_earned, :points_pending, :pending, :time_spent, :submitted_at, :attempt_count)
            expect(settings[:points_possible]).to eq(50)
          end
      end

      context 'when an activity has been reset and resubmitted' do
        it 'uses new points_possible after activity reset' do
          # First submission with old points_possible
          old_results = double('Results', total_points_possible: 10, score: 8, instructor_graded_score_pending?: false)
          submission.submit(old_results)
          
          # Second submission with new points_possible (simulating activity revision)
          new_results = double('Results', total_points_possible: 100, score: 90, instructor_graded_score_pending?: false)
          submission.submit(new_results)
          
          # Verify the second call uses the new points_possible
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(points_possible: 100))
        end
      end
    end
  end

  describe '#submit_nongradable' do
    context 'when used on a nongradable activity' do
      let(:student) { create(:student) }
      let(:section) { create(:section, :program => create(:program)) }
      let(:activity) { create(:activity) }
      let(:submission) { Gradebook::Submission.new(student, section, activity) }

      before do
        allow(activity).to receive(:gradable?).and_return(false)
        allow(GradebookEngine::GradebookAPI).to receive(:submit)
      end

      it 'creates a score with 1 points earned' do
        submission.submit_nongradable()

        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(student.id, section.id, activity.id, section.school_id,
                hash_including(points_earned: 1))
      end

      context 'when time spent is specified' do
        it 'creates a score with the specified time spent' do
          submission.submit_nongradable(12345)

          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(time_spent: 12345))
        end
      end

      context 'when no time spent is specified' do
        it 'creates a score with time spent of 0' do
          submission.submit_nongradable()

          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(time_spent: 0))
        end
      end

      context 'when a submitted_at date is specified' do
        it 'creates a score with the specified submitted_at date' do
          submit_time = 3.days.ago
          submission.submit_nongradable(time_spent = 0, submit_time )

          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(submitted_at: submit_time))
        end
      end
    end

    context 'when used on a gradable activity' do
      let(:student) { create(:student) }
      let(:section) { create(:section, :program => create(:program)) }
      let(:activity) { create(:activity) }
      let(:submission) { Gradebook::Submission.new(student, section, activity) }

      before do
        allow(activity).to receive(:gradable?).and_return(true)
        allow(GradebookEngine::GradebookAPI).to receive(:submit)
      end

      it 'raises an exception' do
        expect do
          submission.submit_nongradable()
        end.to raise_error 'submit_nongradable can only called for activities that are non-gradable'
      end
    end
  end

  describe "submit_points" do
    let(:student) { create(:student) }
    let(:school) { build_stubbed(:school) }
    let(:program) { build_stubbed(:program) }
    let(:instructor) { build_stubbed(:instructor) }

    let(:course) do
      build_stubbed(:course, school: school,
                             program: program,
                             owner: instructor,
                             start_date: 6.months.ago,
                             end_date: 6.months.from_now)
    end

    let(:section) { create(:section, course: course, instructor: instructor) }
    let(:activity) { build_stubbed(:activity) }
    let(:category) { create(:category, weighting_percent: 100) }

    let(:lesson) { build_stubbed(:lesson) }
    let(:unit) { build_stubbed(:unit, program_id: 1, lessons: [lesson]) }
    let(:toc_entry) { build_stubbed(:toc_entry) }
    let(:submission) { Gradebook::Submission.new(student, section, activity) }

    around do |example|
      Timecop.travel(Time.local(2011, 2, 24, 12, 5).in_time_zone) do
        example.run
      end
    end

    before do
      section.students << student
      allow(activity).to receive(:lesson).and_return(lesson)
      allow(activity).to receive(:program).and_return(program)
      allow(lesson).to receive(:strand_for_toc_location).and_return(toc_entry)
      allow(Activity).to receive(:find).and_return(activity)
      allow(GradebookEngine::GradebookAPI).to receive(:submit)
    end

    it 'raises an error on a missing required parameter' do
      required_params = { points_possible: 0,
                          points_earned: 0,
                          pending: false,
                          submitted_at: 0,
                          time_spent: 0,
                          gradable: true }
      submission = Gradebook::Submission.new(student, section, activity)
      required_params.keys.each do |param|
        expect { submission.submit_points(required_params.merge(param => nil)) }
          .to raise_error "#{param} param required"
      end
    end

    it "sets points pending to the passed value if activity is pending" do
      submission.submit_points(points_possible: 100,
                               points_earned: 95,
                               points_pending: 100,
                               pending: true,
                               submitted_at: Time.zone.now,
                               time_spent: '595',
                               gradable: true)

      expect(GradebookEngine::GradebookAPI)
        .to have_received(:submit)
        .with(student.id, section.id, activity.id, section.school_id,
              hash_including(points_pending: 100))
    end

    it "sets points pending to 0 if score is not pending" do
      submission.submit_points(points_possible: 100,
                               points_earned: 95,
                               points_pending: 100,
                               pending: false,
                               submitted_at: Time.zone.now,
                               time_spent: '595',
                               gradable: true)

      expect(GradebookEngine::GradebookAPI)
        .to have_received(:submit)
        .with(student.id, section.id, activity.id, section.school_id,
              hash_including(points_pending: 0))
    end

    context 'when activity is non-gradable' do
      context 'and already viewed' do
        it 'does not update submitted_at' do
          first_submitted_at = 2.days.ago

          score = double(GradebookEngine::ScoreAction,
                           points_earned: 1.0,
                           points_possible: 1,
                           pending: false,
                           submitted_at: first_submitted_at)
          allow(GradebookEngine::GradebookAPI)
            .to receive(:find_score)
            .and_return(score)

          new_submit_time = Time.zone.now
          submission.submit_points(points_possible: 1,
                                   points_earned: 1.0,
                                   pending: false,
                                   submitted_at: new_submit_time,
                                   time_spent: '595',
                                   gradable: false)
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(submitted_at: first_submitted_at))
        end
      end

      context "and viewing for the first time" do
        it "sets submitted_at" do
          submit_time = Time.zone.now
          submission.submit_points(points_possible: 1,
                                   points_earned: 1.0,
                                   pending: false,
                                   submitted_at: submit_time,
                                   time_spent: '595',
                                   gradable: false)
          expect(GradebookEngine::GradebookAPI)
            .to have_received(:submit)
            .with(student.id, section.id, activity.id, section.school_id,
                  hash_including(submitted_at: submit_time))
        end
      end
    end
  end

  describe '#create_demo_score' do
    let(:student) { create(:student) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }
    let(:submission) { Gradebook::Submission.new(student, section, activity) }

    context 'when activities are gradable' do
      before do
        allow(activity).to receive(:gradable?).and_return(true)
      end

      it 'does not create score records for unsubmitted attempts' do
        attempt = create(:attempt_opened, :section => section, :user => student, :activity => activity)

        expect(submission).not_to receive(:submit)
        submission.create_demo_score(attempt, Time.now)
      end

      it 'creates score records for autograded activities' do
        allow(activity).to receive(:instructor_graded?).and_return(false)

        attempt = create(:attempt_submitted, :section => section, :user => student, :activity => activity)

        results = double(MaestroActivityEngine::ActivityContent::Results, :total_points_possible => 10, :score => 0.9,
                                                   :instructor_graded_points_possible => 0,
                                                   :instructor_graded_score_pending? => false)
        allow(attempt).to receive(:results).and_return(results)
        submitted_at = Time.now

        expect(submission).to receive(:submit).with(results, submitted_at, attempt.time_spent, attempt.submission_length)
        submission.create_demo_score(attempt, submitted_at)
      end

      it 'creates score records for instructor graded activities' do
        attempt = create(:attempt_completed, :section => section, :user => student, :activity => activity)

        results = double(MaestroActivityEngine::ActivityContent::Results, :total_points_possible => 10, :score => 0.9,
                                                   :instructor_graded_points_possible => 2,
                                                   :instructor_graded_score_pending? => true)
        allow(attempt).to receive(:results).and_return(results)
        allow(attempt).to receive(:submission_length).and_return(500)
        submitted_at = Time.now

        expect(submission).to receive(:submit).with(results, submitted_at, attempt.time_spent, attempt.submission_length)
        submission.create_demo_score(attempt, submitted_at)
      end
    end

    it 'creates score records for ungradable activities' do
      allow(activity).to receive(:instructor_graded?).and_return(false)
      allow(activity).to receive(:gradable?).and_return(false)
      attempt = create(:attempt, :section => section, :user => student, :activity => activity)
      submitted_at = Time.now

      expect(submission).to receive(:submit_nongradable).with(attempt.time_spent, submitted_at)
      submission.create_demo_score(attempt, submitted_at)
    end
  end
end
