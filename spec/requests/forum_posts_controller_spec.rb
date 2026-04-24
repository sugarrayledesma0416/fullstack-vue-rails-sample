require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'
require 'requests/shared_supersite_junior_blocking_examples'

describe ForumPostsController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:forum) { create(:forum, instructor: instructor, section: section) }
  let!(:parent_post) { create(:forum_post, forum: forum, user: instructor) }

  describe 'POST /create' do
    let(:post_text) { 'reply post text' }

    let(:valid_params) do
      {
        forum_post: { parent_id: parent_post.id, text: post_text }
      }
    end

    def do_request(extra_params = {})
      post(
        forum_forum_posts_path(
          forum_id: forum.id,
          program_id: program.id,
          section_id: section.id
        ),
        params: valid_params.merge(extra_params)
      )
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a logged in user with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'creates a new forum post and displays the forum show view' do
        expect { do_request }.to change(ForumPost, :count).by(1)

        expect(response).to redirect_to(
          forum_path(
            id: forum.id,
            program_id: program.id,
            section_id: section.id,
            anchor: "post_id_#{parent_post.id}"
          )
        )

        expect(flash[:notice]).to eq('Your reply was posted.')

        new_post = ForumPost.last
        expect(new_post).to have_attributes(
          forum_id: forum.id,
          parent_id: parent_post.id,
          text: post_text,
          user_id: instructor.id
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:forum_post) do
      create(
        :forum_post,
        parent_id: parent_post.id,
        text: 'old text',
        user: instructor
      )
    end

    def do_request(extra_params = {})
      put(
        forum_forum_post_path(
          forum_id: forum.id,
          id: forum_post.id,
          program_id: program.id,
          section_id: section.id
        ),
        params: { forum_post: { text: 'new text' } }.merge(extra_params)
      )
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a logged in user with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'updates the forum with the specified id when valid params ' \
          'are specified' do
        do_request

        expect(response).to redirect_to(
          forum_path(
            id: forum.id,
            program_id: program.id,
            section_id: section.id,
            anchor: "post_id_#{forum_post.id}"
          )
        )

        expect(flash[:notice]).to eq('Your edit was saved.')

        reloaded_post = ForumPost.find(forum_post.id)
        expect(reloaded_post.text).to eq('new text')
      end
    end
  end

  describe 'DELETE /destroy' do
    let(:forum_post) do
      create(
        :forum_post,
        parent_id: parent_post.id,
        text: 'old text',
        user: instructor
      )
    end

    def do_request
      delete(
        forum_forum_post_path(
          forum_id: forum.id,
          id: forum_post.id,
          program_id: program.id,
          section_id: section.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a logged in user with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'deletes the forum with the specified id' do
        do_request

        expect(response).to redirect_to(
          forum_path(
            id: forum.id,
            program_id: program.id,
            section_id: section.id,
            anchor: "post_id_#{forum_post.id}"
          )
        )

        reloaded_post = ForumPost.find(forum_post.id)
        expect(reloaded_post).to have_attributes(
          deleted: true, text: 'Deleted post'
        )
      end
    end
  end
end
