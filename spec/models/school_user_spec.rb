describe SchoolUser do
  let(:user)    { create(:user) }
  let(:school)  { create(:school) }
  let(:valid_attrs) do {"sync_token" => 1, "user_guid" => user.guid,
                        "request_id" => 'b6da4613-03c3-49a8-ba25-5043eebac1a6',
                        "school_guid" => school.guid }
  end
  describe 'validation of assign_related_objects' do
    before do
      Dangerfield::Gatekeeper.instance.disabled = false
      described_class.dangerfield_update_attributes(valid_attrs, described_class.new)
    end
    after do
      Dangerfield::Gatekeeper.instance.disabled = true
    end

    context 'for a new record' do
      it 'finds and sets related school and user from guids' do
        school_user = described_class.last
        expect(school_user.user.id).to eq(user.id)
        expect(school_user.school.id).to eq(school.id)
      end
    end

    context 'for an existing record' do
      it 'finds and sets only the related school from guids' do
        school_user = described_class.last
        described_class.dangerfield_update_attributes(valid_attrs.merge!({"user_guid" => -1}),
                                                      school_user)
        school_user = described_class.last
        expect(school_user.user.id).not_to eq(-1)
        expect(school_user.school.id).to eq(school.id)
      end
    end
  end


  describe "reject_if no_school_no_user_added" do
    let(:school) { create(:school) }
    let(:instructor) { create(:instructor) }
    let (:school_user) { create(:school_user, :school => school, :user => instructor) }
    let (:valid_attrs) do { "sync_token"=> 1,
                            "guid" => SecureRandom.uuid,
                            "request_id" => SecureRandom.uuid,
                            "user_guid"=> instructor.guid,
                            "school_guid"=> school.guid
    }
    end

    let (:no_user_attrs) do { "sync_token"=> 2,
                            "guid" => SecureRandom.uuid,
                            "request_id" => SecureRandom.uuid,
                            "user_guid"=> SecureRandom.uuid,
                            "school_guid"=> school.guid
    }
    end

    let (:no_school_attrs) do { "sync_token"=> 2,
                              "guid" => SecureRandom.uuid,
                              "request_id" => SecureRandom.uuid,
                              "user_guid"=> instructor.guid,
                              "school_guid"=> SecureRandom.uuid
    }
    end


    context 'no_school_or_no_user_added? returns false' do
      it 'is an existing record and school and user exist so update accepted' do
        enable_dangerfield do
          Section.dangerfield_update_attributes(valid_attrs, school_user)
          expect(school_user.sync_token).to eq(1)
        end
      end
    end

    context 'no_school_or_no_user_added? returns false' do
      it 'is a new record and and school and user exist so it gets added' do
        enable_dangerfield do
          new_school_user = SchoolUser.new
          SchoolUser.dangerfield_update_attributes(valid_attrs, new_school_user)
          expect(new_school_user.guid).to_not be_nil
        end
      end
    end

    context 'no_school_or_no_user_added? returns true' do
      it 'is a new record and user is not found so it gets rejected' do
        enable_dangerfield do
          new_school_user = SchoolUser.new
          SchoolUser.dangerfield_update_attributes(no_user_attrs, new_school_user)
          expect(new_school_user.guid).to be_nil
        end
      end

      it 'is a new record and school is not found so it gets rejected' do
        enable_dangerfield do
          new_school_user = SchoolUser.new
          SchoolUser.dangerfield_update_attributes(no_school_attrs, new_school_user)
          expect(new_school_user.guid).to be_nil
        end
      end
    end


    context 'no_school_or_no_user_added? returns true' do
      it 'is an existing record and user is not found so it gets rejected' do
        enable_dangerfield do
          current_sync_token = school_user.sync_token
          SchoolUser.dangerfield_update_attributes(no_user_attrs, school_user)
          # if an update had occurred the sync_token would have changed
          expect(school_user.sync_token).to eq(current_sync_token)
        end
      end

      it 'is an existing record and school is not found so it gets rejected' do
        enable_dangerfield do
          current_sync_token = school_user.sync_token
          SchoolUser.dangerfield_update_attributes(no_school_attrs, school_user)
          # if an update had occurred the sync_token would have changed
          expect(school_user.sync_token).to eq(current_sync_token)
        end
      end
    end
  end
end
