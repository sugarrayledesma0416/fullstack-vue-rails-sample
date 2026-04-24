class CreateLtiLaunches < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_launches do |t|
      t.text :jwt
      t.text :decoded_jwt
      t.integer :lti_tool_id
      t.text :state
      t.string :guid
      t.bigint :sync_token, default: 0
      t.string :request_id

      t.timestamps

      t.index [:guid]
    end
  end
end
