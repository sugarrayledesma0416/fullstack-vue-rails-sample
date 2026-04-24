class BackfillIndividuallyAssignableOnCourse < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Course.unscoped.in_batches do |relation|
      relation.update_all allow_individual_assign: false
      sleep(0.01)
    end
  end
end
