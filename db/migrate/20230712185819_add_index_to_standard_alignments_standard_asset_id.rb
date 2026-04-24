class AddIndexToStandardAlignmentsStandardAssetId < ActiveRecord::Migration[6.1]
  def change
    add_index :standard_alignments, :standard_asset_id
  end
end
