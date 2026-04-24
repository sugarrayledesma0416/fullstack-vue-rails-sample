describe InstitutionAdmin do
  let(:user) { create(:institution_admin) }
  let(:school) { create(:school) }
  let(:school_two) { create(:school) }
  let(:program) { create(:program) }
  let(:program_two) { create(:program) }
  let(:district) { create(:district, name: 'VHL District 1') }

  describe '#admin_for_school?' do
    it 'returns false if the user is not an admin in the given school' do
      create(:school_user, user: user, school: school)
      expect(user.admin_for_school?(school)).to be false
    end

    it 'returns true if the user is an admin in the given school' do
      create_school_program_admin_user(user, program, school)
      expect(user.admin_for_school?(school)).to be true
    end
  end

  describe '#admin_district_programs' do
    it 'return all programs belonging to a district' do
      district.schools << school
      district.schools << school_two
      create_school_program_admin_user(user, program, school)
      create_school_program_admin_user(user, program_two, school)
      create_school_program_admin_user(user, program, school_two)
      create_school_program_admin_user(user, program_two, school_two)
      expect(user.admin_district_programs(district)).to match_array([program, program_two])
    end
  end

  def create_school_program_admin_user(user, program, school)
    create(:school_program_admin_user,
           user: user,
           school: school,
           program: program,
           account_type: 'InstitutionAdmin')
  end
end
