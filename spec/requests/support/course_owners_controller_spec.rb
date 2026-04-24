require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Support::CourseOwnersController do
  let(:support_rep_role) { Role.create!(name: Role::SUPPORT_REP) }
  let(:user) { create(:user) }
  let(:ua_url) { 'https://testenv.vhlcentral.com/' }
  let(:school) { create(:clever_school) }
  let(:instructor) { create(:clever_instructor, schools: [school]) }
  let(:lti_rostering_schools) do
    create_list(:school, 2)
  end
  let(:lti_rostering_instructor) do
    user = create(:lti_rostering_instructor, schools: lti_rostering_schools)
    create(:lti_rostering_user_link, user: user)
    user
  end
  let(:ra_schools) do
    create_list(:one_roster_school, 2)
  end
  let(:ra_instructor) do
    user = create(:one_roster_instructor, schools: ra_schools)
    create(:one_roster_linked_user, user: user, school: ra_schools.last)
    user
  end

  before { stub_const('UA_URL', ua_url) }

  describe 'GET /show' do
    let(:target_path) { support_course_owner_path(instructor_guid: instructor.guid) }

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    it 'denies access to users without a support_rep role' do
      log_in_user(user)
      do_request
      expect(response).to redirect_to '/403'
    end

    context 'with a logged in user with support_rep role,' do
      before do
        user.roles << support_rep_role
        log_in_user(user)
      end

      it 'renders the show view' do
        do_request

        expect(response).to be_ok
        expect(response).to render_template(:show)
        expect(assigns(:page_title)).to eq('Change Course Owner')
        expect(assigns(:presenter)).to be_a(Support::CourseOwnerPresenter)
        expect(assigns(:presenter).instructor).to eq(instructor)
      end

      context 'when the instructor is not allowed to change course owner' do
        let(:instructor) { create(:instructor) }

        it 'redirects to the user search page' do
          do_request

          expect(response).to redirect_to(
            "#{UA_URL}/support/user_search/#{instructor.guid}"
          )
          expect(flash[:error]).to eq(
            'Can only change course owner for instructors of the following types: ' \
            "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER}."
          )
        end
      end
    end
  end

  describe 'PUT /update' do
    let(:target_path) { support_course_owner_path(instructor_guid: instructor.guid) }
    let(:course) { create(:open_course, owner: instructor) }
    let(:new_owner) { create(:clever_instructor, schools: [school]) }
    let(:default_params) do
      {
        course_id: course.id,
        new_owner_id: new_owner.id
      }
    end

    def do_request(extra_params = {})
      put target_path, params: default_params.merge(extra_params)
    end

    include_examples 'require logged in user'

    it 'denies access to users without a support_rep role' do
      log_in_user(user)
      do_request
      expect(response).to redirect_to '/403'
    end

    context 'with a logged in user with support_rep role,' do
      before do
        user.roles << support_rep_role
        log_in_user(user)
      end

      context 'when the course does not exist' do
        it 'raises a 404 error' do
          expect { do_request(course_id: '') }.to raise_error(
            ActiveRecord::RecordNotFound,
            /Couldn't find Course/
          )
        end
      end

      context 'when the new owner does not exist' do
        it 'raises a 404 error' do
          expect { do_request(new_owner_id: '') }.to raise_error(
            ActiveRecord::RecordNotFound,
            /Couldn't find Instructor/
          )
        end
      end

      context 'when the instructor is not allowed to change course owner' do
        let(:instructor) { create(:instructor) }

        it 'redirects to the user search page' do
          do_request

          expect(response).to redirect_to(
            "#{UA_URL}/support/user_search/#{instructor.guid}"
          )
          expect(flash[:error]).to eq(
            'Can only change course owner for instructors of the following types: ' \
            "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER}."
          )
        end
      end

      context 'when the new owner is not a Clever instructor' do
        it_behaves_like 'a new owner with invalid instructor type'
      end

      context 'when the new owner is not an LTI Rostering instructor' do
        let(:instructor) { lti_rostering_instructor }

        it_behaves_like 'a new owner with invalid instructor type'
      end

      context 'when the new owner is not a Roster Assistant instructor' do
        let(:instructor) { ra_instructor }

        it_behaves_like 'a new owner with invalid instructor type'
      end

      context 'when the course is closed' do
        let(:course) do
          create(:closed_course, owner: instructor)
        end

        it 'does not change the owner of the course and shows an error message' do
          do_request

          expect(course.owner.reload).to eq(instructor)
          expect(response).to render_template(:show)
          expect(flash[:error]).to eq(
            'Failed to update the course.'
          )

          expect(assigns(:course_name)).to eq(course.name)
          expect(assigns(:errors)).to contain_exactly(
            'The course is closed.'
          )

          expect(assigns(:presenter)).to be_a(Support::CourseOwnerPresenter)
          expect(assigns(:presenter).instructor).to eq(instructor)
        end
      end

      context 'when the course is archived' do
        let(:course) do
          create(:archived_course, owner: instructor)
        end

        it 'does not change the owner of the course and shows an error message' do
          do_request

          expect(course.owner.reload).to eq(instructor)
          expect(response).to render_template(:show)
          expect(flash[:error]).to eq(
            'Failed to update the course.'
          )

          expect(assigns(:course_name)).to eq(course.name)
          expect(assigns(:errors)).to contain_exactly(
            'The course is archived.'
          )

          expect(assigns(:presenter)).to be_a(Support::CourseOwnerPresenter)
          expect(assigns(:presenter).instructor).to eq(instructor)
        end
      end

      context 'when the course has no section' do
        it 'changes the owner of the course' do
          do_request

          expect(course.reload.owner).to eq(new_owner)
          expect(response).to redirect_to(
            support_course_owner_path(instructor_guid: instructor.guid)
          )
          expect(flash[:notice]).to eq('Course successfully updated.')
        end
      end

      context 'when the course has sections' do
        let(:section_1) do
          create(
            :section,
            name: 'section 1',
            course: course,
            instructor: instructor
          )
        end
        let(:section_2) do
          create(
            :section,
            name: 'section 2',
            course: course,
            instructor: instructor
          )
        end
        let(:sections) do
          [
            section_1,
            section_2
          ]
        end
        let(:section_1_new_owner) do
          create(
            :section_instructor,
            section: section_1,
            instructor: new_owner
          )
        end
        let(:section_2_new_owner) do
          create(
            :section_instructor,
            section: section_2,
            instructor: new_owner
          )
        end

        before do
          section_1_new_owner
          section_2_new_owner
        end

        it 'changes the owner of the course and all the sections' do
          do_request

          expect(course.reload.owner).to eq(new_owner)
          sections.each do |section|
            expect(section.reload.instructor).to eq(new_owner)
          end
          expect(response).to redirect_to(
            support_course_owner_path(instructor_guid: instructor.guid)
          )
          expect(flash[:notice]).to eq('Course successfully updated.')
        end
      end
    end
  end
end
