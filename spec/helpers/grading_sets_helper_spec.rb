describe GradingSetsHelper do
  include GradingSetsHelper

  let(:status_hash){ {:status_class => 'status', :remaining => 2} }

  describe "#format_progress_box_class" do
    context "when on the current question" do
      it "returns the status class and 'current' to be used on the progress box div" do
        expect(format_progress_box_class(status_hash, true)).to eql 'status current'
      end
    end

    context "when not on the current question" do
      it "returns the status class to be used on the progress box div" do
        expect(format_progress_box_class(status_hash)).to eql 'status'
      end
    end
  end

  describe "#format_progress_box_style" do
    context "when an activity does not have a concept color" do
      it "returns nil" do
        expect(format_progress_box_style('', false)).to be_nil
      end
    end

    context "when on the current question or student" do
      it "returns the concept color as the background color of the box in the progress bar" do
        expect(format_progress_box_style('red', true)).to eql 'background-color: red;'
      end
    end

    context "when not on the current question or student" do
      it "returns the concept color as the border color of the box in the progress bar" do
        expect(format_progress_box_style('red', false)).to eql 'border-color: red; width: 23px;'
      end
    end
  end

  describe "#format_progress_status" do
    context "when in student by student mode" do
      context "when the grading status of the student passed in is complete (no more questions to grade)" do
        let(:status_hash){ {:status_class => 'complete', :remaining => 2} }
        it "returns 'Complete'" do
          expect(format_progress_status(status_hash, :question, false)).to eql 'Complete'
        end
      end

      context "when the grading status of the student passed in is not complete, or it is the current student" do
        it "returns the number of questions remaining" do
          expect(format_progress_status(status_hash, :question, true)).to eql '2 questions remaining'
        end
      end
    end
  end
end

