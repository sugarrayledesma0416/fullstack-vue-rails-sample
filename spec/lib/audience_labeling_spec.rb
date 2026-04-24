describe AudienceLabeling do
  let(:test_klass) do
    Class.new do
      include AudienceLabeling
    end
  end

  context 'when an existing audience is specified,' do
    it 'returns the value of the specified word key for the specified ' \
       'audience if it exists' do
      expect(
        test_klass.new.audience_label(:elementary, :instructor)
      ).to eq('teacher')
    end

    it 'returns the value of the specified word key for the default audience ' \
       'if no entry exists for that key for the specified audience' do
      expect(
        test_klass.new.audience_label(:elementary, :student)
      ).to eq('student')
    end

    it 'returns nil if there is no value for the specified word key for ' \
       'either the specified audience of the default audience' do
      expect(
        test_klass.new.audience_label(:elementary, :fakekey)
      ).to be_nil
    end
  end

  context 'when a non-existing audience is specified,' do
    it 'returns the value of the specified word key for the default audience ' \
       'if an entry exists for that key for the default audience' do
      expect(
        test_klass.new.audience_label(:badaudience, :instructor)
      ).to eq('instructor')
    end

    it 'returns nil if there is no value for the specified word key for ' \
       'the default audience' do
      expect(
        test_klass.new.audience_label(:badaudience, :fakekey)
      ).to be_nil
    end
  end

  context 'when a nil audience is specified,' do
    # Could happen if the method is called like:
    # audience_label(section&.program&.audience, word)
    it 'returns the value of the specified word key for the default audience ' \
       'if an entry exists for that key for the default audience' do
      expect(
        test_klass.new.audience_label(nil, :instructor)
      ).to eq('instructor')
    end

    it 'returns nil if there is no value for the specified word key for ' \
       'the default audience' do
      expect(
        test_klass.new.audience_label(nil, :fakekey)
      ).to be_nil
    end
  end
end
