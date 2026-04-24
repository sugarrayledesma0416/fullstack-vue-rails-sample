describe OneRoster::LinkedUser do
  let(:school) { create(:school) }
  let(:user) { create(:user) }
  let!(:valid_attrs) do { "sync_token"=>123456, "user_guid"=>user.guid,
                          "school_guid"=>school.guid,
                          "request_id"=>'b6da4613-03c3-49a8-ba25-5043eebac1a6',
                          "external_username"=>'astudent1',
                          "email"=>'astudent1@school.org',
                          "sourced_id"=>'123456',
                          "guid" => SecureRandom.uuid}
  end

  let (:user_not_found_attrs) do { "sync_token"=>123456, "user_guid"=>'garbage',
                            "school_guid"=>school.guid,
                            "request_id" => 'b6da4613-03c3-49a8-ba25-5043eebac1a6',
                            "external_username" => 'astudent2',
                            "email" => 'astudent2@school.org',
                            "sourced_id" => '78910',
                            "guid" => SecureRandom.uuid}
  end

  let (:no_user_guid_attrs) do { "sync_token"=>123456,
                                 "school_guid"=>school.guid,
                                 "request_id" => 'b6da4613-03c3-49a8-ba25-5043eebac1a6',
                                 "external_username" => 'astudent2',
                                 "email" => 'astudent2@school.org',
                                 "sourced_id" => '78910',
                                 "guid" => SecureRandom.uuid}
  end

  describe 'dangerfield_reject_if' do
    it 'accepts new instance because related User is found' do
      enable_dangerfield do
        linked_user = OneRoster::LinkedUser.new
        OneRoster::LinkedUser.dangerfield_update_attributes(valid_attrs, linked_user)
        expect(linked_user.guid).to_not be_nil
      end
    end

    it 'rejects new instance because related User is not found' do
      enable_dangerfield do
        linked_user = OneRoster::LinkedUser.new
        OneRoster::LinkedUser.dangerfield_update_attributes(user_not_found_attrs, linked_user)
        expect(linked_user.guid).to be_nil
      end
    end

    it 'rejects new instance because there is no user_guid in the params' do
      enable_dangerfield do
        linked_user = OneRoster::LinkedUser.new
        OneRoster::LinkedUser.dangerfield_update_attributes(no_user_guid_attrs, linked_user)
        expect(linked_user.guid).to be_nil
      end
    end
  end
end
