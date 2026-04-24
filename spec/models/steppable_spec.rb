describe Steppable do
  
  class SteppableTestClass
    include Steppable

    def steps
      %w{step1 step2 step3 step4}
    end
  end
  
  describe "#current_step" do
    it "should return the current step if it is set" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = 'step2'
      expect(steppable_test.current_step).to eql 'step2'
    end
    
    it "should return the first step if no current step is set" do
      steppable_test = SteppableTestClass.new
      expect(steppable_test.current_step).to eql steppable_test.steps.first
    end
  end
  
  describe "#next_step" do
    it "should return to the next step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps[1]
      expect(steppable_test.next_step).to eql steppable_test.steps[2]
    end
    
    it "should return the first step if on the last step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.last
      expect(steppable_test.next_step).to eql steppable_test.steps.first
    end    
  end
  
  describe "#previous_step" do
    it "should return the previous step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps[3]
      expect(steppable_test.previous_step).to eql steppable_test.steps[2]
    end
    
    it "should return the last step if on the first step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.first
      expect(steppable_test.previous_step).to eql steppable_test.steps.last
    end
  end
  
  describe "#first_step?" do
    it "should return true if current step is the first step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.first
      expect(steppable_test.first_step?).to be_truthy
    end
    
    it "should return false if current step is not the first step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.last
      expect(steppable_test.first_step?).to be_falsey
    end
  end
  
  describe "#last_step?" do
    it "should return true if current step is the last step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.last
      expect(steppable_test.last_step?).to be_truthy
    end
    
    it "should return false if current step is not the last step" do
      steppable_test = SteppableTestClass.new
      steppable_test.current_step = steppable_test.steps.first
      expect(steppable_test.last_step?).to be_falsey
    end
  end

  describe "#step_class" do
    before(:each) do
      @steppable_test = SteppableTestClass.new
      @steppable_test.current_step = @steppable_test.steps[1]
    end

    it "should return 'current' for the current step" do
      expect(@steppable_test.step_class(@steppable_test.steps[1])).to eql 'current'
    end

    it "should return 'complete' for previous steps" do
      expect(@steppable_test.step_class(@steppable_test.steps[0])).to eql 'complete'
    end

    it "should return a blank string for future steps" do
      expect(@steppable_test.step_class(@steppable_test.steps.last)).to eql ''
    end
  end
  
  describe "#current_step?" do
    before(:each) do
      @steppable_test = SteppableTestClass.new
      @steppable_test.current_step = @steppable_test.steps[1]
    end
    
    it "should return true is current step equals step passed as param" do
      step_test = @steppable_test.steps[1]
      expect(@steppable_test.current_step?(step_test)).to be true
    end
    
    it "should return true is current step is not the same step passed as param" do
      step_test = @steppable_test.steps[0]
      expect(@steppable_test.current_step?(step_test)).to be false
    end
    
  end
  
end
