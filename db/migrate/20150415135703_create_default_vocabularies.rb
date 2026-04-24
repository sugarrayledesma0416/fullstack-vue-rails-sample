class CreateDefaultVocabularies < ActiveRecord::Migration[4.2]
  def change
    create_table :default_vocabularies do |t|
      t.references :program, :null => false
      t.references :lesson, :null => false
      t.string :composite_dictionary_id, :null => false
      t.string :topic, :null => false
      t.string :target, :null => false
      t.string :translation, :null => false
      t.string :definition
      t.string :audio_paths, :limit => 2048

      t.timestamps
    end
  end
end
