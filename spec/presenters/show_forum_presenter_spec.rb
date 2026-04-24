describe ShowForumPresenter do
  let(:user) { create(:instructor) }
  let(:forum) { create(:forum, instructor: user) }

  describe '#reply_for' do
    context 'when initialized with a reply post' do
      let(:original) { create(:forum_post, forum: forum, user: user) }
      let(:reply) do
        create(:forum_post, forum: forum, user: user, parent_id: original.id)
      end

      let(:presenter) { described_class.new(forum, reply: reply) }

      context 'when called with the parent of the reply post' do
        it 'returns the reply post' do
          expect(presenter.reply_for(original)).to eq(reply)
        end
      end

      context 'when called with a post that is not the parent of the reply post' do
        it 'returns a new forum post with the parent_id of the specified post' do
          other_post = create(:forum_post, forum: forum, user: user)

          result = presenter.reply_for(other_post)

          expect(result).to be_a ForumPost
          expect(result).not_to be_persisted
          expect(result).to have_attributes(forum: forum, parent_id: other_post.id)
        end
      end
    end

    context 'when initialized without a reply post' do
      it 'returns a new forum post with the parent_id of the specified post' do
        post = create(:forum_post, forum: forum, user: user)

        presenter = described_class.new(forum)
        result = presenter.reply_for(post)

        expect(result).to be_a ForumPost
        expect(result).not_to be_persisted
        expect(result).to have_attributes(forum: forum, parent_id: post.id)
      end
    end
  end

  describe '#has_unsaved_reply?' do
    context 'when initialized with a reply post' do
      let(:original) { create(:forum_post, forum: forum, user: user) }
      let(:reply) do
        create(:forum_post, forum: forum, user: user, parent_id: original.id)
      end

      let(:presenter) { described_class.new(forum, reply: reply) }

      it 'is true when called with the parent of the reply post' do
        expect(presenter.has_unsaved_reply?(original)).to be true
      end

      it 'is false when called with a post that is not the parent of the reply post' do
        other_post = create(:forum_post, forum: forum, user: user)

        expect(presenter.has_unsaved_reply?(other_post)).to be false
      end
    end

    it 'is false when initialized without a reply post' do
      post = create(:forum_post, forum: forum, user: user)

      presenter = described_class.new(forum)

      expect(presenter.has_unsaved_reply?(post)).to be false
    end
  end

  describe '#edit_for' do
    context 'when initialized with an edit post' do
      let(:post) { create(:forum_post, forum: forum, user: user) }

      let(:presenter) do
        post.text = 'Unsaved changes'
        described_class.new(forum, edit: post)
      end

      context 'when called with the saved version of the edit post' do
        it 'returns the unsaved edit post' do
          result = presenter.edit_for(post)

          expect(result).to eq(post)
          expect(result).to be_changed
          expect(result.text).to eq('Unsaved changes')
        end
      end

      context 'when called with a post with a different id than the edit post' do
        it 'returns the saved version of the specified post' do
          other_post = create(:forum_post, forum: forum, user: user)

          result = presenter.edit_for(other_post)
          expect(result).to eq(other_post)
          expect(result).not_to be_changed
        end
      end
    end

    context 'when initialized without a edit post' do
      it 'returns the saved version of the specifeid post' do
        post = create(:forum_post, forum: forum, user: user)
        presenter = described_class.new(forum)

        result = presenter.edit_for(post)

        expect(result).to eq(post)
        expect(result).not_to be_changed
      end
    end
  end

  describe '#has_unsaved_edits?' do
    context 'when initialized with an edit post' do
      let(:post) { create(:forum_post, forum: forum, user: user) }

      let(:presenter) do
        post.text = 'Unsaved changes'
        described_class.new(forum, edit: post)
      end

      it 'is true when called with the saved version of the edit post' do
        expect(presenter.has_unsaved_edits?(post)).to be true
      end

      it 'is false when called with a post with a different id than the edit post' do
        other_post = create(:forum_post, forum: forum, user: user)

        expect(presenter.has_unsaved_edits?(other_post)).to be false
      end
    end

    it 'is false when initialized without a edit post' do
      post = create(:forum_post, forum: forum, user: user)
      presenter = described_class.new(forum)

      expect(presenter.has_unsaved_edits?(post)).to be false
    end
  end
end
