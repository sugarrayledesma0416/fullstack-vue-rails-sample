describe Instructor::AssignablesHelper do
  include Instructor::AssignablesHelper
  include ApplicationHelper
  describe "#show_icons_for_activity" do
    context "when the assignable is instructor gradeable" do
      it "returns the instructor gradeable icon" do
        activity = build_stubbed(:activity)
        allow(activity).to receive(:instructor_graded?).and_return(true)
        assignable = instance_double(InstructorAssignablesPresenter::Assignable, assignable: activity)
        allow(assignable).to receive(:icon) { '' }
        # This method is delegated in the Assignable class
        allow(assignable).to receive(:instructor_graded?) { activity.instructor_graded? }

        expected_text = content_tag(:span, :id => 'instructor_graded', :class => "icon") { image_tag('icon_person.png', :title => "instructor graded") }
        expect(show_icons_for_activity(assignable)).to include(expected_text)
      end
    end
    context "when the assignment is not instructor gradable" do
      it "does not return the instructor gradable icon" do
        activity = build_stubbed(:activity)
        allow(activity).to receive(:instructor_graded?).and_return(false)
        assignable = instance_double(InstructorAssignablesPresenter::Assignable, assignable: activity)
        allow(assignable).to receive(:icon) { '' }
        # This method is delegated in the Assignable class
        allow(assignable).to receive(:instructor_graded?) { activity.instructor_graded? }

        instructor_gradable_icon = content_tag(:span, :id => 'instructor_graded', :class => "icon") { image_tag('icon_person.png', :title => "instructor graded") }
        expect(show_icons_for_activity(assignable)).not_to include(instructor_gradable_icon)
      end
    end
  end
end
