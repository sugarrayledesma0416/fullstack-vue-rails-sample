describe ForumPost do
  it do
    is_expected.to belong_to(:user)
  end

  it 'is valid if text is present and audio file is blank' do
    expect(build(:forum_post, text: 'abc', audio_path: nil)).to be_valid
    expect(build(:forum_post, text: 'abc', audio_path: '')).to be_valid
  end

  it 'is valid if text is blank and audio file is present' do
    expect(build(:forum_post, text: '', audio_path: 'a')).to be_valid
    expect(build(:forum_post, text: nil, audio_path: 'a')).to be_valid
  end

  it 'is valid if both text and audio file are present' do
    expect(build(:forum_post, text: 'a', audio_path: 'b')).to be_valid
  end

  it 'is invalid if both text and audio file are blank' do
    expect(build(:forum_post, text: '', audio_path: '')).not_to be_valid
    expect(build(:forum_post, text: '', audio_path: nil)).not_to be_valid
    expect(build(:forum_post, text: nil, audio_path: '')).not_to be_valid
    forum_post = build(:forum_post, text: nil, audio_path: nil)
    expect(forum_post).not_to be_valid
    expect(forum_post.errors[:text]).to include('or an audio recording is required')
    expect(forum_post.errors[:audio_path]).to include('or text is required')
  end

  it 'has all the right associations' do
    # Temporary test, will delete later.
    forum_post = create(:forum_post)
    expect(forum_post.user).to be_a User
    expect(forum_post.forum).to be_a Forum
  end

  describe '#audio_uri' do
    let(:cdn_prefix) { 'https://s3-bucket-path/' }

    context 'when there is an audio_path present' do
      it 'returns the audio comment S3 path if it exists.' do
        allow(M3::Application.config.multimedia.forums).to receive(:cdn_prefix).and_return(cdn_prefix)
        forum_post = create(:forum_post, audio_path: 'hashed-file')
        expect(forum_post.audio_uri)
          .to eq(forum_post.cdn_prefix + forum_post.audio_path)
      end
    end

    context 'when there is not an audio_path present' do
      it 'returns nothing' do
        forum_post = create(:forum_post, audio_path: nil)
        expect(forum_post.audio_uri).to be_falsey
      end
    end
  end

  describe '#edited?' do
    it 'is false when edited_at is nil' do
      forum_post = build(:forum_post, edited_at: nil)
      expect(forum_post).not_to be_edited
    end

    it 'is true when edited_at is not nil' do
      forum_post = build(:forum_post, edited_at: 1.day.ago)
      expect(forum_post).to be_edited
    end
  end

  describe '#delete!' do
    it 'sets deleted to true' do
      forum_post = create(:forum_post, deleted: false)
      forum_post.delete!
      expect(forum_post.deleted).to be_truthy
    end

    it 'sets post text to "Deleted post"' do
      forum_post = create(:forum_post, deleted: false, text: 'Primus sucks')
      forum_post.delete!
      expect(forum_post.text).to eq('Deleted post')
    end
  end
end
