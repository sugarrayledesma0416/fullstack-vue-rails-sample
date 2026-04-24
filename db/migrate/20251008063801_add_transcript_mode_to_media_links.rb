class AddTranscriptModeToMediaLinks < ActiveRecord::Migration[6.1]
  def change
    # Add transcript_mode as integer enum with default value of 0 (null)
    # 0: null, 1: visible, 2: in_body, 3: hidden
    add_column :media_links, :transcript_mode, :integer, default: 0, null: true
  end
end
