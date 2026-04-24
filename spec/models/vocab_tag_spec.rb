describe VocabTag do
  it "validates presence of name" do
    expect(VocabTag.new).not_to be_valid
  end

  it "validates uniqueness of name scoped to vocab_word_id" do
    tag = create(:vocab_tag, :name => 'test name')
    expect { create(:vocab_tag, :name => 'test name', :vocab_word => tag.vocab_word) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been used')
    expect { create(:vocab_tag, :name => 'test name') }.to_not raise_error
  end
end
