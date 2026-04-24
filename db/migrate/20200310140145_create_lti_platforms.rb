class CreateLtiPlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table 'lti_platforms' do |t|
      t.string 'name'
      t.string 'issuer_id'
      t.string 'keyset_url'
      t.string 'oidc_auth_url'
      t.string 'oauth2_url'
      t.string 'guid'
      t.bigint 'sync_token', default: 0
      t.string 'request_id'
      t.timestamps

      t.index ['guid'], name: 'index_lti_platforms_on_guid'
    end
  end
end
