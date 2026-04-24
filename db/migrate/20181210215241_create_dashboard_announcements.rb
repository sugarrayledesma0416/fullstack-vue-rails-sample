class CreateDashboardAnnouncements < ActiveRecord::Migration[4.2]
  create_table :dashboard_announcements do |table|
    table.string :title, null: false
    table.text :body, null: false
    table.boolean :supersite, null: false
    table.boolean :vol, null: false
    table.string :external_url, null: false
    table.string :link_text

    table.timestamps
  end
end
