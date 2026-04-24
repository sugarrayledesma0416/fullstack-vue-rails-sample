describe ScoreControlsViewManager do
  let(:feedback_item) { instance_double(FeedbackItem, points_earned: '4.5') }
  let(:klass_prefix) { MaestroActivityEngine::ActivityContent }
  let(:question) { instance_double(klass_prefix::OpenEnded::Item) }
  let(:results) { instance_double(klass_prefix::Results) }
  let(:response_id) { 'response_01' }

  describe '#attempt_id' do
    let(:presenter) { instance_double('StudentByStudentPresenter') }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor) }
    let(:student) { create(:student) }
    let(:section) { create(:section, course: course) }
    let(:activity) { create(:activity) }

    let!(:student_attempt) do
      create(
        :attempt_submitted,
        activity: activity,
        section: section,
        user: student
      )
    end

    context 'when feedback_item is present' do
      let(:view_manager) do
        described_class.new(
          question,
          feedback_item,
          results,
          response_id,
          {}
        )
      end

      before do
        allow(feedback_item).to receive(:attempt_id).and_return(student_attempt.id)
      end

      it 'returns the feedback_item attempt_id' do
        expect(view_manager.attempt_id(presenter, student.id)).to eq(feedback_item.attempt_id)
      end
    end

    context 'when feedback_item is not present' do
      let(:view_manager) do
        described_class.new(
          question,
          nil,
          results,
          response_id,
          {}
        )
      end

      let(:grading_feedback) { instance_double(GradingFeedback) }

      before do
        allow(presenter).to receive(:feedback).and_return(grading_feedback)
        allow(grading_feedback).to receive(:attempt_for_student)
          .and_return(student_attempt)
      end

      it 'returns the grading_feedback attempts id' do
        expect(view_manager.attempt_id(presenter, student.id)).to eq(
          grading_feedback.attempt_for_student(student).id
        )
      end
    end
  end

  describe '#score_field' do
    it 'returns the response_id prefixed with "score_for_"' do
      presenter = described_class.new(
        question,
        feedback_item,
        results,
        response_id,
        {}
      )
      expect(presenter.score_field).to eq("score_for_#{response_id}")
    end
  end

  describe '#question_points' do
    context 'when score is present in params,' do
      it 'returns the points earned from the score params' do
        params = { "score_for_#{response_id}" => '5.0' }
        presenter = described_class.new(
          question,
          feedback_item,
          results,
          response_id,
          params
        )
        expect(presenter.question_points).to eq('5.0')
      end
    end

    context 'when score is not present in params,' do
      context 'when question is a Smartbook Response,' do
        let(:question) { ::Smartbook::Response.new({}) }

        context 'when the question has no response,' do
          let(:response) { nil }

          context 'when the question is instructor graded,' do
            before do
              allow(question).to receive(:instructor_gradable?).and_return(true)
            end

            it 'returns score from feedback item when present' do
              presenter = described_class.new(
                question,
                feedback_item,
                response,
                response_id,
                {}
              )
              expect(presenter.question_points).to eq('4.5')
            end

            it 'returns an empty string when there is no feedback item' do
              presenter = described_class.new(
                question,
                nil,
                response,
                response_id,
                {}
              )
              expect(presenter.question_points).to eq('')
            end
          end

          context 'when the question is auto graded,' do
            before do
              allow(question).to receive(:instructor_gradable?).and_return(false)
            end

            it 'returns score from feedback item when present' do
              presenter = described_class.new(
                question,
                feedback_item,
                response,
                response_id,
                {}
              )
              expect(presenter.question_points).to eq('4.5')
            end

            it 'returns zero when there is no feedback item' do
              presenter = described_class.new(
                question,
                nil,
                response,
                response_id,
                {}
              )
              expect(presenter.question_points).to eq(0.0)
            end
          end
        end

        context 'when the Smartbook Response is instructor gradable,' do
          let(:response) { ::Smartbook::Response.new({}) }

          before do
            allow(question).to receive(:instructor_gradable?).and_return(true)
          end

          it 'returns score from feedback item when present' do
            presenter = described_class.new(
              question,
              feedback_item,
              response,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq('4.5')
          end

          it 'returns empty string when there is no feedback item' do
            presenter = described_class.new(
              question,
              nil,
              response,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq('')
          end
        end

        context 'when the Smartbook Response is not instructor gradable,' do
          let(:response) { ::Smartbook::Response.new({}) }

          before do
            allow(question).to receive(:instructor_gradable?).and_return(false)
          end

          it 'returns score from feedback item when present' do
            presenter = described_class.new(
              question,
              feedback_item,
              response,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq('4.5')
          end

          it 'calculates the score from the results when there is no feedback item' do
            allow(response).to receive(:score).and_return(0.5)
            allow(question).to receive(:points_possible).and_return(20)
            presenter = described_class.new(
              question,
              nil,
              response,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq(10.0)
          end
        end
      end
    end

    context 'when question is instructor gradable,' do
      let(:question) do
        klass_prefix::OpenEnded::Item.new
      end

      it 'returns the score from the feedback item if one is specified' do
        presenter = described_class.new(
          question,
          feedback_item,
          results,
          response_id,
          {}
        )
        expect(presenter.question_points).to eq('4.5')
      end

      it 'returns an empty string if no feedback item is specified' do
        presenter = described_class.new(
          question,
          nil,
          results,
          response_id,
          {}
        )
        expect(presenter.question_points).to eq('')
      end
    end

    context 'when question is a TrueFalseEnhanced item,' do
      let(:question) do
        klass_prefix::TrueFalseEnhanced::Item.new(rank: 1)
      end

      context 'when the question is marked as pending in the results,' do
        before do
          allow(results).to receive(:correctness).and_return('pending')
        end

        it 'returns the score from the feedback item if one is specified' do
          presenter = described_class.new(
            question,
            feedback_item,
            results,
            response_id,
            {}
          )
          expect(presenter.question_points).to eq('4.5')
        end

        it 'returns an empty string if no feedback item is specified' do
          presenter = described_class.new(
            question,
            nil,
            results,
            response_id,
            {}
          )
          expect(presenter.question_points).to eq('')
        end
      end

      context 'when the question is not marked as pending in the results,' do
        before do
          allow(results).to receive(:correctness).and_return('correct')
        end

        context 'when a feedback item is specified,' do
          it 'returns the score from the feedback item if it is not nil' do
            presenter = described_class.new(
              question,
              feedback_item,
              results,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq('4.5')
          end

          it 'returns the score from the results if the feeback item score is nil' do
            allow(feedback_item).to receive(:points_earned).and_return(nil)
            allow(results).to receive(:points_earned).and_return('7')

            presenter = described_class.new(
              question,
              feedback_item,
              results,
              response_id,
              {}
            )
            expect(presenter.question_points).to eq(7.0)
          end
        end

        it 'returns the score from results when no feedback item is specified' do
          allow(results).to receive(:points_earned).and_return('7')

          presenter = described_class.new(
            question,
            nil,
            results,
            response_id,
            {}
          )
          expect(presenter.question_points).to eq(7.0)
        end
      end
    end

    context 'when question is not instructor gradable' do
      let(:question) do
        klass_prefix::FillInTheBlanks::Item.new(rank: 1)
      end

      context 'when a feedback item is specified,' do
        it 'returns the score from the feedback item if it is not nil' do
          presenter = described_class.new(
            question,
            feedback_item,
            results,
            response_id,
            {}
          )
          expect(presenter.question_points).to eq('4.5')
        end

        it 'returns the score from the results if the feeback item score is nil' do
          allow(feedback_item).to receive(:points_earned).and_return(nil)
          allow(results).to receive(:points_earned).and_return('7')

          presenter = described_class.new(
            question,
            feedback_item,
            results,
            response_id,
            {}
          )
          expect(presenter.question_points).to eq(7.0)
        end
      end

      it 'returns the score from results when no feedback item is specified' do
        allow(results).to receive(:points_earned).and_return('7')

        presenter = described_class.new(
          question,
          nil,
          results,
          response_id,
          {}
        )
        expect(presenter.question_points).to eq(7.0)
      end
    end
  end

  describe '#recording_path' do
    let(:response) { OpenStruct.new(recording_path: '/path/to/archive.mp4') }
    let(:results_with_recordings) do
      [{ label: 'question label', response: response }, { label: 'foo', response: 'bar' }]
    end

    let(:view_manager) do
      described_class.new(
        question,
        feedback_item,
        results_with_recordings,
        response_id,
        {}
      )
    end

    it 'returns the recording path for a chat type result' do
      allow(question).to receive(:label).and_return('question label')
      expect(view_manager.recording_path).to eq('/path/to/archive.mp4')
    end
  end
end
