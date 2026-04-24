describe Instructor::CoursesHelper do
  include Instructor::CoursesHelper

  describe "#category_max_attempts" do
    context "when max attempts is unlimited" do
      it "returns 'unlimited'" do
        category = create(:category, :max_attempts => -1)
        expect(category_max_attempts(category)).to eql 'unlimited'
      end
    end

    context "when max attempts is not unlimited" do
      it "returns a string with max attempts" do
        max_attempts = 2
        category = create(:category, :max_attempts => max_attempts)
        expect(category_max_attempts(category)).to eql max_attempts.to_s
      end
    end
  end

end
