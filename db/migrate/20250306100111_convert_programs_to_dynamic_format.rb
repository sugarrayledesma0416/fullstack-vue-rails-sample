class ConvertProgramsToDynamicFormat < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE programs ROW_FORMAT=DYNAMIC;'
    )
  end
end
