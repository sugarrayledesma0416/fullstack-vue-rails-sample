describe School do

  describe 'validation of assign_related_objects' do
    let(:sales_rep)   { create(:user) }
    let(:district)    { create(:school) }
    let(:valid_attrs) do { "sync_token" => 1, "sales_rep_guid" => sales_rep.guid,
                           "request_id" => 'b6da4613-03c3-49a8-ba25-5043eebac1a6',
                           "district_guid" => district.guid }
    end
    let(:missing_attrs) do { "sync_token" => 1,
                           "request_id" => 'b6da4613-03c3-49a8-ba25-5043eebac1a6'}
    end
    it 'finds and sets related sales_rep and district_id from guids' do
      Dangerfield::Gatekeeper.instance.disabled = false
      school = described_class.new
      described_class.dangerfield_update_attributes(valid_attrs, school)
      school = described_class.last
      expect(school.sales_rep.id).to eq(sales_rep.id)
      expect(school.district_id).to eq(district.id)
      Dangerfield::Gatekeeper.instance.disabled = true
    end

    it 'handles missing sales_rep and district guids' do
      Dangerfield::Gatekeeper.instance.disabled = false
      school = described_class.new
      described_class.dangerfield_update_attributes(missing_attrs, school)
      school = described_class.last
      expect(school.sales_rep).to be_nil
      expect(school.district_id).to be_nil
      Dangerfield::Gatekeeper.instance.disabled = true
    end
  end

  describe 'validation of time zones' do
    let(:school) { create(:school) }

    it 'is valid when the time zone is nil' do
      school.time_zone = nil
      expect(school).to be_valid
    end

    it 'ensures the time zone is in the list of supported time zones' do
      school.time_zone = 'blah'
      expect(school).not_to be_valid
    end

    it 'is invalid when the time zone is not in the list of supported time zones' do
      school.time_zone = 'Eastern Time (US & Canada)'
      expect(school).to be_valid
    end
  end

  describe "#country_name" do
    it "returns the country name for a school's country code" do
      Country.create!(:code => 'MUL', :name => 'MadeUpLandia')
      school = create(:school, :country_code => 'MUL')
      expect(school.country_name).to eq('MadeUpLandia')
    end

    it "returns empty string if no country code is set" do
      school = create(:school, :country_code => nil)
      expect(school.country_name).to eq('')
    end

    it "returns empty string if country is US or Canada" do
      Country.create!(:code => 'USA', :name => 'United States')
      Country.create!(:code => 'CAN', :name => 'Canada')
      school1 = create(:school, :country_code => 'USA')
      school2 = create(:school, :country_code => 'CAN')
      expect(school1.country_name).to eq('')
      expect(school2.country_name).to eq('')
    end

    it "returns empty string if no country matches the code" do
      school = create(:school, :country_code => 'BADCODE')
      expect(school.country_name).to eq('')
    end
  end

  describe "#active_instructors_with_program_access" do
    let(:school) { build_stubbed(:school) }
    let(:program) { build_stubbed(:program) }

    # Returned from Maestro client
    let(:active_instructor) { FactoryBot.create(:instructor, archived: false) }
    let(:archived_instructor) { FactoryBot.create(:instructor, archived: true) }
    let(:all_instructors) do
      { 'instructor_guids' => [active_instructor.guid, archived_instructor.guid],
        'instructor_ids' => [active_instructor.id, archived_instructor.id] }
    end

    before do
      allow(Maestro::School).to receive(:instructors).and_return(all_instructors)
    end

    it 'should call method which filters instructors at a school by program access' do
      expect(Maestro::School).to receive(:instructors).with(school.guid, program.id)
      school.active_instructors_with_program_access(program)
    end

    it 'should filter out archived users' do
      instructors = school.active_instructors_with_program_access(program)

      expect(instructors).not_to include(archived_instructor)
      expect(instructors).to include(active_instructor)
    end

    it 'returns M3 Instructors' do
      instructors = school.active_instructors_with_program_access(program)

      instructors.map do |instructor|
        expect(instructor).to be_an(Instructor)
      end
    end
  end

  describe ".real_students" do
    it "should only return real students" do
      school = create(:school)
      fake_student = create(:student, :fake => true)
      real_student = create(:student)
      school.students << fake_student
      school.students << real_student
      expect(school.real_students).to eq([real_student])
    end
  end

  describe "#category_from_school_type" do
    it "returns the appropriate category" do
      expect(School.category_from_school_type('4-Year College')).to eq(1)
      expect(School.category_from_school_type('2-Year College')).to eq(1)
      expect(School.category_from_school_type('Online University')).to eq(1)
      expect(School.category_from_school_type('Private')).to eq(2)
      expect(School.category_from_school_type('Catholic')).to eq(2)
      expect(School.category_from_school_type('Catholic State')).to eq(2)
      expect(School.category_from_school_type('Private State')).to eq(2)
      expect(School.category_from_school_type('Public')).to eq(3)
      expect(School.category_from_school_type('Proprietary')).to eq(4)
      expect(School.category_from_school_type('International')).to eq(4)
      expect(School.category_from_school_type('Other')).to eq(4)
      expect(School.category_from_school_type('Continuing Ed')).to eq(4)
      expect(School.category_from_school_type('Prospect')).to eq(4)
      expect(School.category_from_school_type('District')).to eq(4)
    end

    it "returns nil when no category matches" do
      expect(School.category_from_school_type('Invalid Type')).to be_nil
      expect(School.category_from_school_type('')).to  be_nil
      expect(School.category_from_school_type(nil)).to be_nil
    end
  end


  context "with instructors and students at a school" do
    before(:each) do
      @school = create(:school)
      @students = [create(:student),
                   create(:student),
                   create(:student)]
      @students.each {|student| @school.students << student}
      @instructors = [create(:instructor),
                      create(:instructor),
                      create(:instructor )]
      @instructors.each {|instructor| @school.instructors << instructor}
    end

    it "should only return instructors when asked for instructors" do
      expect(@school.instructors).to eq(@instructors)
    end

    it "should only return students when asked for students" do
      students = @school.students
      students.each do |student|
        expect(@students).to include(student)
      end
    end
  end

  describe '#district?' do
    it "returns false when school_type is not 'District'" do
      school_1 = build(:school)
      school_2 = build(:school, school_type: 'Other type')
      expect(school_1).not_to be_district
      expect(school_2).not_to be_district
    end

    it "returns true when school_type is 'District'" do
      school = build(:school, school_type: 'District')
      expect(school).to be_district
    end

    it "returns true when school_type is 'district'" do
      school = build(:school, school_type: 'district')
      expect(school).to be_district
    end

    it "returns true when school_type is 'dIsTricT'" do
      school = build(:school, school_type: 'dIsTricT')
      expect(school).to be_district
    end
  end

  describe '#district' do
    it "returns school's district" do
      district = create(:district)
      school = create(:school, district_id: district.id)
      expect(school.district).to eql(district)
    end

    it 'returns nil if school does not have a district' do
      school = create(:school)
      expect(school.district).to be_nil
    end
  end

  describe '#clever?' do
    it 'returns false if clever_id is nil' do
      expect(build(:school, clever_id: nil)).not_to be_clever
    end

    it 'returns true if clever_id has some value' do
      school = build(:clever_school)
      expect(school).to be_clever
    end
  end

  describe '#clever_rostering?' do
    it 'returns false if clever_integration_type is empty' do
      expect(create(:school, clever_integration_type: nil)).not_to be_clever_rostering
      expect(create(:school, clever_integration_type: '')).not_to be_clever_rostering
    end

    it 'returns false if clever_integration_type is SSO' do
      expect(create(:clever_school, clever_integration_type: 'SSO')).not_to be_clever_rostering
    end

    it 'returns true if clever_integration_type is rostering' do
      expect(create(:clever_school, clever_integration_type: 'Rostering')).to be_clever_rostering
    end
  end

  describe '#rostering?' do
    it 'returns false if both clever_integration_type and one_roster_integration_type are empty' do
      expect(create(:school, clever_integration_type: nil)).not_to be_rostering
      expect(create(:school, clever_integration_type: '')).not_to be_rostering
      expect(create(:school, one_roster_integration_type: nil)).not_to be_rostering
      expect(create(:school, one_roster_integration_type: '')).not_to be_rostering
    end

    it 'returns false if clever_integration_type is SSO' do
      expect(create(:clever_school, clever_integration_type: 'SSO')).not_to be_rostering
    end

    it 'returns true if clever_integration_type is rostering' do
      expect(create(:clever_school, clever_integration_type: 'Rostering')).to be_rostering
    end

    it 'returns true if one_roster_integration_type is SSO-Rostering' do
      expect(create(:one_roster_sso_school)).to be_rostering
    end

    it 'returns true if rostering type is Rostering' do
      expect(create(:one_roster_school)).to be_rostering
    end
  end

  describe '#enterprise_for_program?' do
    it 'returns false if there are no admins for the school and program' do
      school = create(:school)
      program = create(:program)
      expect(school.enterprise_for_program?(program)).to be false
    end

    it 'returns true if there are admins for the school and program' do
      school = create(:school)
      program = create(:program)
      admin = create(:institution_admin)
      create(:school_program_admin_user,
             user: admin,
             school: school,
             program: program,
             account_type: admin.account_type)

      expect(school.enterprise_for_program?(program)).to be true
    end
  end

  describe ".find_district_guid" do
    it "returns guid of school's district" do
      school = create(:school)
      district = create(:school)
      school.district_id = district.id
      expect(school.find_district_guid).to eql(district.guid)
    end

    it 'returns nil if school does not have a district' do
      school = create(:school)
      expect(school.find_district_guid).to be_nil
    end
  end

  describe ".by_guid" do
    it 'returns school that matches specified guid' do
      new_school = create(:school)
      expect(School.by_guid(new_school.guid)).to eql(new_school)
    end
  end

  describe '#gradebook_analytics_enabled?' do
    let(:school) { create(:school) }

    context 'if school is in the gradebook-v2 table' do
      it 'returns true' do
        create(:gradebook_analytics_school, school_id: school.id)
        expect(school.gradebook_analytics_enabled?).to be true
      end
    end

    context 'if school is not in gradebook-v2 table' do
      it 'returns false' do
        expect(school.gradebook_analytics_enabled?).to be false
      end
    end
  end

  describe '#is_parent_institution?' do
    it 'returns true if school is a parent_institution' do
      parent_school = create(:school)
      child_school = create(:school, parent_institution_id: parent_school.id)
      expect(parent_school.is_parent_institution?).to be_truthy
    end

     it 'returns false if school is not a parent_institution' do
      school = create(:school)
      expect(school.is_parent_institution?).to be_falsey
     end
  end

  describe '#can_share_to_google_classroom?' do
    context 'when school is of type district' do
      it 'return school`s share_to_google_classroom' do
        school = create(:school, school_type: 'District', share_to_google_classroom: true)
        expect(school.can_share_to_google_classroom?).to be(school.share_to_google_classroom)
      end
    end

    context 'when school does not have a district' do
      it 'returns school`s share_to_google_classroom' do
        school = create(:school, school_type: 'Default', share_to_google_classroom: false)
        expect(school.can_share_to_google_classroom?).to be(school.share_to_google_classroom)
      end
    end

    context 'when school has a district, compare share_to_google_classroom_last_updated_at' do
      context 'when school`s share_to_google_classroom_last_updated_at is greater' do
        it 'return school`s share_to_google_classroom' do
          district = create(
            :school,
            school_type: 'District',
            share_to_google_classroom: false,
            share_to_google_classroom_last_updated_at: DateTime.now.utc - 1.day
          )
          school = create(
            :school,
            district_id: district.id,
            share_to_google_classroom: true,
            share_to_google_classroom_last_updated_at: DateTime.now.utc
          )
          expect(school.can_share_to_google_classroom?).to be(school.share_to_google_classroom)
        end
      end

      context 'when district`s share_to_google_classroom_last_updated_at is greater' do
        it 'return district`s share_to_google_classroom' do
          district = create(
            :school,
            school_type: 'District',
            share_to_google_classroom: true,
            share_to_google_classroom_last_updated_at: DateTime.now.utc
          )
          school = create(
            :school,
            district_id: district.id,
            share_to_google_classroom: false,
            share_to_google_classroom_last_updated_at: DateTime.now.utc - 1.day
          )
          expect(school.can_share_to_google_classroom?).to be(district.share_to_google_classroom)
        end
      end
    end
  end

  describe '#has_chat_support_enabled?' do
    context 'when the school is a district,' do
      let(:school) { create(:district) }

      it 'return true when the district has no config' do
        expect(school).to have_chat_support_enabled
      end

      it 'return true when the district explicitly enabled chat support' do
        create(:school_config, school:, chat_support_disabled: false)

        expect(school).to have_chat_support_enabled
      end

      it 'return false when the district explicitly disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect(school).not_to have_chat_support_enabled
      end
    end

    context 'when the school has no district,' do
      let(:school) { create(:school) }

      it 'return true when the school has no config' do
        expect(school).to have_chat_support_enabled
      end

      it 'return true when the school explicitly enabled chat support' do
        create(:school_config, school:, chat_support_disabled: false)

        expect(school).to have_chat_support_enabled
      end

      it 'return false when the school explicitly disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect(school).not_to have_chat_support_enabled
      end
    end

    context 'when the school has a district,' do
      let(:district) { create(:district) }
      let(:school) { create(:school, district:) }

      context 'when the district enabled chat support,' do
        before do
          create(:school_config, school: district, chat_support_disabled: false)
        end

        it 'return true when the school has no config' do
          expect(school).to have_chat_support_enabled
        end

        it 'return true when the school explicitly enabled chat support' do
          create(:school_config, school:, chat_support_disabled: false)

          expect(school).to have_chat_support_enabled
        end

        it 'return false when the school explicitly disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          expect(school).not_to have_chat_support_enabled
        end
      end

      context 'when the district disabled chat support,' do
        before do
          create(:school_config, school: district, chat_support_disabled: true)
        end

        it 'return false when the school has no config' do
          expect(school).not_to have_chat_support_enabled
        end

        it 'return false when the school explicitly enabled chat support' do
          create(:school_config, school:, chat_support_disabled: false)

          expect(school).not_to have_chat_support_enabled
        end

        it 'return false when the school explicitly disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          expect(school).not_to have_chat_support_enabled
        end
      end
    end
  end

  describe '#has_chat_support_disabled?' do
    context 'when the school is a district,' do
      let(:school) { create(:district) }

      it 'return false when the district has no config' do
        expect(school).not_to have_chat_support_disabled
      end

      it 'return false when the district explicitly enabled chat support' do
        create(:school_config, school:, chat_support_disabled: false)

        expect(school).not_to have_chat_support_disabled
      end

      it 'return true when the district explicitly disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect(school).to have_chat_support_disabled
      end
    end

    context 'when the school has no district,' do
      let(:school) { create(:school) }

      it 'return false when the school has no config' do
        expect(school).not_to have_chat_support_disabled
      end

      it 'return false when the school explicitly enabled chat support' do
        create(:school_config, school:, chat_support_disabled: false)

        expect(school).not_to have_chat_support_disabled
      end

      it 'return true when the school explicitly disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect(school).to have_chat_support_disabled
      end
    end

    context 'when the school has a district,' do
      let(:district) { create(:district) }
      let(:school) { create(:school, district:) }

      context 'when the district enabled chat support,' do
        before do
          create(:school_config, school: district, chat_support_disabled: false)
        end

        it 'return false when the school has no config' do
          expect(school).not_to have_chat_support_disabled
        end

        it 'return false when the school explicitly enabled chat support' do
          create(:school_config, school:, chat_support_disabled: false)

          expect(school).not_to have_chat_support_disabled
        end

        it 'return true when the school explicitly disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          expect(school).to have_chat_support_disabled
        end
      end

      context 'when the district disabled chat support,' do
        before do
          create(:school_config, school: district, chat_support_disabled: true)
        end

        it 'return true when the school has no config' do
          expect(school).to have_chat_support_disabled
        end

        it 'return true when the school explicitly enabled chat support' do
          create(:school_config, school:, chat_support_disabled: false)

          expect(school).to have_chat_support_disabled
        end

        it 'return true when the school explicitly disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          expect(school).to have_chat_support_disabled
        end
      end
    end
  end

  describe '#school_content_sharing?' do
    subject(:school) { build_stubbed(:school, school_config:) }

    context 'when the school does not have school_config' do
      let(:school_config) { nil }

      it { expect(school.school_content_sharing?).to be true }
    end

    context 'when the school has school_config' do
      let(:school_config) { build_stubbed(:school_config) }

      context 'when the school_content_sharing configuration is true' do
        before { school_config.school_content_sharing = true }

        it { expect(school.school_content_sharing?).to be true }
      end

      context 'when the school_content_sharing configuration is false' do
        before { school_config.school_content_sharing = false }

        it { expect(school.school_content_sharing?).to be false }
      end
    end
  end

  describe '#program_content_sharing?' do
    subject(:school) { build_stubbed(:school, school_config:) }

    context 'when the school does not have school_config' do
      let(:school_config) { nil }

      it { expect(school.program_content_sharing?(347)).to be true }
    end

    context 'when the school has school_config' do
      let(:school_config) { build_stubbed(:school_config) }

      context 'when there is a true configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = true }

        it { expect(school.program_content_sharing?(347)).to be true }
      end

      context 'when there is a false configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = false }

        it { expect(school.program_content_sharing?(347)).to be false }
      end
    end
  end

  describe '#sharing_content_for_program?' do
    subject(:school) { build_stubbed(:school, school_config:, district:) }

    context 'when the school does not belongs to a district' do
      let(:district) { nil }

      it_behaves_like 'school sharing content for program'
    end

    context 'when the school belongs to a district' do
      let(:district) { build_stubbed(:district, school_config: district_config) }

      context 'when the district does not have school_config' do
        let(:district_config) { nil }

        it_behaves_like 'school sharing content for program'
      end

      context 'when the district has school_config' do
        let(:district_config) { build_stubbed(:school_config) }

        context 'when the district is not allowed to share content' do
          let(:school_config) { build_stubbed(:school_config) }

          before { district_config.school_content_sharing = false }

          context 'when the school is allowed to share' do
            before do
              school_config.school_content_sharing = true
              school_config.program_content_sharing_json['347'] = true
            end

            it { expect(school.sharing_content_for_program?(347)).to be false }
          end

          context 'when the school is not allowed to share' do
            before do
              school_config.school_content_sharing = false
              school_config.program_content_sharing_json['347'] = false
            end

            it { expect(school.sharing_content_for_program?(347)).to be false }
          end
        end

        context 'when the district is allowed to share content' do
          before { district_config.school_content_sharing = true }

          it_behaves_like 'school sharing content for program'
        end
      end
    end
  end

  describe '#k12?' do
    subject(:school) { build_stubbed(:school, school_type_category:) }

    context 'when school is school_type_category 3' do
      let(:school_type_category) { 3 }

      it { expect(school).to be_k12 }
    end

    context 'when school is school_type_category 2' do
      let(:school_type_category) { 2 }

      it { expect(school).to be_k12 }
    end

    context 'when school is different from school_type_category 2 or 3' do
      let(:school_type_category) { 1 }

      it { expect(school).not_to be_k12 }
    end
  end
end
