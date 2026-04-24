class BackfillAddSharedToSection < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    Section.unscoped.in_batches do |relation|
      relation.update_all shared: true
      sleep(0.01)
    end
  end
end
