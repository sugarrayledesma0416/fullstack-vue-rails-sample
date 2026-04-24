class CreateProgramEditions < ActiveRecord::Migration[6.1]
  def change
    create_table :program_editions do |t|
      t.integer :program_id, null: false
      t.integer :next_edition_program_id
      t.integer :previous_edition_program_id
      t.string :guid
      t.integer :sync_token, limit: 8, default: 0
      t.string :request_id

      t.timestamps
    end

    add_index :program_editions, :program_id, name: 'index_program_editions_on_program_id'
    add_index :program_editions, :guid, name: 'index_program_editions_on_guid'
  end
end
