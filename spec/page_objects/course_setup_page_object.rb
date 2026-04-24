require 'page_objects/page_object'
require 'page_objects/button_object'

class CourseSetupPathPageObject < PageObject
  def button(id)
    element = case id
              when :express_setup
                expect(page).to have_selector('.test-path-step__express-setup-button')
                page.find('.test-path-step__express-setup-button')
              when :advanced_setup
                expect(page).to have_selector('.test-path-step__advance-setup-button')
                page.find('.test-path-step__advance-setup-button')
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end
end
