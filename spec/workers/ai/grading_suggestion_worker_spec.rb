RSpec.describe AI::GradingSuggestionWorker do
  let(:activity) { create(:activity) }
  let(:section) { create(:section) }
  let(:attempt1) { create(:attempt, activity: activity, section: section) }
  let(:attempt2) { create(:attempt, activity: activity, section: section) }
  let(:attempt3) { create(:attempt, activity: activity, section: section) }
  let(:attempt_ids) { [attempt1.id, attempt2.id, attempt3.id] }

  before do
    allow(Activity).to receive(:find).with(activity.id).and_return(activity)
    allow(Section).to receive(:find).with(section.id).and_return(section)
    allow(Attempt).to receive(:where).with(activity_id: activity.id, section_id: section.id)
                                     .and_return([attempt1, attempt2])
  end

  describe "#perform" do
    context "when processing attempts" do
      before do
        allow(Attempt).to receive(:where).with(id: attempt_ids).and_return([attempt1, attempt2, attempt3])
      end

      it "fetches the correct attempts" do
        described_class.new.perform(attempt_ids)
        expect(Attempt).to have_received(:where).with(id: attempt_ids)
      end

      context "when some attempts already have completed jobs" do
        before do
          create(:ai_grading_suggestion_job,
            attempt: attempt1,
            status: 'completed'
          )
        end

        it "only processes attempts without completed jobs" do
          suggestion_generator = instance_double(AI::GradingSuggestionGenerators::ActivityGenerator)
          comment_generator = instance_double(AI::OverallCommentGenerators::ActivityGenerator)

          allow(AI::GradingSuggestionGenerators::ActivityGenerator)
            .to receive(:new)
            .and_return(suggestion_generator)
          allow(AI::OverallCommentGenerators::ActivityGenerator)
            .to receive(:new)
            .and_return(comment_generator)
          allow(suggestion_generator).to receive(:generate)
          allow(comment_generator).to receive(:generate)

          described_class.new.perform(attempt_ids)

          # Should only process attempt2 and attempt3
          expect(AI::GradingSuggestionGenerators::ActivityGenerator)
            .to have_received(:new)
            .exactly(2).times
            .with(attempt: anything, grading_suggestion_input: nil)

          expect(AI::OverallCommentGenerators::ActivityGenerator)
            .to have_received(:new)
            .exactly(2).times
            .with(attempt: anything, grading_suggestion_input: nil)
        end
      end

      context "when generating suggestions" do
        it "calls both generators for each attempt without completed jobs" do
          suggestion_generator = instance_double(AI::GradingSuggestionGenerators::ActivityGenerator)
          comment_generator = instance_double(AI::OverallCommentGenerators::ActivityGenerator)

          expect(AI::GradingSuggestionGenerators::ActivityGenerator)
            .to receive(:new)
            .exactly(3).times
            .with(attempt: anything, grading_suggestion_input: nil)
            .and_return(suggestion_generator)

          expect(AI::OverallCommentGenerators::ActivityGenerator)
            .to receive(:new)
            .exactly(3).times
            .with(attempt: anything, grading_suggestion_input: nil)
            .and_return(comment_generator)

          expect(suggestion_generator).to receive(:generate).exactly(3).times
          expect(comment_generator).to receive(:generate).exactly(3).times

          described_class.new.perform(attempt_ids)
        end
      end
    end

    context "when handling Sidekiq configuration" do
      it "is enqueued in the default queue" do
        expect {
          described_class.perform_async(attempt_ids)
        }.to change(described_class.jobs, :size).by(1)

        expect(described_class.jobs.last["queue"]).to eq("default")
      end

      it "has the correct retry configuration" do
        expect(described_class.get_sidekiq_options["retry"]).to eq(3)
      end
    end
  end
end
