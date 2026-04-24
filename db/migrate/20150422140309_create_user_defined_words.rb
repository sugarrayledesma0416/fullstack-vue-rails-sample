class CreateUserDefinedWords < ActiveRecord::Migration[4.2]
  def change
    create_table :user_defined_words do |t|
      t.references :program, :null => false
      t.references :lesson, :null => false
      t.references :user, :null => false

      t.string :target, :null => false
      t.string :translation, :null => false
      t.string :definition, :limit => 512

      t.timestamps
    end
  end
end
