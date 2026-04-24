describe 'content access' do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:guardian) { AccessGuardian.new(user, course) }

  context 'given a user with access to content of a license group' do
    let(:activity) { create(:activity, :license_group_id => 1) }
    let(:other_activity) { create(:activity, :license_group_id => 2) }
    let(:licensed_content) { double('LicensedContent', :license_group_ids => [1]) }

    before do
      allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).and_return(licensed_content)
    end

    context 'when additional content is made available for that license group' do
      before do
        other_activity.update!(license_group_id: 1)
      end

      it 'gives the user access to the additional content' do
        expect(guardian.has_accessible_license_group?(activity)).to be_truthy
        expect(guardian.has_accessible_license_group?(other_activity)).to be_truthy
      end
    end

    context 'when content is removed from that license group' do
      before do
        activity.update!(license_group_id: 2)
      end

      it 'removes access to that content for the user' do
        expect(guardian.has_accessible_license_group?(activity)).to be_falsey
        expect(guardian.has_accessible_license_group?(other_activity)).to be_falsey
      end
    end
  end
end
