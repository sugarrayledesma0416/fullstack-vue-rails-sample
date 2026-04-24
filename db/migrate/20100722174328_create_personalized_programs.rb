class CreatePersonalizedPrograms < ActiveRecord::Migration[4.2]
  def self.up
    create_table :personalized_programs do |t|
      t.integer :user_id
      t.integer :program_id
    end
  end

  def self.down
    drop_table :personalized_programs
  end
end
