describe Role do

  describe "#find_sales_rep" do
    let!(:role){ Role.new(:name => Role::SALES_REP) }

    it "finds users whose username is the passed param plus _admin" do
      user = create(:student, :username => 'srep_admin')
      user.roles << role
      expect(Role.find_sales_rep('SREP')).to eq(user)
    end

    it "excludes users whose don't have sales rep privileges" do
      user = create(:user, :username => 'srep_admin')
      expect(Role.find_sales_rep('SREP')).to eq(nil)
    end

    it "returns oup_admin if passed OXFORD" do
      user = create(:student, :username => 'oup_admin')
      user.roles << role
      expect(Role.find_sales_rep('OXFORD')).to eq(user)
    end
  end

end
