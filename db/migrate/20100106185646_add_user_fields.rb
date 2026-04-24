class AddUserFields < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :year_of_birth, :integer
    add_column :users, :secret_question, :string
    add_column :users, :secret_answer, :string
  end

  def self.down
    remove_column :users, :year_of_birth
    remove_column :users, :secret_question
    remove_column :users, :secret_answer
  end
end
