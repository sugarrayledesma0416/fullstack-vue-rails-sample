describe Array do
  describe "#intersect" do
    it "returns intersections for unordered arrays" do
      array_1 = [1,2,3,4]
      array_2 = [5,3,6,2]
      expect(array_1.intersect(array_2)).to eq([2,3])
    end

    it "returns intersections for arrays of different lengths" do
      array_1 = [1,2,3,4]
      array_2 = [2,3,3,3,5,6,7]
      expect(array_1.intersect(array_2)).to eq([2,3])
      expect(array_2.intersect(array_1)).to eq([2,3])
    end
  end

  describe "#most_common_item" do
    it "should return an item with 2 instances if all others have one" do
      expect([1, 3, 2, 3].most_common_item).to eq(3)
    end

    it "should return the first item encountered when there is a tie" do
      expect([2, 1, 1, 2].most_common_item).to eq(2)
    end

    it "should return nil for an empty array" do
      expect([].most_common_item).to eq(nil)
    end
  end

end
