describe DefaultVocabWord do
  it "validates presence of language" do
    expect(DefaultVocabWord.new(:program_id => 1, :target_word => 'x', :base_word => 'y', :target_definition => 'z')).not_to be_valid
  end

  it "validates presence of program_id" do
    expect(DefaultVocabWord.new(:language => 'es', :target_word => 'x', :base_word => 'y', :target_definition => 'z')).not_to be_valid
  end

  it "validates presence of target word" do
    expect(DefaultVocabWord.new(:program_id => 1, :language => 'es', :base_word => 'y', :target_definition => 'z')).not_to be_valid
  end

  it "validates presence of base word" do
    expect(DefaultVocabWord.new(:program_id => 1, :target_word => 'x', :language => 'es', :target_definition => 'z')).not_to be_valid
  end

  # it "validates presence of target_definition" do
  #   DefaultVocabWord.new(:program_id => 1, :target_word => 'x', :base_word => 'y', :language => 'es').should_not be_valid
  # end

  it "has a vocab_tags association (pointing to its default_vocab_tags)" do
    word = create(:default_vocab_word, :vocab_tags => [])
    tag = DefaultVocabTag.new(:name => 'tag')
    word.vocab_tags << tag
    word.save
    expect(word.vocab_tags.to_a).to eql [tag]
  end
end
