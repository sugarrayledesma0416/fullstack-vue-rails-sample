describe DefaultVocabWord do
  it "validates presence of name" do
    expect(DefaultVocabTag.new).not_to be_valid
  end
end

