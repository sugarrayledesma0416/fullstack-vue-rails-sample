describe Smartbook::ScoreCalculator do
  let(:activity) do
    instance_double(
      Activity,
      content_object: content_object,
      points_possible: content_object.points_possible
    )
  end
  let(:auto_graded_points_possible) { 4.0 }
  let(:instructor_graded_points_possible) { 20.0 }
  let(:content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::SmartBookContent,
      auto_graded_points_possible: auto_graded_points_possible,
      instructor_graded_points_possible: instructor_graded_points_possible,
      points_possible: auto_graded_points_possible + instructor_graded_points_possible
    )
  end
  let(:latest_auto_graded_responses) { [] }
  let(:latest_instructor_graded_responses) { [] }
  let(:smartbook_responses) do
    instance_double(
      Smartbook::Responses,
      latest_auto_graded_responses: latest_auto_graded_responses,
      latest_instructor_graded_responses: latest_instructor_graded_responses
    )
  end
  let(:attempt) do
    instance_double(
      Attempt,
      activity: activity,
      smartbook_responses: smartbook_responses,
      feedback_items: feedback_items
    )
  end
  let(:feedback_items) { [] }
  let(:calculator) { described_class.new(attempt) }

  before do
    allow(attempt).to receive(:feedback_item) do |question_label|
      feedback_items.detect do |fb_item|
        fb_item.question_label == question_label
      end
    end
  end

  describe '#points_earned' do
    context 'when there is no question,' do
      it 'returns 0' do
        expect(calculator.points_earned).to eq(0)
      end
    end

    context 'when the student submitted auto-graded questions' do
      let(:question_1) do
        instance_double(
          Smartbook::Response,
          label: 'question 01',
          points_possible: 5.0,
          points_earned: 3.0,
          submission_time: Time.zone.now
        )
      end
      let(:question_2) do
        instance_double(
          Smartbook::Response,
          label: 'question 02',
          points_possible: 10.0,
          points_earned: 7.0,
          submission_time: Time.zone.now
        )
      end
      let(:latest_auto_graded_responses) { [question_1, question_2] }
      let(:auto_graded_points_possible) do
        question_1.points_possible + question_2.points_possible
      end
      let(:instructor_graded_points_possible) { 0 }
      let(:feedback_items) { [] }

      context 'when an auto-graded question has no feedback item,' do
        it 'uses the points earned from the smartbook response' do
          points_earned = question_1.points_earned + question_2.points_earned
          points_possible = question_1.points_possible + question_2.points_possible
          expect(calculator.points_earned).to eq(
            (points_earned / points_possible) * activity.points_possible
          )
        end
      end

      context 'when an auto-graded question has a feedback item with a score,' do
        context 'when the feedback item has no score,' do
          let(:feedback_items) do
            [
              instance_double(
                FeedbackItem,
                question_label: question_2.label,
                points_earned: nil,
                updated_at: Time.zone.now
              )
            ]
          end

          it 'uses the points earned from the smartbook response' do
            points_earned = question_1.points_earned + question_2.points_earned
            points_possible = question_1.points_possible + question_2.points_possible
            expect(calculator.points_earned).to eq(
              (points_earned / points_possible) * activity.points_possible
            )
          end
        end

        context 'when the feedback item has a score,' do
          let(:feedback_item_question_2) do
            instance_double(
              FeedbackItem,
              question_label: question_2.label,
              points_earned: 1.5,
              updated_at: Time.zone.now
            )
          end
          let(:feedback_items) do
            [feedback_item_question_2]
          end

          it 'uses the points earned from the feedback item' do
            points_earned = question_1.points_earned + feedback_item_question_2.points_earned
            points_possible = question_1.points_possible + question_2.points_possible
            expect(calculator.points_earned).to eq(
              (points_earned / points_possible) * activity.points_possible
            )
          end
        end

        context 'when the feedback item is older than the latest response,' do
          let(:question_2) do
            instance_double(
              Smartbook::Response,
              label: 'question 02',
              points_possible: 10.0,
              points_earned: 10.0,
              submission_time: Time.zone.now + 1.day
            )
          end
          let(:feedback_item_question_2) do
            instance_double(
              FeedbackItem,
              question_label: question_2.label,
              points_earned: 1.5,
              updated_at: Time.zone.now
            )
          end
          let(:feedback_items) do
            [feedback_item_question_2]
          end

          it 'uses the points earned from the smartbook response' do
            points_earned = question_1.points_earned + question_2.points_earned
            points_possible = question_1.points_possible + question_2.points_possible
            expect(calculator.points_earned).to eq(
              (points_earned / points_possible) * activity.points_possible
            )
          end
        end
      end

      context 'when an auto-graded question is not submitted,' do
        let(:latest_auto_graded_responses) { [question_1] }

        it 'considers the question is worth 0 points' do
          points_earned = question_1.points_earned
          points_possible = question_1.points_possible + question_2.points_possible
          expect(calculator.points_earned).to eq(
            (points_earned / points_possible) * activity.points_possible
          )
        end
      end
    end

    context 'when the student submitted instructor-graded questions' do
      let(:question_1) do
        instance_double(
          Smartbook::Response,
          label: 'question 01',
          points_possible: 5.0,
          submission_time: Time.zone.now
        )
      end
      let(:question_2) do
        instance_double(
          Smartbook::Response,
          label: 'question 02',
          points_possible: 10.0,
          submission_time: Time.zone.now
        )
      end
      let(:latest_instructor_graded_responses) { [question_1, question_2] }
      let(:auto_graded_points_possible) { 0.0 }
      let(:instructor_graded_points_possible) do
        question_1.points_possible + question_2.points_possible
      end
      let(:feedback_item_question_1) do
        instance_double(
          FeedbackItem,
          question_label: question_1.label,
          points_earned: 1.5,
          updated_at: Time.zone.now
        )
      end
      let(:feedback_items) do
        [feedback_item_question_1]
      end

      context 'when an instructor-graded question has no feedback item,' do
        it 'ignores the question' do
          expect(calculator.points_earned).to eq(
            (feedback_item_question_1.points_earned / question_1.points_possible) * activity.points_possible
          )
        end
      end

      context 'when an instructor-graded question has a feedback item,' do
        context 'when the feedback item has no score,' do
          let(:feedback_item_question_2) do
            instance_double(
              FeedbackItem,
              question_label: question_2.label,
              points_earned: nil,
              updated_at: Time.zone.now
            )
          end
          let(:feedback_items) do
            [
              feedback_item_question_1,
              feedback_item_question_2
            ]
          end

          it 'ignores the question' do
            expect(calculator.points_earned).to eq(
              (feedback_item_question_1.points_earned / question_1.points_possible) * activity.points_possible
            )
          end
        end

        context 'when the feedback item has a score,' do
          let(:feedback_item_question_2) do
            instance_double(
              FeedbackItem,
              question_label: question_2.label,
              points_earned: 1.5,
              updated_at: Time.zone.now
            )
          end
          let(:feedback_items) do
            [
              feedback_item_question_1,
              feedback_item_question_2
            ]
          end

          it 'uses the points earned from the feedback item' do
            points_earned = feedback_item_question_1.points_earned + feedback_item_question_2.points_earned
            points_possible = question_1.points_possible + question_2.points_possible
            expect(calculator.points_earned).to eq(
              (points_earned / points_possible) * activity.points_possible
            )
          end
        end

        context 'when the feedback item is older than the latest response,' do
          let(:question_2) do
            instance_double(
              Smartbook::Response,
              label: 'question 02',
              points_possible: 10.0,
              submission_time: Time.zone.now + 1.day
            )
          end
          let(:feedback_item_question_2) do
            instance_double(
              FeedbackItem,
              question_label: question_2.label,
              points_earned: 1.5,
              updated_at: Time.zone.now
            )
          end
          let(:feedback_items) do
            [
              feedback_item_question_1,
              feedback_item_question_2
            ]
          end

          it 'ignores the question' do
            expect(calculator.points_earned).to eq(
              (feedback_item_question_1.points_earned / question_1.points_possible) * activity.points_possible
            )
          end
        end
      end

      context 'when an instructor-graded question is not submitted,' do
        let(:latest_instructor_graded_responses) { [question_1] }

        it 'considers the question is worth 0 points' do
          points_earned = feedback_item_question_1.points_earned
          points_possible = question_1.points_possible + question_2.points_possible
          expect(calculator.points_earned).to eq(
            (points_earned / points_possible) * activity.points_possible
          )
        end
      end
    end

    context 'when the student submitted instructor-graded and auto-graded questions' do
      let(:auto_graded_question) do
        instance_double(
          Smartbook::Response,
          label: 'question 01',
          points_possible: 5.0,
          points_earned: 4.0,
          submission_time: Time.zone.now
        )
      end
      let(:instructor_graded_question) do
        instance_double(
          Smartbook::Response,
          label: 'question 02',
          points_possible: 10.0,
          submission_time: Time.zone.now
        )
      end
      let(:latest_auto_graded_responses) { [auto_graded_question] }
      let(:latest_instructor_graded_responses) { [instructor_graded_question] }
      let(:auto_graded_points_possible) { auto_graded_question.points_possible }
      let(:instructor_graded_points_possible) { instructor_graded_question.points_possible }
      let(:feedback_item) do
        instance_double(
          FeedbackItem,
          question_label: instructor_graded_question.label,
          points_earned: 6.0,
          updated_at: Time.zone.now
        )
      end
      let(:feedback_items) { [feedback_item] }

      it 'uses the points earned from instructor-graded and auto-graded questions' do
        points_earned = auto_graded_question.points_earned + feedback_item.points_earned
        points_possible = auto_graded_question.points_possible + instructor_graded_question.points_possible
        expect(calculator.points_earned).to eq(
          (points_earned / points_possible) * activity.points_possible
        )
      end
    end
  end
end
