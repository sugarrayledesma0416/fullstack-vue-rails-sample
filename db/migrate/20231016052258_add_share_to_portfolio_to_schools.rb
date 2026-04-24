class AddShareToPortfolioToSchools < ActiveRecord::Migration[6.1]
  def change
    add_column :schools, :share_to_portfolio, :boolean, default: false
  end
end
