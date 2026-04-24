module ActivityTest
  module RecordingV2Helpers
    def listen_to_question(question)
      with_element(question.button(:listen)) do |button|
        expect(button).not_to be_active

        step 'Start listening' do
          button.click
        end

        step 'The button is now active' do
          Waiter.new.wait { button.active? }
        end

        step 'The button is no more active when reaching the end of the audio file' do
          Waiter.new.wait(5) { !button.active? }
        end
      end
    end

    def record_audio_file(question)
      with_element(question.button(:record)) do |button|
        step 'I can submit the activity before recording' do
          expect(@page_object.button(:submit)).not_to be_disabled
        end

        step 'Start recording' do
          button.click
        end

        step 'The record button becomes active' do
          Waiter.new.wait { button.active? }
        end

        step 'I cannot submit the activity while recording' do
          expect(@page_object.button(:submit)).to be_disabled
        end

        step 'Stop recording' do
          button.click
        end

        step 'The record button is no more active' do
          Waiter.new.wait { !button.active? }
        end

        purpose 'I can submit the activity' do
          Waiter.new.wait do
            !@page_object.button(:submit).disabled?
          end
        end

        purpose 'Now the review button is visible and enabled' do
          Waiter.new.wait do
            review_button = question.button(:review)
            review_button.enabled? && !review_button.loading?
          end
        end
      end
    end

    def listen_to_review(question)
      with_element(question.button(:review)) do |button|
        step 'Listen to review' do
          button.click
        end

        step 'The review button becomes active' do
          Waiter.new.wait { button.active? }
        end

        step 'Stop listening to review' do
          button.click
        end

        step 'The review button is no more active' do
          Waiter.new.wait { !button.active? }
        end
      end
    end
  end
end

