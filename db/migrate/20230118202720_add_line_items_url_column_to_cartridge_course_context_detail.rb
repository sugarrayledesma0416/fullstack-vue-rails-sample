class AddLineItemsUrlColumnToCartridgeCourseContextDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :cartridge_course_context_details, :line_items_url, :string
  end
end
