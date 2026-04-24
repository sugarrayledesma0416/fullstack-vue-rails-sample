class CreateLtiUserLinks < ActiveRecord::Migration[5.2]
  def change
    create_table 'lti_user_links' do |t|
      t.integer 'lti_platform_id'
      t.string 'platform_user_id', collation: 'utf8_bin'
      t.integer 'user_id'
      t.string 'guid'
      t.bigint 'sync_token', default: 0
      t.string 'request_id'
      t.timestamps

      t.index ['guid'], name: 'index_lti_user_links_on_guid'
      t.index(
        %w[lti_platform_id platform_user_id],
        name: 'index_lti_user_links_on_lti_platform_id_and_platform_user_id'
      )
    end
  end
end
