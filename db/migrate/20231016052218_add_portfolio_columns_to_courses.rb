class AddPortfolioColumnsToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :share_to_portfolio, :boolean, default: false
    add_column :courses, :portfolio_activity_types, :json
  end
end
