class AddDropLowestScoreJobTable < ActiveRecord::Migration[4.2]

  def up
    create_table  :drop_lowest_score_jobs do |t|
      t.integer   :section_id,  default: 0,     null: false
      t.integer   :category_id, default: 0,     null: false
      t.integer   :user_id,     default: 0,     null: false
      t.boolean   :enqueued,    default: false, null: false
      t.datetime  :started_at,                  null: true

      t.timestamps
    end
    add_index :drop_lowest_score_jobs, [:section_id, :category_id, :user_id], name: 'section_category_user'
  end

  def down
    drop_table :drop_lowest_score_jobs
  end
end
