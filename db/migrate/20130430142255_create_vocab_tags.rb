class CreateVocabTags < ActiveRecord::Migration[4.2]
  def self.up
    create_table :vocab_tags do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :vocab_tags
  end
end
