class AddHasVhlImageToActivity < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :has_vhl_image, :boolean
  end
end
