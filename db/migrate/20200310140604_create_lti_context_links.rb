class CreateLtiContextLinks < ActiveRecord::Migration[5.2]
  def change
    create_table 'lti_context_links' do |t|
      t.integer 'lti_platform_id'
      t.string 'deployment_id'
      t.string 'context_id', collation: 'utf8_bin'
      t.string 'context_label'
      t.string 'context_title'
      t.string 'line_items_url'
      t.integer 'section_id'
      t.string 'guid'
      t.bigint 'sync_token', default: 0
      t.string 'request_id'
      t.timestamps

      t.index ['guid'], name: 'index_lti_context_links_on_guid'
      t.index(
        %w[lti_platform_id context_id],
        name: 'index_lti_context_links_on_lti_platform_id_and_context_id'
      )
    end
  end
end
