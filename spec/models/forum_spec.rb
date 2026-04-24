describe Forum do
  it { is_expected.to validate_presence_of(:section_id) }
  it { is_expected.to validate_presence_of(:instructor_id) }
  it { is_expected.to validate_presence_of(:name) }

  it 'has all the right associations' do
    # Temporary test, will delete later.
    forum = create(:forum)
    expect(forum.instructor).to be_a Instructor
    expect(forum.section).to be_a Section
  end

  describe '#posts_tree' do
    let(:owner) { create(:instructor) }
    let(:forum) { create(:forum, instructor: owner) }
    let!(:first_post) do
      create(:forum_post, forum: forum, original_post: true, user: owner)
    end

    it 'returns a TreeNode instance for the original post' do
      expect(forum.posts_tree.object).to eq(first_post)
    end

    context 'when the original post has no replies' do
      it 'returns a TreeNode instance without any children' do
        expect(forum.posts_tree.children).to eq([])
      end
    end

    context 'when the original post has replies' do
      let(:student) { create(:student) }

      it 'assigns children sorted by creation date' do
        # Create children out of order to ensure sorting is by creation date
        # and not by autoincrement id.
        child_2 = create(:forum_post, forum: forum, parent_id: first_post.id,
                                      created_at: 1.days.ago, user: student)
        child_1 = create(:forum_post, forum: forum, parent_id: first_post.id,
                                      created_at: 5.days.ago, user: owner)

        expect(forum.posts_tree.children.map(&:object)).to eq([child_1, child_2])
      end

      it 'assigns children to the appropriate parents' do
        child_1 = create(:forum_post, forum: forum, user: owner,
                                      parent_id: first_post.id,
                                      created_at: 6.days.ago)
        child_2 = create(:forum_post, forum: forum, user: student,
                                      parent_id: first_post.id,
                                      created_at: 4.days.ago)
        child_3 = create(:forum_post, forum: forum, user: student,
                                      parent_id: first_post.id,
                                      created_at: 2.days.ago)

        grandchild_1_1 = create(:forum_post, forum: forum, user: owner,
                                             parent_id: child_1.id,
                                             created_at: 5.days.ago)
        grandchild_1_2 = create(:forum_post, forum: forum, user: student,
                                             parent_id: child_1.id,
                                             created_at: 4.days.ago)
        grandchild_3_1 = create(:forum_post, forum: forum, user: student,
                                             parent_id: child_3.id,
                                             created_at: 2.days.ago)
        grandchild_3_2 = create(:forum_post, forum: forum, user: owner,
                                             parent_id: child_3.id,
                                             created_at: 1.days.ago)
        great_grandchild_1_2_1 = create(:forum_post, forum: forum, user: student,
                                                     parent_id: grandchild_1_2.id,
                                                     created_at: 5.days.ago)
        great_grandchild_1_1_1 = create(:forum_post, forum: forum, user: owner,
                                                     parent_id: grandchild_1_1.id,
                                                     created_at: 1.days.ago)

        children = forum.posts_tree.children
        expect(children.map(&:object)).to eq([child_1, child_2, child_3])
        expect(children[0].children.map(&:object)).to eq([grandchild_1_1, grandchild_1_2])
        expect(children[1].children).to eq([])
        expect(children[2].children.map(&:object)).to eq([grandchild_3_1, grandchild_3_2])
        expect(children[0].children[0].children.map(&:object)).to eq([great_grandchild_1_1_1])
        expect(children[0].children[1].children.map(&:object)).to eq([great_grandchild_1_2_1])
      end
    end
  end
end
