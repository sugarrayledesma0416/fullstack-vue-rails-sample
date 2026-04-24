# The controller is the interface for the integration test, but
# we're not writing controller specs.
describe ForumPostsController, type: :controller do
  include RspecJsApiHelpers
  render_views # helps catch problems where we assign the wrong stuff

  def log_in_and_grant_program_access(user, program)
    fake_login(user)
    initialize_program_access_client_calls_for_user_and_program(user, program)
  end

  def focus_on(course, section = nil)
    session[:focus] = {
      course.program_id => {
        course_id: course.id,
        section_id: section && section.id,
        sort: nil
      }
    }
  end

  let(:program) { create(:program) }
  let(:owner) { create(:instructor) }
  let(:course) { create(:course, program: program, owner: owner) }
  let(:section) { create(:section, instructor: owner) }
  let(:forum) { create(:forum, instructor: owner, section: section) }

  shared_examples 'reply posts by permitted user' do
    context 'with valid attributes' do
      it 'saves a new forum post record' do
        expect { post :create, params: post_params }.to change(ForumPost, :count).by(1)

        reply = ForumPost.last

        expect(reply).to have_attributes(user_id: user.id,
                                         parent_id: first_post.id,
                                         forum_id: forum.id,
                                         text: reply_text,
                                         original_post: false)
      end

      it 'redirects to the forum show page with an anchor to the parent id' do
        post :create, params: post_params

        expected_path = forum_path(program.id, section, forum.id, anchor: "post_id_#{first_post.id}")
        expect(response).to redirect_to(expected_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_post_params) do
        {
          program_id: program.id,
          section_id: section.id,
          forum_id: forum.id,
          forum_post: { text: '', parent_id: first_post.id }
        }
      end

      it 'does not save the forum post' do
        expect { post :create, params: invalid_post_params }.not_to change(ForumPost, :count)
      end

      it 're-renders the forum show page and assigns the forum' do
        post :create, params: invalid_post_params

        expect(assigns(:forum)).to eq(forum)
        expect(response).to render_template('forums/show')
      end

      it 'puts the failed reply with error messages into the presenter' do
        post :create, params: invalid_post_params

        reply = assigns(:presenter).reply_for(first_post)

        expect(reply).to be_a(ForumPost)
        expect(reply.errors[:text]).to eq(['or an audio recording is required'])
      end
    end
  end

  describe 'the action for updating an existing forum post' do
    let(:original_text) { 'I am the original post body' }
    let(:updated_text) { 'I am the new post body' }

    let!(:original_post) do
      create(:forum_post, forum: forum, user: owner, text: original_text)
    end

    let(:params_for_update) do
      {
        program_id: program.id,
        forum_id: forum.id,
        id: original_post.id,
        section_id: section.id,
        forum_post: { text: updated_text }
      }
    end

    context 'for the author of the original post' do
      before do
        log_in_and_grant_program_access(owner, program)
        focus_on(course)
      end

      context 'with valid attributes' do
        it 'saves the changes to the original post' do
          put :update, params: params_for_update

          original_post.reload
          expect(original_post.text).to eq(updated_text)
          expect(original_post).to be_edited
        end

        it 'redirects to the forum show page with an anchor to the original post id' do
          put :update, params: params_for_update

          expected_path = forum_path(
            program.id, section, forum.id, anchor: "post_id_#{original_post.id}"
          )
          expect(response).to redirect_to(expected_path)
        end
      end

      context 'with invalid attributes' do
        let(:invalid_params_for_update) do
          params_for_update.merge(forum_post: { text: '' })
        end

        it 'does not save the forum post' do
          put :update, params: invalid_params_for_update

          original_post.reload
          expect(original_post.text).to eq(original_text)
          expect(original_post).not_to be_edited
        end

        it 're-renders the forum show page and assigns the forum' do
          put :update, params: invalid_params_for_update

          expect(assigns(:forum)).to eq(forum)
          expect(response).to render_template('forums/show')
        end

        it 'puts the failed edit with error messages into the presenter' do
          put :update, params: invalid_params_for_update

          edit = assigns(:presenter).edit_for(original_post)

          expect(edit).to eq(original_post)
          expect(edit).to be_changed
          expect(edit.errors[:text]).to eq(['or an audio recording is required'])
        end
      end
    end

    context 'for a user who is not the author of the original post' do
      it 'redirects without changing the original post' do
        user = create(:student)
        log_in_and_grant_program_access(user, program)
        create(:active_enrollment, user: user, section: section)

        put :update, params: params_for_update

        original_post.reload
        expect(original_post.text).to eq(original_text)
        expect(original_post).not_to be_edited
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'the action for posting a reply to a forum post' do
    let(:reply_text) { 'I am the text of the reply post.' }
    let(:post_params) do
      {
        program_id: program.id,
        section_id: section.id,
        forum_id: forum.id,
        forum_post: { text: reply_text, parent_id: first_post.id }
      }
    end

    let!(:first_post) do
      create(:forum_post, forum: forum, original_post: true, user: owner)
    end

    context 'for a student enrolled in the section' do
      let(:user) { create(:student) }

      before do
        log_in_and_grant_program_access(user, program)
        create(:active_enrollment, user: user, section: section)
      end

      include_examples 'reply posts by permitted user'
    end

    context 'for a course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
        focus_on(course)
      end
      let(:user) { owner }

      include_examples 'reply posts by permitted user'
    end

    context "for a student not enrolled in the forum's section" do
      let(:user) { create(:student) }

      before do
        log_in_and_grant_program_access(user, program)
        create(:dropped_enrollment, user: user, section: section)
      end

      it 'redirects without creating a forum post record' do
        expect { post :create, params: post_params }.not_to change(ForumPost, :count)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "for an instructor not affiliated with the forum's section" do
      let(:user) { create(:instructor) }

      before do
        log_in_and_grant_program_access(user, program)
      end

      it 'redirects without creating a forum post record' do
        expect { post :create, params: post_params }.not_to change(ForumPost, :count)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
