class BackfillActivitiesComponentLanguage < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Activity.unscoped.in_batches do |relation|
      relation.update_all(component_language: 'en')
      sleep(0.1)
    end
  end
end
