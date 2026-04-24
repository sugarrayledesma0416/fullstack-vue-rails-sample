class AddAdditionalAttrsToStdAssets < ActiveRecord::Migration[6.1]
  def change
    add_column :standard_assets, :additional_attrs, :json
  end
end
