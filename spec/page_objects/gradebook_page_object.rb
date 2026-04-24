class GradebookPageObject < PageObject
  def category_column_wrapper(category)
    expect(page).to have_selector('.test-grades-column .test-category-name', text: category)
    page.find('.test-grades-column .test-category-name', text: category).first(:xpath, './/..')
  end

  def visit_category_contextual_menu(category, menu_entry)
    page.within(category_column_wrapper(category)) do
      page.find('a.test-gear-menu-opener').click
      page.find('a', text: menu_entry).click
    end
  end

  def category_weighting_percent(category)
    category_column_wrapper(category).has_selector?(category_weighting_percent_selector)
    category_column_wrapper(category).find(category_weighting_percent_selector).value
  end

  def change_category_weighting_percent(category, value)
    category_column_wrapper(category).has_selector?(category_weighting_percent_selector)
    category_column_wrapper(category).find(category_weighting_percent_selector).set(value)
  end

  def category_weighting_percent_selector
    'input[name="weighting_percent"]'
  end

  def add_category_modal
    AddGradebookCategoryPageObject.new(
      page.find('.test-add-category-modal')
    )
  end

  def has_no_add_category_modal?
    page.has_no_selector?('.test-add-category-modal', visible: true)
  end

  def edit_category_modal
    EditGradebookCategoryPageObject.new(
      page.find('.test-edit-category-modal')
    )
  end

  def has_no_edit_category_modal?
    page.has_no_selector?('.test-editcategory-modal', visible: true)
  end

  def view_tutorial
    if page.has_selector?(:button, text: 'View Tutorial')
      page.click_button('View Tutorial')
    end
  end

  def hide_tutorial
    if page.has_selector?(:button, text: 'Hide Tutorial')
      page.click_button('Hide Tutorial')
    end
  end

  def button(id)
    element = case id
              when :cancel
                page.find('.test-cancel-btn')
              when :back
                page.find('.test-back-btn', text: 'Previous')
              when :next
                page.find('.test-next-btn', text: 'Next')
              when :select
                page.find('button', text: 'Select')
              when :get_started
                page.find_button('Get started')
              when :add_category
                page.find('button', text: 'Add Category')
              when :save_changes
                page.find('.test-save-changes', text: 'Save changes')
              else
                raise ArgumentError, "invalid button '#{id}'"
              end
    ButtonObject.new(element)
  end
end
