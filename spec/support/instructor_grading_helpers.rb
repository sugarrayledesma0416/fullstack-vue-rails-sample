module InstructorGradingHelpers
  def expect_no_grading_list_item(activity:)
    expect(@page_object).to have_no_grading_list_item(activity)
  end

  def expect_grading_list_item(activity:, count:)
    expect(@page_object.grading_list_item(activity).graded_count).to match(/#{count}.*graded/)
  end

  def for_instructor_grading_tasks_assignments_page
    @page_object = InstructorGradingTaskAssignmentsPageObject.new
    yield @page_object
    @page_object = nil
  end

  class InstructorGradingTaskAssignmentsPageObject
    include Capybara::DSL

    def needs_grading_section_count
      find_or_fail(
        '#needs_grading_section_to_grade.circled', __method__
      ).text
    end

    def upcoming_grading_section_count
      find_or_fail(
        '#upcoming_grading_section_to_grade.circled', __method__
      ).text
    end

    def already_graded_section_count
      find_or_fail(
        '#already_graded_section_to_grade.circled', __method__
      ).text
    end

    def unassigned_activities_section_count
      find_or_fail(
        '#unassigned_activities_section_to_grade.circled', __method__
      ).text
    end

    def grading_list_item(activity)
      GradingListItem.new(self, activity)
    end

    def has_no_grading_list_item?(activity)
      GradingListItem.new(self, activity).not_exist?
    end

    class GradingListItem
      attr_reader :activity, :page_object

      def initialize(page_object, activity)
        @page_object = page_object
        @activity = activity
      end

      def not_exist?
        page_object.has_no_selector?(selector, text: activity.title, visible: true)
      end

      def graded_count
        # Even though we want to find the li, it has no identifying information
        # so we have to find the activity link within it, then use xpath to
        # get to the parent item.
        # element is a link inside a li in a ul. To find graded item we have to
        # get the parent of parent, that means get ul, then we find graded item.
        list_item = element.find(:xpath, '..').find(:xpath, '..')
        list_item.find('.graded').text
      end

      def click
        element.click
      end

      private def selector
        '.c-activity-grading__link'
      end

      private def element
        page_object.find(selector, text: activity.title)
      end
    end

    # Find a capybara element on the page using the selector `selector` and raise
    # an error if the element is not found.
    def find_or_fail(selector, target)
      page.find(selector)
    rescue StandardError => e
      raise Capybara::ExpectationNotMet, "Unable to find #{target} " \
        "using selector '#{selector}'.\nCaused by: #{e.class}: #{e.message}"
    end
  end
end
