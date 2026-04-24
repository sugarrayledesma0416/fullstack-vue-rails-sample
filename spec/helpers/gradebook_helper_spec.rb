describe GradebookHelper do
  describe"#format_as_decimal_without_trailing_zero" do
    it 'returns 0 when given Nan' do
      expect(helper.format_as_decimal_without_trailing_zero(Float::NAN)).to eq(0)
    end

    it "should return a number with one decimal precision if decimal is not zero" do
      expect(helper.format_as_decimal_without_trailing_zero(145.25)).to eql 145.3
      expect(helper.format_as_decimal_without_trailing_zero(23.1)).to eql 23.1
      expect(helper.format_as_decimal_without_trailing_zero(4.0).is_a?(Float)).to be_falsey
    end

    it "should return a string if passed a string" do
      expect(helper.format_as_decimal_without_trailing_zero('Pending')).to eql 'Pending'
      expect(helper.format_as_decimal_without_trailing_zero('-')).to eql '-'
    end

    it "should return a whole number if passed a number with trailing .0" do
      expect(helper.format_as_decimal_without_trailing_zero(145.0)).to eql 145
      expect(helper.format_as_decimal_without_trailing_zero(23)).to eql 23
      expect(helper.format_as_decimal_without_trailing_zero(4.5).is_a?(Float)).to be_truthy
      expect(helper.format_as_decimal_without_trailing_zero(BigDecimal('4.0'))).to eql 4
    end

    it "should round down to 1 decimal place if passed a number with a decimal precision greater than 1" do
      expect(helper.format_as_decimal_without_trailing_zero(254.78)).to eql 254.8
      expect(helper.format_as_decimal_without_trailing_zero(23.678)).to eql 23.7
      expect(helper.format_as_decimal_without_trailing_zero(4.2).is_a?(Float)).to be_truthy
    end
  end

  describe "#format_as_percent_with_one_decimal" do
    it "should round correctly" do
      expect(helper.format_as_percent_with_one_decimal(0.9816)).to eql '98.2%'
      expect(helper.format_as_percent_with_one_decimal(0.9815)).to eql '98.2%'
      expect(helper.format_as_percent_with_one_decimal(0.9814)).to eql '98.1%'
      expect(helper.format_as_percent_with_one_decimal(0.8915)).to eql '89.2%'
      expect(helper.format_as_percent_with_one_decimal(0.7314)).to eql '73.1%'
      expect(helper.format_as_percent_with_one_decimal(0.7315)).to eql '73.2%'
    end

    it "should not strip trailing .0 from whole numbers" do
      expect(helper.format_as_percent_with_one_decimal(0.73)).to eql '73.0%'
    end

    it "should not return the % symbol if no_percent_symbol is specified" do
      expect(helper.format_as_percent_with_one_decimal(0.73,true)).to eql '73.0'
    end
  end

  describe "#format_mark" do
    it "should return A for 0.90-1.0" do
      expect(helper.format_mark(0.9)).to eql 'A'
      expect(helper.format_mark(1.0)).to eql 'A'
    end

    it "should return A for 0.895-0.899" do
      expect(helper.format_mark(0.895)).to eql 'A'
      expect(helper.format_mark(0.899)).to eql 'A'
    end

    it "should return B for 0.80-0.894" do
      expect(helper.format_mark(0.8)).to eql 'B'
      expect(helper.format_mark(0.894)).to eql 'B'
    end

    it "should return B for 0.795-0.799" do
      expect(helper.format_mark(0.795)).to eql 'B'
      expect(helper.format_mark(0.799)).to eql 'B'
    end

    it "should return C for 0.7-0.794" do
      expect(helper.format_mark(0.7)).to eql 'C'
      expect(helper.format_mark(0.794)).to eql 'C'
    end

    it "should return C for 0.695-0.699" do
      expect(helper.format_mark(0.695)).to eql 'C'
      expect(helper.format_mark(0.699)).to eql 'C'
    end

    it "should return D for 0.60-0.694" do
      expect(helper.format_mark(0.60)).to eql 'D'
      expect(helper.format_mark(0.694)).to eql 'D'
    end

    it "should return D for 0.596-0.599" do
      expect(helper.format_mark(0.596)).to eql 'D'
      expect(helper.format_mark(0.599)).to eql 'D'
    end

    it "should return F for 0.595 and below" do
      expect(helper.format_mark(0.595)).to eql 'F'
      expect(helper.format_mark(0.50)).to eql 'F'
      expect(helper.format_mark(0.40)).to eql 'F'
      expect(helper.format_mark(0.30)).to eql 'F'
      expect(helper.format_mark(0.20)).to eql 'F'
      expect(helper.format_mark(0.10)).to eql 'F'
      expect(helper.format_mark(0.0)).to eql 'F'
    end

    it "should return blank if ratio is nil" do
      expect(helper.format_mark(nil)).to eql ''
    end
  end
end
