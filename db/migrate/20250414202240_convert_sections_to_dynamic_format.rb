class ConvertSectionsToDynamicFormat < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE sections ROW_FORMAT=DYNAMIC;'
    )
  end
end
