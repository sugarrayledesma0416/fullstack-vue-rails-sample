describe GracePeriodAllocation do
  let(:gp_counts) { GracePeriodAllocation.new(1) }

  before do
    allow(Maestro::School).to receive(:grace_period_allocation).with(anything).and_return({'number_used' => 1, 'number_allowed' => 5})
  end

  it "exposes the school_id" do
    expect(gp_counts.school_id).to eq(1)
  end

  describe "grace_period_allocation" do
    it "calls api to fetch grace period count figures for a school" do
      expect(Maestro::School).to receive(:grace_period_allocation).with(anything).and_return({'number_used' => 0, 'number_allowed' => 0})
      gp_counts.grace_period_allocation
    end
  end

  describe "allowed?" do
    it "returns true when the number_allowed is greater than zero" do
      expect(gp_counts).to be_allowed
    end
  end

  describe "allowed" do
    it "return the number of grace periods allowed for the school" do
      expect(gp_counts.allowed).to eq(5)
    end
  end

  describe "used" do
    it "returns the number of grace periods used" do
      expect(gp_counts.used).to eq(1)
    end
  end

  describe "remaining" do
    it "returns the number of grace periods remaining" do
      expect(gp_counts.remaining).to eq(4)
    end
  end
end
