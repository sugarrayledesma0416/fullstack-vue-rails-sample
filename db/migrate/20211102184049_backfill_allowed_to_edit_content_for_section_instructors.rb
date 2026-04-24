class BackfillAllowedToEditContentForSectionInstructors < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    SectionInstructor.unscoped.in_batches do |relation|
      relation.update_all allowed_to_edit_content: false
      sleep(0.1)
    end
  end
end
