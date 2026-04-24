class BackfillAddSearchableToStandards < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Standard.unscoped.in_batches do |relation|
      relation.update_all searchable: true
      sleep(0.01)
    end
  end
end
