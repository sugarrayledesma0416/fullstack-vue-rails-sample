describe UserEmailHelper do
  include described_class

  describe '#user_display_email' do
    context 'when the user is a VHL user,' do
      let(:user) { create(:user) }

      it "returns the user's email" do
        expect(user_display_email(user)).to eq(user.email)
      end
    end

    context 'when the user is a RA user,' do
      it 'returns the RA email' do
        school = create(:school)
        user = create(:one_roster_user, schools: [school])
        user_link = create(:one_roster_linked_user, user: user, school: school)

        expect(user_display_email(user)).to eq(user_link.email)
      end
    end

    context 'when the user is a clever user,' do
      it 'returns an empty string' do
        user = create(:clever_student)

        expect(user_display_email(user)).to eq('')
      end

    end

    context 'when the user is an Lti rostering user,' do
      it 'returns the platform email' do
        user = create(:lti_rostering_user)
        user_link = create(:lti_rostering_user_link, user: user)

        expect(user_display_email(user)).to eq(user_link.platform_user_email)
      end
    end

    context 'when the user is an Lti user,' do
      it "returns the user's email" do
        user = create(:user)
        create(:lti_rostering_user_link, user: user)

        expect(user_display_email(user)).to eq(user.email)
      end
    end
  end
end
