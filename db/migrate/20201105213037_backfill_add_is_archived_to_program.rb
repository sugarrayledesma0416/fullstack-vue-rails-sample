class BackfillAddIsArchivedToProgram < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    Program.unscoped.in_batches do |relation|
      relation.update_all is_archived: false
      sleep(0.1)
    end
  end
end
