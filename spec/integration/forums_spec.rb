# The controller is the interface for the integration test, but
# we're not writing controller specs.
describe ForumsController, type: :controller do
  include RspecJsApiHelpers
  render_views # helps catch problems where we assign the wrong stuff

  def log_in_and_grant_program_access(user, program)
    fake_login(user)
    initialize_program_access_client_calls_for_user_and_program(user, program)
  end

  def focus_on(course, section = nil)
    session[:focus] = {
      course.program_id.to_s => {
        'course_id' => course.id,
        'section_id' => section && section.id,
        'sort' => nil
      }
    }
  end

  let(:program) { create(:program) }
  let(:school) { create(:school) }
  let(:owner) { create(:instructor, schools: [school]) }
  let(:course) { create(:course, program: program, owner: owner, school: school) }
  let(:section) { create(:section, course:, instructor: owner) }

  describe 'the forum list page' do

    context 'for a student' do
      let(:student) { create(:student) }

      before do
        log_in_and_grant_program_access(student, program)
      end

      it "doesn't throw errors when there are no forums" do
        create(:active_enrollment, section: section, user: student)

        expect do
          get :index, params: { program_id: program.id, section_id: section.id }
        end.not_to raise_error
      end

      it 'shows a list of forums for their currently enrolled section' do
        enrolled_section = create(:section, course: course, instructor: owner)
        unenrolled_section = create(:section, course: course, instructor: owner)

        create(:active_enrollment, section: enrolled_section, user: student)
        create(:dropped_enrollment, section: unenrolled_section, user: student)

        enrolled_section_forum = create(:forum, section: enrolled_section,
                                                instructor: owner)
        # Unenrolled section forum:
        create(:forum, section: unenrolled_section, instructor: owner)

        get :index, params: { program_id: program.id, section_id: enrolled_section.id }

        expect(response).to render_template :index
        expect(assigns[:forum_sections]).to eq([enrolled_section])
        expect(assigns[:forums]).to eq(
          enrolled_section.id => [enrolled_section_forum]
        )
      end
    end

    context 'for any instructor' do
      it "doesn't throw errors when there is no course in focus" do
        log_in_and_grant_program_access(owner, program)

        expect do
          get :index, params: { program_id: program.id, section_id: 0 }
        end.not_to raise_error
        expect(assigns[:forum_sections]).to be nil
        expect(assigns[:forums]).to be_nil
      end
    end

    context 'for a course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
      end

      it "doesn't throw errors when there are no forums" do
        create(:section, course: course, instructor: owner)
        focus_on(course)

        expect do
          get :index, params: { program_id: program.id, section_id: course.sections.first.id }
        end.not_to raise_error
      end

      it 'shows forums in all sections of the currently focused course' do
        non_focused_course = create(:course, program: program, owner: owner)
        section_in_non_focused_course = create(:section,
                                               course: non_focused_course,
                                               instructor: owner)
        create(:forum, section: section_in_non_focused_course, instructor: owner)

        focused_section_1 = create(:section, course: course, instructor: owner)
        focused_section_2 = create(:section, course: course, instructor: owner)

        section_1_forum = create(:forum, section: focused_section_1, instructor: owner)
        section_2_forum = create(:forum, section: focused_section_2, instructor: owner)

        focus_on(course)

        get :index, params: { program_id: program.id, section_id: focused_section_1.id }

        expect(response).to render_template :index
        expect(assigns[:forum_sections]).to match_array(
          [focused_section_1, focused_section_2]
        )
        expect(assigns[:forums]).to eq(
          focused_section_1.id => [section_1_forum],
          focused_section_2.id => [section_2_forum]
        )
      end
    end
  end

  describe 'the new forum form' do
    it 'does not allow access to students' do
      student = create(:student)
      log_in_and_grant_program_access(student, program)

      get :new, params: { program_id: program.id, section_id: section.id }

      expect(response).to have_http_status(:redirect)
    end

    context 'for any instructor' do
      it "doesn't throw errors when there is no course in focus" do
        log_in_and_grant_program_access(owner, program)

        expect do
          get :new, params: { program_id: program.id, section_id: 0 }
        end.not_to raise_error
        expect(assigns[:available_sections]).to be nil
        expect(assigns[:forum]).to be_nil
      end
    end

    context 'for a co-instructor' do
      it 'assigns only sections the co-instructor is supposed to see' do
        co_instructor = create(:instructor)
        log_in_and_grant_program_access(co_instructor, program)

        section_1 = create(:section, course: course, instructor: owner)
        create(:section_instructor, role: 'Co-instructor', section: section_1,
                                    instructor: co_instructor)

        section_2 = create(:section, course: course, instructor: owner)
        create(:section_instructor, role: 'Assistant', section: section_2,
                                    instructor: co_instructor)

        create(:section, course: course, instructor: owner)
        # co-instructor has no role for this section

        focus_on(course)
        get :new, params: { program_id: program.id, section_id: section_1.id }

        expect(assigns[:available_sections]).to match_array([section_1, section_2])
      end
    end

    context 'with the course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
        create(:section, course: course, instructor: owner)
      end

      it 'allows access to the view' do
        focus_on(course)
        get :new, params: { program_id: program.id }

        expect(response).to render_template(:new)
      end

      it 'assigns an empty forum instance and first post' do
        focus_on(course)
        get :new, params: { program_id: program.id }

        new_forum = assigns[:forum]
        expect(new_forum).to be_a(Forum)
        expect(new_forum).not_to be_persisted
        expect(new_forum.first_post).to be_a(ForumPost)
        expect(new_forum.first_post).not_to be_persisted
      end

      it 'assigns a list of the sections in the course' do
        section_1 = course.sections.first
        section_2 = create(:section, course: course, instructor: owner)

        focus_on(course)
        get :new, params: { program_id: program.id }

        expect(assigns[:available_sections]).to match_array([section_1, section_2])
      end
    end
  end

  describe 'posting to create forum' do
    before do
      log_in_and_grant_program_access(owner, program)
      focus_on(course)
    end

    let(:section) { create(:section, course: course, instructor: owner) }

    context 'with valid attributes' do
      it 'saves a new forum record and first post' do
        name = 'Yay, I am a forum'
        first_post_text = 'I am the text of the first post.'

        post_params = {
          program_id: program.id,
          section_id: section.id,
          forum: {
            section_id: section.id,
            name: name,
            first_post_attributes: { text: first_post_text }
          }
        }

        expect { post :create, params: post_params }.to change(Forum, :count).by(1)

        forum = Forum.last

        expect(forum).to have_attributes(instructor_id: owner.id,
                                         section_id: section.id,
                                         name: name)
        first_post = forum.first_post
        expect(first_post).to be_present
        expect(first_post).to have_attributes(user_id: owner.id,
                                              text: first_post_text,
                                              original_post: true)
        expect(response).to redirect_to(forums_path(program, section))
      end
    end

    context 'with invalid forum attributes' do
      it 're-renders the new action with the forum with errors' do
        post_params = {
          forum: { section_id: section.id },
          program_id: program.id,
          section_id: section.id
        }

        expect { post :create, params: post_params }.not_to change(Forum, :count)

        expect(response).to render_template(:new)
        forum = assigns[:forum]
        expect(forum.errors).not_to be_empty
        expect(forum.errors[:name]).to eq(['is required'])
      end

      it 'assigns a list of the sections in the course' do
        section_2 = create(:section, course: course, instructor: owner)
        post_params = {
          forum: { section_id: section.id },
          program_id: program.id,
          section_id: section.id
        }

        post :create, params: post_params

        expect(assigns[:available_sections]).to match_array([section, section_2])
      end
    end

    context 'with valid forum attributes but invalid first post attributes' do
      it 're-renders the new action with the forum with errors' do
        post_params = {
          forum: {
            first_post_attributes: { text: '' },
            name: 'a',
            section_id: section.id
          },
          program_id: program.id,
          section_id: section.id
        }

        # Does not persist parent if child fails validation.
        expect { post :create, params: post_params }.not_to change(Forum, :count)

        expect(response).to render_template(:new)

        forum = assigns[:forum]
        expect(forum.errors).not_to be_empty
        expect(forum.errors[:'first_post.text']).to eq(['or an audio recording is required'])
        expect(forum.first_post).to be_present
        expect(forum.first_post.errors[:text]).to eq(['or an audio recording is required'])
      end
    end
  end

  describe 'the show forum page' do
    let(:section) { create(:section, course: course, instructor: owner) }
    let(:forum) { create(:forum, section: section, instructor: owner) }
    let(:student) { create(:student) }
    let!(:first_post) do
      create(:forum_post, forum: forum, original_post: true, user: owner)
    end

    it 'does not allow access to students not enrolled in the forum section' do
      student = create(:student)
      log_in_and_grant_program_access(student, program)
      create(:dropped_enrollment, user: student, section: section)

      get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to have_http_status(:redirect)
    end

    it 'does not allow access to non-instructor-team instructors' do
      other_instructor = create(:instructor)
      log_in_and_grant_program_access(other_instructor, program)
      focus_on(course)

      get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to have_http_status(:redirect)
    end

    it 'allows access to co-instructors' do
      co_instructor = create(:instructor)
      create(:section_instructor, role: 'Co-instructor', section: section,
                                  instructor: co_instructor)
      log_in_and_grant_program_access(co_instructor, program)
      focus_on(course)

      get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to render_template(:show)
    end

    it 'allows access to assistants' do
      assistant = create(:instructor)
      create(:section_instructor, role: 'Assistant', section: section,
                                  instructor: assistant)
      log_in_and_grant_program_access(assistant, program)
      focus_on(course)

      get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to render_template(:show)
    end

    context 'for an enrolled student' do
      before do
        log_in_and_grant_program_access(student, program)
        create(:active_enrollment, user: student, section: section)
      end

      it 'assigns the forum specified by the forum id' do
        get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

        expect(assigns(:forum)).to eq(forum)
      end

      it 'creates a tree of posts' do
        child_1 = create(:forum_post, forum: forum, parent_id: first_post.id, user: owner)
        child_2 = create(:forum_post, forum: forum, parent_id: first_post.id, user: student)

        get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

        root_node = assigns(:forum).posts_tree
        expect(root_node.object).to eq(first_post)
        expect(root_node.children.map(&:object)).to eq([child_1, child_2])
      end
    end

    context 'for a course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
        focus_on(course)
      end

      it 'assigns the forum specified by the forum id' do
        get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

        expect(assigns(:forum)).to eq(forum)
      end

      it 'creates a tree of posts' do
        child_1 = create(:forum_post, forum: forum, parent_id: first_post.id, user: owner)
        child_2 = create(:forum_post, forum: forum, parent_id: first_post.id, user: student)

        get :show, params: { program_id: program.id, id: forum.id, section_id: section.id }

        root_node = assigns(:forum).posts_tree
        expect(root_node.object).to eq(first_post)
        expect(root_node.children.map(&:object)).to eq([child_1, child_2])
      end
    end
  end

  describe 'the edit forum form' do
    let(:section) { create(:section, course: course, instructor: owner) }
    let(:forum) { create(:forum, section: section, instructor: owner) }

    it 'does not allow access to students' do
      student = create(:student)
      log_in_and_grant_program_access(student, program)

      get :edit, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to have_http_status(:redirect)
    end

    it 'does not allow access to non-instructor-team instructors' do
      other_instructor = create(:instructor)
      log_in_and_grant_program_access(other_instructor, program)
      focus_on(course)

      get :edit, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to have_http_status(:redirect)
    end

    it 'allows access to co-instructors' do
      co_instructor = create(:instructor)
      create(:section_instructor, role: 'Co-instructor', section: section,
                                  instructor: co_instructor)
      log_in_and_grant_program_access(co_instructor, program)
      focus_on(course)

      get :edit, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to render_template(:edit)
    end

    it 'allows access to assistants' do
      assistant = create(:instructor)
      create(:section_instructor, role: 'Assistant', section: section,
                                  instructor: assistant)
      log_in_and_grant_program_access(assistant, program)
      focus_on(course)

      get :edit, params: { program_id: program.id, id: forum.id, section_id: section.id }

      expect(response).to render_template(:edit)
    end

    context 'with the course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
        focus_on(course)
        get :edit, params: { program_id: program.id, id: forum.id, section_id: section.id }
      end

      it 'allows access to the view' do
        expect(response).to render_template(:edit)
      end

      it 'assigns the forum to be edited' do
        expect(assigns[:forum]).to eq(forum)
      end
    end
  end

  describe 'posting to update forum' do
    let(:section) { create(:section, course: course, instructor: owner) }
    let(:forum) { create(:forum, section: section, instructor: owner) }
    let(:new_name) { 'I am the new forum name' }
    let(:valid_params) do
      {
        forum: { name: new_name },
        id: forum.id,
        program_id: program.id,
        section_id: section.id
      }
    end

    it 'does not allow access to students' do
      student = create(:student)
      log_in_and_grant_program_access(student, program)

      put :update, params: valid_params

      expect(response).to have_http_status(:redirect)
      expect(forum.reload.name).not_to eq(new_name)
    end

    it 'does not allow access to non-instructor-team instructors' do
      other_instructor = create(:instructor)
      log_in_and_grant_program_access(other_instructor, program)
      focus_on(course)

      put :update, params: valid_params

      expect(response).to have_http_status(:redirect)
      expect(forum.reload.name).not_to eq(new_name)
    end

    it 'allows co-instructors to make changes' do
      co_instructor = create(:instructor)
      create(:section_instructor, role: 'Co-instructor', section: section,
                                  instructor: co_instructor)
      log_in_and_grant_program_access(co_instructor, program)
      focus_on(course)

      put :update, params: valid_params

      expect(response).to redirect_to(forums_path(program, section))
      expect(forum.reload.name).to eq(new_name)
    end

    it 'allows assistants to make changes' do
      assistant = create(:instructor)
      create(:section_instructor, role: 'Assistant', section: section,
                                  instructor: assistant)
      log_in_and_grant_program_access(assistant, program)
      focus_on(course)

      put :update, params: valid_params

      expect(response).to redirect_to(forums_path(program, section))
      expect(forum.reload.name).to eq(new_name)
    end

    context 'for the course owner' do
      before do
        log_in_and_grant_program_access(owner, program)
        focus_on(course)
      end

      context 'with valid attributes' do
        it 'saves changes to the forum' do
          put :update, params: valid_params

          expect(response).to redirect_to(forums_path(program, section))
          expect(forum.reload.name).to eq(new_name)
        end
      end

      context 'with invalid forum attributes' do
        it 're-renders the edit view with the forum with errors' do
          put :update, params: {
            id: forum.id,
            forum: { name: '' },
            program_id: program.id
          }

          expect(response).to render_template(:edit)
          forum = assigns[:forum]
          expect(forum.errors).not_to be_empty
          expect(forum.errors[:name]).to eq(['is required'])
        end
      end
    end
  end

  describe 'deleting a forum' do
    let(:section) { create(:section, course: course, instructor: owner) }
    let(:forum) { create(:forum, section: section, instructor: owner) }
    let(:valid_params) { { program_id: program.id, id: forum.id } }

    it 'does not allow access to students' do
      student = create(:student)
      log_in_and_grant_program_access(student, program)

      delete :destroy, params: valid_params

      expect(response).to have_http_status(:redirect)
      expect(Forum.find(forum.id)).to eq(forum)
    end

    it 'does not allow access to non-instructor-team instructors' do
      other_instructor = create(:instructor)
      log_in_and_grant_program_access(other_instructor, program)
      focus_on(course)

      delete :destroy, params: valid_params

      expect(response).to have_http_status(:redirect)
      expect(Forum.find(forum.id)).to eq(forum)
    end

    it 'allows co-instructors to delete the forum' do
      co_instructor = create(:instructor)
      create(:section_instructor, role: 'Co-instructor', section: section,
                                  instructor: co_instructor)
      log_in_and_grant_program_access(co_instructor, program)
      focus_on(course)

      delete :destroy, params: valid_params

      expect(response).to redirect_to(forums_path(program, section))
      expect(Forum.where(id: forum.id).exists?).to be false
    end

    it 'allows assistants to delete the forum' do
      assistant = create(:instructor)
      create(:section_instructor, role: 'Assistant', section: section,
                                  instructor: assistant)
      log_in_and_grant_program_access(assistant, program)
      focus_on(course)

      delete :destroy, params: valid_params

      expect(response).to redirect_to(forums_path(program, section))
      expect(Forum.where(id: forum.id).exists?).to be false
    end

    it 'allows the course owner to delete the forum' do
      log_in_and_grant_program_access(owner, program)
      focus_on(course)

      delete :destroy, params: valid_params

      expect(response).to redirect_to(forums_path(program, section))
      expect(Forum.where(id: forum.id).exists?).to be false
    end
  end
end
