describe AccessGuardian, core: true do
  let(:user) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program) }
  let(:licensed_content) { instance_double(Maestro::LicensedContent) }
  let(:unit) { build_stubbed(:unit, rank: 3) }
  let(:lesson) { build_stubbed(:lesson, unit_id: unit.id) }
  let(:guardian) { described_class.new(user, program) }

  let(:activity) do
    build_stubbed(:activity, lesson_id: lesson.id, license_group_id: 456)
  end

  before do
    allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
      .and_return(licensed_content)
    allow(licensed_content).to receive(:license_group_ids).and_return([456])
    allow(licensed_content).to receive(:lessons).and_return([3])
    allow(lesson).to receive(:unit_rank).and_return(2)
    allow(activity).to receive(:lesson).and_return(lesson)
  end

  describe "#can_access_content?" do
    it "retrieves access information from our api for a user and his program" do
      expect(guardian).to receive(:has_accessible_lesson?).and_return(true)
      expect(guardian).to receive(:has_accessible_license_group?).and_return(true)
      expect(guardian.can_access_content?(activity, lesson)).to be_truthy
    end
  end

  describe '#has_accessible_license_group?' do
    it 'is false when initialized with a nil program' do
      guardian = described_class.new(user, nil)

      expect(guardian).not_to have_accessible_license_group(activity)
    end

    context 'when initialized with a non-nil program' do
      before do
        allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
          .with(user.guid, program.id)
          .and_return(licensed_content)
      end

      context 'when no program_id is specified' do
        it 'is true if the LicensedContent contains the license_group_id ' \
           'of the specified object' do
          expect(guardian).to have_accessible_license_group(activity)
        end

        it 'is false if the LicensedContent does not contain the ' \
           'license_group_id of the specified content' do
          allow(licensed_content).to receive(:license_group_ids).and_return([123])

          expect(guardian).not_to have_accessible_license_group(activity)
        end
      end

      context 'when a program_id is specified' do
        let(:other_program_id) { build_stubbed(:program).id }

        let(:other_program_licensed_content) do
          instance_double(Maestro::LicensedContent)
        end

        before do
          allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
            .with(user.guid, other_program_id)
            .and_return(other_program_licensed_content)
        end

        it 'is true if the LicensedContent for the specified program id ' \
           'contains the license_group_id of the specified object' do
          allow(other_program_licensed_content).to receive(:license_group_ids)
            .and_return([456])

          # Pass the program id as a string because that is how it is
          # stored in the ProgamConfig.
          expect(guardian).to have_accessible_license_group(
            activity, other_program_id.to_s
          )
        end

        it 'is false if the LicensedContent does not contain the ' \
           'license_group_id of the specified content' do
          allow(other_program_licensed_content).to receive(:license_group_ids)
            .and_return([123])

          # Pass the program id as a string because that is how it is
          # stored in the ProgamConfig.
          expect(guardian).not_to have_accessible_license_group(
            activity, other_program_id.to_s
          )
        end
      end
    end
  end

  describe 'AccessGuardian::EmptyLicenseContent' do
    describe "#license_group_ids" do
      it 'returns an empty array' do
        expect(AccessGuardian::EmptyLicenseContent.new.license_group_ids).to eq([])
      end
    end
  end

  describe "#has_accessible_lesson?" do
    it "uses the user's unlocked lessons to determine availability" do
      expect(guardian).to receive(:valid_program_units).and_return([1,2,3,6,7])
      expect(guardian.has_accessible_lesson?(lesson)).to be_truthy
    end

    it 'returns true if lesson is current events' do
      lesson.use_type = 'CurrentEvents'
      expect(guardian.has_accessible_lesson?(lesson)).to be_truthy
    end
  end

  describe "#site_functions" do
    let(:my_vocab_function) { double('SiteFunction',
                                   :site_function_name => 'my_vocabulary',
                                   :license_group_id => 1) }

    describe "when the user license group is a site function" do
      it "returns a hash that maps the site function names to a site function object" do
        user_license = double('UserLicense',
                              :license_group => double('LicenseGroup', :id => 1,
                                                     :site_function? => true,
                                                     :site_function_name => 'my_vocabulary'))

        expected = { :my_vocabulary => my_vocab_function }
        expect(Maestro::UserLicense).to receive(:all_for_user_and_program).with(user.guid, program.id).and_return([user_license])
        expect(SiteFunction).to receive(:new).with('my_vocabulary', 1).and_return(my_vocab_function)
        expect(guardian.site_functions).to eq(expected)
      end

      it "ignores non-site_function licenses that don't include_content" do
        user_license = double('UserLicense',
                              :license_group => double('LicenseGroup',
                                                     :id => 1,
                                                     :name => 'Instructor License',
                                                     :site_function? => false))
        expected = {}
        expect(Maestro::UserLicense).to receive(:all_for_user_and_program).with(user.guid, program.id).and_return([user_license])
        expect(SiteFunction).not_to receive(:new)
        expect(guardian.site_functions).to eq(expected)
      end

      it 'does not include license groups that are not site functions' do
        user_license = double('UserLicense',
                            :license_group => double('LicenseGroup',
                                                   :id => 1,
                                                   :site_function? => false,
                                                   :includes_content => true))

        allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])
        expected = {}
        expect(guardian.site_functions).to eq(expected)
      end
    end
  end

  describe "#has_grace_period?" do
    let(:content_license) { double('Maestro::UserLicense', :grace_period? => false, :demo => false, :expired? => false) }

    context "when there is a grace period license" do
      let(:grace_period_license) { double('Maestro::UserLicense', :grace_period? => true, :demo => false) }

      context "that has not expired" do
        before do
          allow(grace_period_license).to receive_messages(:expired? => false)
        end

        it "returns true" do
          allow(guardian).to receive(:user_licenses).and_return([content_license, grace_period_license])
          expect(guardian.has_grace_period?).to be_truthy
        end
      end
      context "that has expired" do
        before do
          allow(grace_period_license).to receive_messages(:expired? => true)
        end

        it "returns false" do
          allow(guardian).to receive(:user_licenses).and_return([content_license, grace_period_license])
          expect(guardian.has_grace_period?).to be_falsey
        end
      end
    end

    context "when there is no grace period license" do
      it "returns false" do
        allow(guardian).to receive(:user_licenses).and_return([content_license])
        expect(guardian.has_grace_period?).to be_falsey
      end
    end
  end

  describe '#has_vocab_words?' do
    context "when there is a site function and i have access to it and it is not expired" do
      it 'returns true' do
        # Step 1: Create double LicenseGroup that has site_function? true and site_function_name= 'my_vocabulary' (see line 67)
        license_group = double(Maestro::LicenseGroup, id: 1,
                              site_function?: true,
                              site_function_name: 'my_vocabulary')
        # Step 2: Create a user license that points to this license group
        user_license = double(Maestro::UserLicense, license_group: license_group)
        # Step 3: Ensure that Maestro::UserLicense.all_for_user_and_program returns this user_license (see line 97)
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])
        # Step 4: Create a LicensedContent double that has the license_group created in step 1
        licensed_content = double(Maestro::LicensedContent, license_group_ids: [license_group.id])
        # Step 5: Ensure that Maestro::LicenseContent.find_for_user_and_program returns this licensed_content double
        allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).and_return(licensed_content)
        expect(guardian).to have_vocab_words
      end
    end

    context "when I do not have access to the site function" do
      it 'returns false' do
        # Step 1: Create double LicenseGroup that has site_function? true and site_function_name= 'my_vocabulary' (see line 67)
        license_group = double(Maestro::LicenseGroup, id: 1,
                              site_function?: true,
                              site_function_name: 'my_vocabulary')
        # Step 2: Ensure that Maestro::UserLicense.all_for_user_and_program does not return any user_license
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
        # Step 3: Create a LicensedContent double that has the license_group created in step 1
        licensed_content = double(Maestro::LicensedContent, license_group_ids: [license_group.id])
        # Step 4: Ensure that Maestro::LicenseContent.find_for_user_and_program returns this licensed_content double
        allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).and_return(licensed_content)
        expect(guardian).not_to have_vocab_words
      end
    end

    context "when the site function has expired" do
      it 'returns false' do
        # Step 1: Create double LicenseGroup that has site_function? true and site_function_name= 'my_vocabulary' (see line 67)
        license_group = double(Maestro::LicenseGroup, id: 1,
                              site_function?: true,
                              site_function_name: 'my_vocabulary')
        # Step 2: Create a user license that points to this license group
        user_license = double(Maestro::UserLicense, license_group: license_group)
        # Step 3: Ensure that Maestro::UserLicense.all_for_user_and_program returns this user_license (see line 97)
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])
        # Step 4: Create a LicensedContent double that does not have the license_group created in step 1
        licensed_content = double(Maestro::LicensedContent, license_group_ids: [])
        # Step 5: Ensure that Maestro::LicenseContent.find_for_user_and_program returns this licensed_content double
        allow(Maestro::LicensedContent).to receive(:find_for_user_and_program).and_return(licensed_content)
        expect(guardian).not_to have_vocab_words
      end
    end
  end

  describe '#has_vtext?' do
    let(:vtext_function) { instance_double(SiteFunction) }

    context 'when no program_id is specified' do
      it 'returns true when the user is an instructor' do
        allow(user).to receive(:instructor?).and_return(true)

        expect(guardian).to have_vtext
      end

      context 'when the user is not an instructor' do
        it 'is false when there is no vtext site function' do
          allow(guardian).to receive(:site_functions)
            .and_return({})
          expect(guardian).not_to have_vtext
        end

        context 'when there is a vtext site function' do
          before do
            allow(guardian).to receive(:site_functions)
              .and_return(vtext: vtext_function)
          end

          it 'is true when the vtext site function is accessible to the user' do
            allow(guardian).to receive(:has_accessible_license_group?).and_return(true)

            expect(guardian).to have_vtext
          end

          it 'is false when the vtext site function is not accessible to the user' do
            allow(guardian).to receive(:has_accessible_license_group?).and_return(false)

            expect(guardian).not_to have_vtext
          end
        end
      end
    end

    context 'when a program_id is specified' do
      let(:other_program_id) { build_stubbed(:program).id }

      it 'returns true when the user is an instructor' do
        allow(user).to receive(:instructor?).and_return(true)

        expect(guardian).to have_vtext(other_program_id)
      end

      context 'when the user is not an instructor' do
        it 'is false when there is no vtext site function' do
          allow(guardian).to receive(:site_functions)
            .and_return({})
          expect(guardian).not_to have_vtext(other_program_id)
        end

        context 'when there is a vtext site function' do
          let(:other_program_licensed_content) do
            instance_double(Maestro::LicensedContent)
          end

          before do
            allow(guardian).to receive(:site_functions)
              .and_return(vtext: vtext_function)
            allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
              .with(user.guid, other_program_id)
              .and_return(other_program_licensed_content)
            allow(vtext_function).to receive(:license_group_id).and_return(6)
          end

          it 'is true when the vtext site function for the specified program id ' \
             'is accessible to the user' do
            allow(other_program_licensed_content).to receive(:license_group_ids)
              .and_return([6])

            # Pass the program id as a string because that is how it is
            # stored in the ProgamConfig.
            expect(guardian).to have_vtext(other_program_id.to_s)
          end

          it 'is false when the vtext site function for the specified program id ' \
             'is not accessible to the user' do
            allow(other_program_licensed_content).to receive(:license_group_ids)
              .and_return([5])

            # Pass the program id as a string because that is how it is
            # stored in the ProgamConfig.
            expect(guardian).not_to have_vtext(other_program_id.to_s)
          end
        end
      end
    end
  end

  describe "#has_ebook?" do
    let(:eBook_function) { double('SiteFunction') }

    before do
      allow(guardian).to receive(:site_functions).and_return({ :eBook => eBook_function })
    end

    context "when eBook is accessible for the user" do
      it "returns true" do
        expect(guardian).to receive(:has_accessible_license_group?).with(eBook_function).and_return(true)
        expect(guardian).to have_ebook
      end
    end

    context "when eBook is not accessible for the user" do
      it "returns false" do
        expect(guardian).to receive(:has_accessible_license_group?).with(eBook_function).and_return(false)
        expect(guardian).not_to have_ebook
      end
    end

  end

  describe "#has_live_chat?" do
    let(:live_chat_site_function) { double('SiteFunction') }

    before do
      allow(guardian).to receive(:site_functions).and_return({ :live_chat => live_chat_site_function })
    end

    context "when the my vocabulary site function is accessible for the user" do
      it "returns true" do
        expect(guardian).to receive(:has_accessible_license_group?).with(live_chat_site_function).and_return(true)
        expect(guardian.has_live_chat?).to be_truthy
      end
    end

    context "when the my vocabulary site function is not accessible for the user" do
      it "returns false" do
        expect(guardian).to receive(:has_accessible_license_group?).with(live_chat_site_function).and_return(false)
        expect(guardian.has_live_chat?).to be_falsey
      end
    end
  end

  describe '#has_mobile_app?' do
    let(:user_license) { double('UserLicense', :expired? => false, :practice_app? => true) }

    before do
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])
    end

    context 'when license has not expired' do
      it 'is true when user has practice app access' do
        expect(guardian).to have_mobile_app
      end

      it 'is false when user does not have practice app access' do
        allow(user_license).to receive(:practice_app?).and_return(false)
        expect(guardian).not_to have_mobile_app
      end
    end

    it 'is false when license has expired' do
      allow(user_license).to receive(:expired?).and_return(true)
      expect(guardian).not_to have_mobile_app
    end
  end

  describe '#has_portfolio?' do
    context 'when the user is a fake student' do
      before do
        allow(user).to receive(:fake?).and_return(true)
      end

      it 'calls has_portfolio_for_fake_student?' do
        allow(guardian).to receive(:has_portfolio_for_fake_student?)
        guardian.has_portfolio?
        expect(guardian).to have_received(:has_portfolio_for_fake_student?)
      end
    end

    context 'when the user is not a fake student' do
      before do
        allow(user).to receive(:fake?).and_return(false)
      end

      it 'calls has_portfolio_access?' do
        allow(guardian).to receive(:has_portfolio_access?)
        guardian.has_portfolio?
        expect(guardian).to have_received(:has_portfolio_access?)
      end
    end
  end

  describe '#has_portfolio_access?' do
    let(:portfolio_license_group) do
      instance_double(
        Maestro::LicenseGroup,
        id: 26,
        name: 'Portfolio',
        site_function?: true,
        site_function_name: 'portfolio'
      )
    end
    let(:portfolio_user_license) do
      instance_double(
        Maestro::UserLicense,
        expired?: false,
        license_group: portfolio_license_group,
        websam?: false
      )
    end

    context 'when the user has the portfolio license group' do
      before do
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
          .and_return([portfolio_user_license])
        allow(licensed_content).to receive(:license_group_ids)
          .and_return([portfolio_license_group.id])
      end

      it 'is true when user has portfolio access, and the user license has not expired' do
        expect(guardian).to have_portfolio
      end
    end

    context 'when the user does not have the portfolio license group' do
      before do
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
          .and_return([])
      end

      it 'is false when user does not have portfolio access' do
        expect(guardian).not_to have_portfolio
      end
    end
  end

  describe '#has_portfolio_for_fake_student?' do
    let(:section_instructor) { build_stubbed(:instructor) }
    let(:school) { create(:school) }
    let(:course) { create(:course, program:, school:) }
    let(:section) { create(:section, course:, instructor: section_instructor) }
    let(:instructor_access_guardian) { instance_double(described_class) }

    before do
      allow(user).to receive(:fake?).and_return(true)
      allow(user).to receive(:sections).and_return([section])
      allow(described_class).to receive(:new).with(user, program).and_return(guardian)
      allow(described_class)
        .to receive(:new)
        .with(section_instructor, program)
        .and_return(instructor_access_guardian)
    end

    context 'when instructor corresponding to the section of the fake student exists' do
      it 'returns true if the instructor has portfolio access' do
        allow(instructor_access_guardian).to receive(:has_portfolio?).and_return(true)
        expect(guardian.has_portfolio_for_fake_student?).to be true
      end

      it 'returns false if the instructor does not have portfolio access' do
        allow(instructor_access_guardian).to receive(:has_portfolio?).and_return(false)
        expect(guardian.has_portfolio_for_fake_student?).to be false
      end
    end

    context 'when instructor is not found' do
      before do
        allow(user).to receive(:sections).and_return([])
      end

      it 'returns nil' do
        expect(guardian.has_portfolio_for_fake_student?).to be_falsey
      end
    end
  end

  describe '#premium_license?' do
    let(:premium_license_id) { 23 }
    let(:non_premium_license_id) { 2 }

    it 'is true when an activity is premium content' do
      expect(guardian.premium_license?(premium_license_id)).to be_truthy
    end

    it 'is false when an activity is not premium content' do
      expect(guardian.premium_license?(non_premium_license_id)).to be_falsey
    end

    it 'is false if the license id passed in is nil' do
      expect(guardian.premium_license?(nil)).to be_falsey
    end
  end

  describe "#valid_program_units" do
    let(:unit_1){ build_stubbed(:unit, :rank => 0)}
    let(:unit_2){ build_stubbed(:unit, :rank => 1)}
    let(:unit_3){ build_stubbed(:unit, :rank => 2)}

    before do
      allow(program).to receive(:units).and_return([unit_1, unit_2, unit_3])
    end

    context "when the program units are a comma separated list e.g. 1,2,3" do
      it "returns an array of the program units tokenized" do
        allow(guardian).to receive_message_chain(:user_licensed_content, :lessons).and_return('1,2,3')
        expect(guardian.valid_program_units).to match_array([0, 1, 2])
      end
    end

    context "when the program units are a dash separated list e.g. 1-10" do
      it "returns an array of the program units expanded" do
        allow(guardian).to receive_message_chain(:user_licensed_content, :lessons).and_return('1-4')
        expect(guardian.valid_program_units).to match_array([0, 1, 2, 3])
      end
    end

    context "when the program units are a mix of comma separated and dash separated numbers, e.g. 1,2,3-10" do
      it "returns an array of the program units expanded" do
        allow(guardian).to receive_message_chain(:user_licensed_content, :lessons).and_return('1,2,3-6')
        expect(guardian.valid_program_units).to match_array([0, 1, 2, 3, 4, 5])
      end
    end

    context "when the program units is just a star" do
      it "returns an array of all program units for that program" do
        allow(guardian).to receive_message_chain(:user_licensed_content, :lessons).and_return('*')
        expect(guardian.valid_program_units).to match_array([0, 1, 2])
      end
    end

    context "when the program units is a dash separated number with a star, e.g. 4-*" do
      it "returns an array of the program units from the start number to the last unit in the program" do
        allow(guardian).to receive_message_chain(:user_licensed_content, :lessons).and_return('1-*')
        expect(guardian.valid_program_units).to match_array([0, 1, 2])
      end
    end
  end

  describe '#demo_access_expiration_date' do
    it 'returns the expiration date for a demo user license' do
      demo_license = double(Maestro::UserLicense,
                            demo: true,
                            expiration_date: 5.days.from_now.to_date.to_s)
      other_license = double(Maestro::UserLicense,
                             demo: false,
                             expiration_date: 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([other_license, demo_license])
      expect(guardian.demo_access_expiration_date).to eql demo_license.expiration_date
    end

    it 'returns nil when the license is not a demo user license' do
      non_demo_license = double(Maestro::UserLicense,
                                demo: false,
                                expiration_date: 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([non_demo_license])
      expect(guardian.demo_access_expiration_date).to be_nil
    end
  end

  describe '#ebook_expiration_date' do
    it 'returns the expiration date for an ebook license' do
      ebook_expiration = 5.days.from_now.to_date.to_s
      ebook_license_group = double(Maestro::LicenseGroup, name: 'eBook')
      ebook_license = double(Maestro::UserLicense,
                             license_group: ebook_license_group,
                             expiration_date: ebook_expiration)

      other_expiration = 6.days.from_now.to_date.to_s
      other_license_group = double(Maestro::LicenseGroup, name: 'Practice App')
      other_license = double(Maestro::UserLicense,
                             license_group: other_license_group,
                             expiration_date: other_expiration)

      allow(Maestro::UserLicense).to receive(:all_for_user_and_program) do
        [other_license, ebook_license]
      end

      expect(guardian.ebook_expiration_date).to eq(ebook_expiration)
    end

    it 'returns nil when the user has no ebook licenses' do
      other_expiration = 6.days.from_now.to_date.to_s
      other_license_group = double(Maestro::LicenseGroup, name: 'Practice App')
      other_license = double(Maestro::UserLicense,
                             license_group: other_license_group,
                             expiration_date: other_expiration)

      allow(Maestro::UserLicense).to receive(:all_for_user_and_program) do
        [other_license]
      end

      expect(guardian.ebook_expiration_date).to be_nil
    end
  end

  describe "ever_had_demo_access?" do
    it "returns true when the user has an active demo user license" do
      demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.from_now.to_date.to_s)
      other_license = double('Maestro::UserLicense', :demo => false, :expiration_date => 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([other_license, demo_license])
      expect(guardian.ever_had_demo_access?).to be_truthy
    end

    it "returns true when the user has an expired demo user license" do
      demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.ago.to_date.to_s)
      other_license = double('Maestro::UserLicense', :demo => false, :expiration_date => 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([other_license, demo_license])
      expect(guardian.ever_had_demo_access?).to be_truthy
    end

    it "returns false when the user has never had demo access" do
      non_demo_license = double('Maestro::UserLicense', :demo => false, :expiration_date => 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([non_demo_license])
      expect(guardian.ever_had_demo_access?).to be_falsey
    end
  end

  describe "has_unexpired_demo_access?" do
    it "returns true when the user has an active demo user license" do
      demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.from_now.to_date.to_s)
      other_license = double('Maestro::UserLicense', :demo => false, :expiration_date => 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([other_license, demo_license])
      expect(guardian.has_unexpired_demo_access?).to be_truthy
    end

    it "returns false when the user has an expired demo user license" do
      demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.ago.to_date.to_s)
      other_license = double('Maestro::UserLicense', :demo => false, :expiration_date => 6.days.from_now.to_date.to_s)
      allow(guardian).to receive(:user_licenses).and_return([other_license, demo_license])
      expect(guardian.has_unexpired_demo_access?).to be_falsey
    end
  end

    describe "#demo_days_remaining" do
    context "if demo access has not expired" do
      it "returns the number of days left for the demo to expire" do
        demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.from_now.to_date.to_s)
        allow(guardian).to receive(:user_licenses).and_return([demo_license])
        expect(guardian.demo_days_remaining).to eql 5
      end
    end

    context "if demo access expired" do
      it "returns a negative number when the demo has expired" do
        demo_license = double('Maestro::UserLicense', :demo => true, :expiration_date => 5.days.ago.to_date.to_s)
        allow(guardian).to receive(:user_licenses).and_return([demo_license])
        expect(guardian.demo_days_remaining).to eql -5
      end
    end
  end
end
