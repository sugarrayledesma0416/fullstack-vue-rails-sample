describe User do
  describe '#can_use_ai_grading_suggestions?' do
    let(:user) { create(:user) }

    it 'is true if the user has the setting set to true' do
      user.set(Setting::AI::AllowGradingSuggestions, 'true')

      expect(user.can_use_ai_grading_suggestions?).to be_truthy
    end

    it 'is false if the user has the setting set to false' do
      user.set(Setting::AI::AllowGradingSuggestions, 'false')

      expect(user.can_use_ai_grading_suggestions?).to be_falsey
    end

    it 'is false if the user has no setting' do
      expect(user.can_use_ai_grading_suggestions?).to be_falsey
    end
  end

  describe 'grant_access_to_ai_grading_suggestions' do
    it 'sets the grading suggestions setting to true' do
      user = create(:user)
      user.grant_access_to_ai_grading_suggestions

      expect(user.can_use_ai_grading_suggestions?).to be_truthy
    end
  end

  describe 'revoke_access_to_ai_grading_suggestions' do
    it 'sets the grading suggestions setting to false' do
      user = create(:user)
      user.revoke_access_to_ai_grading_suggestions

      expect(user.can_use_ai_grading_suggestions?).to be_falsey
    end
  end

  describe '#ai_grading_suggestions_enabled?' do
    let(:user) { create(:user) }

    it 'is true if the user has the setting set to true' do
      user.set(Setting::AI::EnableGradingSuggestions, 'true')

      expect(user.ai_grading_suggestions_enabled?).to be_truthy
    end

    it 'is false if the user has the setting set to false' do
      user.set(Setting::AI::EnableGradingSuggestions, 'false')

      expect(user.ai_grading_suggestions_enabled?).to be_falsey
    end

    it 'is false if the user has no setting' do
      expect(user.ai_grading_suggestions_enabled?).to be_falsey
    end
  end

  it 'filters out archived users on find' do
    user = create(:user, archived: true)
    expect(User.where(id: user.id).first).to be_nil
  end

  describe 'named_scopes' do
    describe '.is_fake' do
      it 'returns only fake users' do
        create(:student)
        @user_fake = create(:student, fake: true)
        expect(User.is_fake).to eq([@user_fake])
      end
    end

    describe '.not_fake' do
      before do
        @user = create(:student)
      end

      it 'returns all users except the fake user' do
        @user_fake = create(:user, fake: true)
        expect(User.not_fake).to eq([@user])
      end
    end
  end

  describe '#full_name' do
    it 'returns first_name and last_name separated by a space' do
      user = create(:user)
      expect(user.full_name).to eql "#{user.first_name} #{user.last_name}"
    end
  end

  describe '#email' do
    it 'returns a empty string if it is a clever student' do
      student = create(:clever_student)
      expect(student.email).to eq('')
    end

    it 'returns then linked user email if it is a one_roster user' do
      school = create(:one_roster_school)
      user = create(:one_roster_user, schools: [school])
      linked_user = create(:one_roster_linked_user, user:, school:)

      expect(user.email).to eq(linked_user.email)
    end

    it 'returns a string with the email if it a non rostering student' do
      email = '78978@mail.com'
      student = create(:user, email:)
      expect(student.email).to eq(email)
    end
  end

  describe '#instructor?' do
    it 'returns true if the user is an instructor' do
      user = create(:instructor)
      expect(user).to be_instructor
    end

    it 'returns true if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).to be_instructor
    end

    it 'returns true if the user is a data admin' do
      user = create(:data_admin)
      expect(user).to be_instructor
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user).not_to be_instructor
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user).not_to be_instructor
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user).not_to be_instructor
    end
  end

  describe '#institution_admin?' do
    it 'returns true if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).to be_institution_admin
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user).not_to be_institution_admin
    end

    it 'returns false if the user is a data admin' do
      user = create(:data_admin)
      expect(user).not_to be_institution_admin
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user).not_to be_institution_admin
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user).not_to be_institution_admin
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user).not_to be_institution_admin
    end
  end

  describe '#data_admin?' do
    it 'returns true if the user is a data admin' do
      user = create(:data_admin)
      expect(user).to be_data_admin
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user).not_to be_data_admin
    end

    it 'returns false if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).not_to be_data_admin
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user).not_to be_data_admin
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user).not_to be_data_admin
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user).not_to be_data_admin
    end
  end

  describe '#enterprise_admin?' do
    it 'returns true if the user is a data admin' do
      user = create(:data_admin)
      expect(user.enterprise_admin?).to be true
    end

    it 'returns true if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user.enterprise_admin?).to be true
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user.enterprise_admin?).to be false
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user.enterprise_admin?).to be false
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user.enterprise_admin?).to be false
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user.enterprise_admin?).to be false
    end
  end

  describe '#student?' do
    it 'returns true if the user is a student' do
      user = create(:student)
      expect(user).to be_student
    end

    it 'returns false if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).not_to be_student
    end

    it 'returns false if the user is a data admin' do
      user = create(:data_admin)
      expect(user).not_to be_student
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user).not_to be_student
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user).not_to be_student
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user).not_to be_student
    end
  end

  describe '#editor?' do
    it 'returns true if the user is an editor' do
      user = create(:editor)
      expect(user).to be_editor
    end

    it 'returns false if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).not_to be_editor
    end

    it 'returns false if the user is a data admin' do
      user = create(:data_admin)
      expect(user).not_to be_editor
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user).not_to be_editor
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user).not_to be_editor
    end

    it 'returns false if the user is a grader' do
      user = create(:grader)
      expect(user).not_to be_editor
    end
  end

  describe '#is_resource_editor?' do
    it 'returns true if role is resource_editor' do
      user = create(:user)
      user.roles << Role.new(name: Role::RESOURCE_EDITOR)
      expect(user.is_resource_editor?).to be_truthy
    end

    it 'returns false if role is not resource_editor' do
      user = create(:user)
      user.roles << Role.new(name: Role::SUPPORT_VENDOR)
      expect(user.is_resource_editor?).not_to be_truthy
    end
  end

  describe '#is_common_cartridge_creator?' do
    it 'returns true if the user has the CC creator role' do
      user = create(:user)
      user.roles << Role.new(name: Role::COMMON_CARTRIDGE_CREATOR)
      expect(user.is_common_cartridge_creator?).to be_truthy
    end

    it 'returns false if the user has not the CC creator role' do
      user = create(:user)
      expect(user.is_common_cartridge_creator?).not_to be_truthy
    end
  end

  describe '#grader?' do
    it 'returns true if the user is a grader' do
      user = create(:grader)
      expect(user).to be_grader
    end

    it 'returns false if the user is an instructor' do
      user = create(:instructor)
      expect(user).not_to be_grader
    end

    it 'returns false if the user is an institution admin' do
      user = create(:institution_admin)
      expect(user).not_to be_grader
    end

    it 'returns false if the user is a data admin' do
      user = create(:data_admin)
      expect(user).not_to be_grader
    end

    it 'returns false if the user is an editor' do
      user = create(:editor)
      expect(user).not_to be_grader
    end

    it 'returns false if the user is a student' do
      user = create(:student)
      expect(user).not_to be_grader
    end
  end

  describe '#can_view_unreleased_units?' do
    context 'without able to see unreleased units role' do
      it 'returns false' do
        user = create(:user)
        expect(user.can_view_unreleased_units?).to be_falsey
      end
    end

    context 'with a role that allows him to see released units' do
      it 'returns true' do
        user = create(:user)
        allow(user).to receive(:roles).and_return([double(Role,
                                                          name: Role::UNRELEASED_UNIT_VIEWER)])
        expect(user.can_view_unreleased_units?).to be_truthy
      end
    end
  end

  describe '#can_review_questions?' do
    let(:user) { create(:user) }

    context 'without able to see unreleased units role' do
      it 'returns false' do
        expect(user).not_to be_can_review_questions
      end
    end

    context 'with a role that allows him to see released units' do
      it 'returns true' do
        user.roles.create(name: Role::REVIEWER)
        expect(user).to be_can_review_questions
      end
    end
  end

  describe '#clever?' do
    it "returns true if the user's email domain is the fake domain from UA" do
      fake_domain = 'this-is-a-clever-user.com'
      user = create(:user, email: '219357349587234968@' + fake_domain)

      expect(user.clever?).to be_truthy
    end

    it "returns true if the user's email domain is the fake admin domain from UA" do
      fake_domain = 'this-is-a-clever-admin-user.com'
      user = create(:user, email: '219357349587234968@' + fake_domain)

      expect(user.clever?).to be_truthy
    end

    it "returns false if the user's email domain is anything else" do
      user = create(:user)

      expect(user.clever?).to be_falsey
    end
  end

  describe '#clever_instructor?' do
    it 'returns false for clever students' do
      user = create(:clever_student)

      expect(user).not_to be_clever_instructor
    end

    it 'returns true for clever instructors' do
      user = create(:clever_instructor)

      expect(user).to be_clever_instructor
    end

    it 'returns false for clever admins' do
      user = create(:clever_admin)

      expect(user).not_to be_clever_instructor
    end

    it 'returns false for VHL students' do
      user = create(:student)

      expect(user).not_to be_clever_instructor
    end

    it 'returns false for VHL instructors' do
      user = create(:instructor)

      expect(user).not_to be_clever_instructor
    end
  end

  describe '#clever_admin?' do
    it 'returns false for clever students' do
      user = create(:clever_student)

      expect(user).not_to be_clever_admin
    end

    it 'returns false for clever instructors' do
      user = create(:clever_instructor)

      expect(user).not_to be_clever_admin
    end

    it 'returns true for clever admins' do
      user = create(:clever_admin)

      expect(user).to be_clever_admin
    end

    it 'returns false for VHL students' do
      user = create(:student)

      expect(user).not_to be_clever_admin
    end

    it 'returns false for VHL instructors' do
      user = create(:instructor)

      expect(user).not_to be_clever_admin
    end
  end

  describe '#one_roster?' do
    it 'returns true when the user is a OneRoster user' do
      school = create(:one_roster_school)
      user = create(:one_roster_user, schools: [school])
      create(:one_roster_linked_user, user:, school:)

      expect(user.one_roster?).to be_truthy
    end

    it "returns false when the user's email is from the fake RA domain but no " \
       'linked user exists' do
      school = create(:one_roster_school)
      user = create(:one_roster_user, schools: [school])

      expect(user.one_roster?).to be_falsey
    end

    it 'returns false when the user is a clever user' do
      user = create(:clever_student)

      expect(user.one_roster?).to be_falsey
    end

    it 'returns false when the user is a VHL user' do
      user = create(:user)

      expect(user.one_roster?).to be_falsey
    end
  end

  describe '#cartridge?' do
    it 'returns true when the user is a cartridge user' do
      school = create(:school)
      user = create(:cartridge_user, schools: [school])
      create(:cartridge_user_link, user:, school:)

      expect(user.cartridge?).to be_truthy
    end

    it "returns false when the user's email is from the fake cartridge domain " \
       'but no user links exists' do
      school = create(:school)
      user = create(:cartridge_user, schools: [school])

      expect(user.cartridge?).to be_falsey
    end

    it 'returns false when the user is not a cartridge user' do
      user = create(:user)

      expect(user.cartridge?).to be_falsey
    end
  end

  describe '#lti_rostering?' do
    context 'when the user is linked with an Lti-rostering platform,' do
      let(:platform) { create(:lti_rostering_platform) }

      it "returns true if the user's email is from the fake Lti-rostering domain" do
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_truthy
      end

      it "returns true if the user's email is from the fake RA domain" do
        user = create(:one_roster_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_truthy
      end

      it "returns true if the user's email is from the fake Clever domain" do
        user = create(:clever_instructor)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_truthy
      end

      it "returns false if the user's email is not from any of the fake " \
         'Lti-rostering, RA or Clever domains' do
        user = create(:user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_falsey
      end
    end

    context 'when the user is linked with an non-rostering Lti platform,' do
      let(:platform) { create(:lti_platform) }

      it "returns false if the user's email is from the fake Lti-rostering domain" do
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is from the fake RA domain" do
        user = create(:one_roster_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is from the fake Clever domain" do
        user = create(:clever_instructor)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is not from any of the fake " \
         'Lti-rostering, RA or Clever domains' do
        user = create(:user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering?).to be_falsey
      end
    end

    context 'when the user is not linked with an Lti platform,' do
      it "returns false if the user's email is from the fake Lti-rostering domain" do
        user = create(:lti_rostering_user)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is from the fake RA domain" do
        user = create(:one_roster_user)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is from the fake Clever domain" do
        user = create(:clever_instructor)

        expect(user.lti_rostering?).to be_falsey
      end

      it "returns false if the user's email is not from any of the fake " \
         'Lti-rostering, RA or Clever domains' do
        user = create(:user)

        expect(user.lti_rostering?).to be_falsey
      end
    end
  end

  describe '#lti_rostering_transitioned_from_clever?' do
    context 'when the user is linked to an LTI-rostering platform,' do
      it 'returns true if the LTI platform tranisitioned from Clever' do
        platform = create(:lti_rostering_platform, rostering_transition_from: 'Clever')
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering_transitioned_from_clever?).to be(true)
      end

      it 'returns false if the LTI platform transitioned from something other than Clever' do
        platform = create(:lti_rostering_platform, rostering_transition_from: 'RA')
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering_transitioned_from_clever?).to be(false)
      end

      it 'returns false if the LTI platform did not transition from anyting' do
        platform = create(:lti_rostering_platform, rostering_transition_from: nil)
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering_transitioned_from_clever?).to be(false)
      end
    end

    context 'when the user is linked to an LTI non-rostering platform,' do
      let(:platform) { create(:lti_platform) }

      it 'returns false' do
        user = create(:lti_rostering_user)
        create(:lti_rostering_user_link, user:, lti_platform: platform)

        expect(user.lti_rostering_transitioned_from_clever?).to be(false)
      end
    end

    context 'when the user is not linked to an LTI platform,' do
      it 'returns false' do
        user = create(:user)

        expect(user.lti_rostering_transitioned_from_clever?).to be(false)
      end
    end
  end

  describe 'clever_rostering?' do
    let(:user) { create(:user, email: 'cleverboy@this-is-a-clever-user.com') }
    let(:school) { build_stubbed(:school) }
    let(:clever_school) { build_stubbed(:clever_school) }
    let(:clever_rostering_school) { create(:clever_rostering_school) }

    before do
      allow(user).to receive(:schools).and_return([school])
    end

    it 'returns true if this user with Clever and their school is a rostering school' do
      allow(user).to receive(:schools).and_return([clever_rostering_school])
      expect(user).to be_clever_rostering
    end

    it 'returns false if this user with Clever and their school is not a rostering school' do
      allow(user).to receive(:schools).and_return([clever_school])
      expect(user).not_to be_clever_rostering
    end

    it 'returns false if this user with Clever and they have no school' do
      allow(user).to receive(:schools).and_return([])
      expect(user).not_to be_clever_rostering
    end

    it 'returns false if the user is not with Clever' do
      user.update(email: 'regularboy@somedomain.com')
      expect(user).not_to be_clever_rostering
    end
  end

  describe 'one_roster_rostering?' do
    let(:one_roster_school) { create(:one_roster_school) }
    let(:school) { create(:school) }

    it 'returns true when the user has an associated one roster linked user' do
      user = create(:one_roster_user)
      create(:one_roster_linked_user, user:)

      expect(user).to be_one_roster_rostering
    end

    context 'when the user has no associated one roster linked user,' do
      it 'returns false when the user has no schools' do
        user = create(:one_roster_user, schools: [])

        expect(user).not_to be_one_roster_rostering
      end

      it 'returns false when his school is OneRoster rostering school' do
        school = create(:one_roster_school)
        user = create(:one_roster_user, schools: [school])

        expect(user).not_to be_one_roster_rostering
      end

      it 'returns false when his school is OneRoster SSO-rostering school' do
        school = create(:one_roster_sso_school)
        user = create(:one_roster_user, schools: [school])

        expect(user).not_to be_one_roster_rostering
      end

      it 'returns false when his school is not a OneRoster rostering school' do
        school = create(:school)
        user = create(:one_roster_user, schools: [school])

        expect(user).not_to be_one_roster_rostering
      end
    end
  end

  describe 'rostering?' do
    let(:user) { create(:user) }
    let(:school) { create(:school) }
    let(:clever_school) { create(:clever_school) }
    let(:clever_rostering_school) { create(:clever_rostering_school) }
    let(:one_roster_school) { create(:one_roster_school) }

    context 'with a clever user' do
      before do
        user.update(email: 'cleverboy@this-is-a-clever-user.com')
      end

      it 'returns true if this user with Clever and their school is a Clever rostering school' do
        user.update(email: 'cleverboy@this-is-a-clever-user.com')
        allow(user).to receive(:schools).and_return([clever_rostering_school])
        expect(user).to be_rostering
      end

      it 'returns false if this user with Clever and their school is not a Clever rostering school' do
        user.update(email: 'cleverboy@this-is-a-clever-user.com')
        allow(user).to receive(:schools).and_return([clever_school])
        expect(user).not_to be_rostering
      end

      it 'returns false if this user with Clever and they have no school' do
        user.update(email: 'cleverboy@this-is-a-clever-user.com')
        allow(user).to receive(:schools).and_return([])
        expect(user).not_to be_rostering
      end
    end

    context 'with a one_roster user' do
      let(:user) do
        create(:one_roster_user).tap do |user|
          create(:one_roster_linked_user, user:)
        end
      end

      it 'returns true if their school is a OneRoster rostering school' do
        allow(user).to receive(:schools).and_return([one_roster_school])
        expect(user).to be_rostering
      end

      it 'returns true if their school is not a OneRoster rostering school' do
        allow(user).to receive(:schools).and_return([school])
        expect(user).to be_rostering
      end

      it 'returns true if this user has no school' do
        allow(user).to receive(:schools).and_return([])
        expect(user).to be_rostering
      end
    end

    it 'returns false if the user has no school' do
      allow(user).to receive(:schools).and_return([])
      expect(user.rostering?).to be_falsey
    end

    it 'returns false if the user is not rostering via any external system' do
      allow(user).to receive(:schools).and_return([school])
      expect(user.rostering?).to be_falsey
    end
  end

  describe 'clever_or_one_roster?' do
    it 'returns true if the user has a clever email' do
      user = create(
        :user,
        email: "#{SecureRandom.uuid}@#{User::CLEVER_USERS_FAKE_EMAIL_DOMAIN}"
      )
      expect(user).to be_clever_or_one_roster
    end

    it 'returns true if the user is in a one_roster user' do
      user = create(:one_roster_user)
      create(:one_roster_linked_user, user:)

      expect(user).to be_clever_or_one_roster
    end

    it 'returns false when the user is a VHL user' do
      user = create(:user)

      expect(user).not_to be_clever_or_one_roster
    end
  end

  describe '#has_current_access_to?' do
    let(:user) { create(:grader) }
    let(:program) { create(:program) }
    let(:mc_program) { double('Maestro::Program', id: program.id) }

    it 'returns false if user does not have access to the specified given program' do
      allow(Maestro::User).to receive(:accessible_programs).and_return([])
      expect(user.has_current_access_to?(program)).to be_falsey
    end

    it 'returns true if the user has access to the specified program' do
      allow(Maestro::User).to receive(:accessible_programs).and_return([mc_program])
      expect(user.has_current_access_to?(program)).to be_truthy
    end

    it 'does not raise an exception when the client accessible programs array contains a program not present in the database' do
      invalid_mc_program = double('Maestro::Program', id: (program.id + 1))
      allow(Maestro::User).to receive(:accessible_programs).and_return([invalid_mc_program])
      expect { user.has_current_access_to?(program) }.not_to raise_error
    end
  end

  describe '#email_domain' do
    it 'returns everything after the @ sign' do
      user = create(:user, email: 'someone@vistahigherlearning.com')
      expect(user.email_domain).to eql('vistahigherlearning.com')
    end
  end

  describe '#class' do
    it 'defines a ACCOUNT_TYPES constant containing the possible location strings' do
      expect(User::ACCOUNT_TYPES).to include('Student')
      expect(User::ACCOUNT_TYPES).to include('Instructor')
      expect(User::ACCOUNT_TYPES).to include('Grader')
      expect(User::ACCOUNT_TYPES).to include('Editor')
    end
  end

  describe '#setting' do
    it 'returns nil for nonsense settings' do
      user = create(:user)
      value = user.setting('nonsense')
      expect(value).to be_nil
    end

    it 'returns the default value of sensible values if not set' do
      user = create(:user)
      value = user.setting(Setting::Gradebook::CategoryView)
      expect(value).to eql(Setting.default(Setting::Gradebook::CategoryView))
    end

    it 'returns the setting value if set' do
      user = create(:user)
      create(:setting, user:, name: 'some arbitrary name', value: 'value')
      value = user.setting('some arbitrary name')
      expect(value).to eql('value')
    end
  end

  describe '#set' do
    it "creates the value in the database if it doesn't exist" do
      user = create(:user)
      expect(Setting).to receive(:create!).with(hash_including(name: 'something_nice',
                                                               value: 'value'))

      user.set('something_nice', 'value')
    end

    it 'updates the value in the database if it already exists' do
      user = create(:user)
      user.set('foo', 'bar')
      expect(user.setting('foo')).to eq('bar')
      user.set('foo', 'qux')
      expect(user.setting('foo')).to eq('qux')
    end

    it 'sanitizes the value if name is passed as a Definition instance' do
      class Def < Setting::Definition; end

      expect(Def).to receive(:sanitize_value)

      user = create(:user)
      user.set(Def, 'value')
    end

    it 'returns a Setting object' do
      class ReturnValue < Setting::Definition; end

      user = create(:user)
      result = user.set(ReturnValue, 'value')
      expect(result).to be_a Setting
    end
  end

  describe '#initials_and_last_name' do
    it 'returns the last name with the firstname initial' do
      user = create(:user, first_name: 'herman louis', last_name: 'andersson cruz')
      expect(user.initials_and_last_name).to eql 'H.L Andersson Cruz'
    end
  end

  describe '.find_by_id_including_archived' do
    context 'when no user exists with the specified id, whether archived or unarchived' do
      it 'returns nil' do
        expect(User.find_by_id_including_archived(1_234_567)).to be_nil
      end
    end

    context 'when a user with the specified id exists and is not archived' do
      it 'returns that user' do
        user = create(:student)
        expect(User.find_by_id_including_archived(user.id)).to eql user
      end
    end

    context 'when a user with the specified id exists and is archived' do
      it 'returns that user' do
        user = create(:student, archived: true)
        expect(User.find_by_id_including_archived(user.id)).to eql user
      end
    end
  end

  describe '.find_guid' do
    it 'returns the guid of a user given an id' do
      user = create(:user)
      expect(User.find_guid(user.id)).to eql(user.guid)
    end
  end

  describe '#avatar_image_url' do
    it 'returns the correct avatar image url for that user' do
      user = create(:student)
      expect(user.avatar_image_url).to eql("https://avatars.vhlcentral.com/avatars/#{user.guid}.jpg")
    end
  end

  describe '#avatar_thumb_url' do
    it 'returns the correct avatar thumbnail url for that user' do
      user = create(:student)
      expect(user.avatar_thumb_url).to eql("https://avatars.vhlcentral.com/avatars/#{user.guid}_t.jpg")
    end
  end

  context 'update_gradebook' do
    context 'after commit' do
      let(:user) { create(:user) }

      it 'triggers update_gradebook in after_commit' do
        user.first_name = 'NewName'
        expect(user).to receive(:update_gradebook)
        user.save
      end

      it 'triggers notify_update when user is created' do
        auser = described_class.new
        auser.first_name = 'Test'
        auser.last_name = 'User'
        auser.username = 'test.user@test.com'
        auser.email = 'test.user@test.com'
        expect(auser).to receive(:notify_update)
        auser.save
      end

      it 'triggers notify_deletion for an archived user' do
        auser = described_class.new
        auser.first_name = 'Test'
        auser.last_name = 'User'
        auser.username = 'test.user@test.com'
        auser.email = 'test.user@test.com'
        auser.run_callbacks(:commit)
        auser.archived = true
        expect(auser).to receive(:notify_deletion)
        auser.save
      end

      it 'triggers notify_deletion for a destroyed user' do
        auser = described_class.new
        auser.first_name = 'Test'
        auser.last_name = 'User'
        auser.username = 'test.user@test.com'
        auser.email = 'test.user@test.com'
        auser.save
        expect(auser).to receive(:notify_deletion)
        auser.destroy
      end
    end
  end

  describe 'admin_for_school?' do
    let(:user) { create(:user) }
    let(:school) { create(:school) }

    it 'returns false' do
      expect(user.admin_for_school?(school)).to be false
    end
  end
end
