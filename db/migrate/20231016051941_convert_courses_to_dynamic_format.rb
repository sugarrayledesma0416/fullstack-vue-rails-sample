class ConvertCoursesToDynamicFormat < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE courses ROW_FORMAT=DYNAMIC;'
    )
  end
end
