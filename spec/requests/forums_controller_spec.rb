require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'
require 'requests/shared_require_instructor_examples'
require 'requests/shared_supersite_junior_blocking_examples'

describe ForumsController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }

  describe 'GET /index' do
    let!(:forum) { create(:forum, section: section) }

    def do_request
      get forums_path(program_id: program.id, section_id: section.id)
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a logged in user with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'renders an index view with a list of forums' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:index)

        expect(assigns(:forums)).to eq(
          section.id => [forum]
        )
      end
    end
  end

  describe 'GET /new' do
    def do_request
      get new_forum_path(program_id: program.id, section_id: section.id)
    end

    include_examples 'require instructor or grader with program access'

    context 'with a logged in instructor with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Course,#{course.id}", return_to: '' }
        )
      end

      include_examples 'prevents access for supersite junior programs'

      it 'assigns an unsaved Form instance and renders the new view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:new)

        new_forum = assigns(:forum)
        expect(new_forum).to be_a(Forum)
        expect(new_forum).not_to be_persisted
        expect(new_forum.instructor_id).to eq(instructor.id)
        expect(new_forum.section_id).to eq(section.id)
      end
    end
  end

  describe 'POST /create' do
    let(:name) { 'first forum' }
    let(:post_text) { 'first post text' }

    let(:valid_params) do
      {
        forum: {
          name: name,
          section_id: section.id,
          first_post_attributes: {
            text: post_text
          }
        }
      }
    end

    def do_request(extra_params = {})
      post(
        forums_path(program_id: program.id, section_id: section.id),
        params: valid_params.merge(extra_params)
      )
    end

    include_examples 'require instructor or grader with program access'

    context 'with a logged in instructor with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'creates a new forum and redirects to the forums index ' \
         'with valid params' do
        expect { do_request }.to change(Forum, :count).by(1)

        expect(response).to redirect_to(forums_path(program_id: program.id))

        expect(flash[:notice]).to eq('Forum was successfully created!')

        new_forum = Forum.last
        expect(new_forum).to have_attributes(
          instructor_id: instructor.id,
          name: name,
          section_id: section.id
        )

        first_post = new_forum.forum_posts.first
        expect(first_post).to have_attributes(
          text: post_text,
          user_id: instructor.id
        )
      end
    end
  end

  describe 'GET /show' do
    let(:forum) { create(:forum, section: section) }

    def do_request
      get forum_path(id: forum.id, program_id: program.id, section_id: section.id)
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a logged in user with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
        create(:forum_post, forum: forum)
      end

      include_examples 'prevents access for supersite junior programs'

      it 'finds and assigns the forum with the specified id and renders ' \
         'the show view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        expect(assigns(:forum)).to eq(forum)
        expect(assigns(:presenter)).to be_a(ShowForumPresenter)
      end
    end
  end

  describe 'GET /edit' do
    let(:forum) { create(:forum, section: section) }

    def do_request
      get edit_forum_path(id: forum.id, program_id: program.id, section_id: section.id)
    end

    include_examples 'require instructor or grader with program access'

    context 'with a logged in instructor with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'finds and assigns the forum with the specified id and renders ' \
         'the edit view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:edit)

        expect(assigns(:forum)).to eq(forum)
      end
    end
  end

  describe 'PUT /update' do
    let(:forum) { create(:forum, name: 'old name', section: section) }

    def do_request(extra_params = {})
      put(
        forum_path(id: forum.id, program_id: program.id, section_id: section.id),
        params: { forum: { name: 'new name' } }.merge(extra_params)
      )
    end

    include_examples 'require instructor or grader with program access'

    context 'with a logged in instructor with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'updates the forum with the specified id when valid params ' \
          'are specified' do
        do_request

        reloaded_forum = Forum.find(forum.id)

        expect(reloaded_forum.name).to eq('new name')
      end
    end
  end

  describe 'DELETE /destroy' do
    let(:forum) { create(:forum, section: section) }

    def do_request
      delete forum_path(id: forum.id, program_id: program.id, section_id: section.id)
    end

    include_examples 'require instructor or grader with program access'

    context 'with a logged in instructor with program access,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'prevents access for supersite junior programs'

      it 'deletes the forum with the specified id' do
        do_request

        expect(response).to redirect_to(forums_path(program_id: program.id, section_id: section.id))

        expect(flash[:notice]).to eq("Forum '#{forum.name}' has been deleted.")

        expect(Forum).not_to exist(forum.id)
      end
    end
  end
end
