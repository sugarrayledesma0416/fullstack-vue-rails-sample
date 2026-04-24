describe Ua::SchoolsController do
  let(:instructor) { create(:instructor) }
  let(:winning_school) { create(:school) }
  let(:losing_school) { create(:school) }
  let(:merge_params) { { new_school_guid: winning_school.guid, old_school_guid: losing_school.guid, format: :json } }
  let(:bad_merge_params) { { new_school_guid: 'some_random_guid', old_school_guid: losing_school.guid, format: :json } }

  let(:school_user) { create(:school_user, school: losing_school) }
  let(:course) { create(:course, school: losing_school) }

  before do
    basic_auth_user = 'iron_keep_b6eef'
    password = 'test'
    HTTP_AUTHENTICATIONS[basic_auth_user] = password
    request.env['HTTP_AUTHORIZATION'] =
      ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)

    # Create these objects one minute ago so that we can assert that their
    #   updated_at times remain the same.
    Timecop.freeze(1.minute.ago) do
      @school_user_updated_at = school_user.updated_at
      @course_updated_at = course.updated_at
    end
  end

  describe '#merge' do
    def do_request(params)
      put :merge, params: params
    end

    context 'when passed guids for schools to merge,' do
      context 'when both schools are found,' do
        before do
          do_request(merge_params)
        end

        it 'should find and merge the losing school into the winning school' do
          expect(response.status).to eq(200)
        end

        it 'should update school users and courses' do
          expect(school_user.reload.school).to eq(winning_school)
          expect(course.reload.school).to eq(winning_school)
        end

        # Check that update does not invoke callbacks.
        it 'should not change the updated_at time for school users and courses' do
          expect(school_user.reload.updated_at).to be_within(1.second).of(@school_user_updated_at)
          expect(course.reload.updated_at).to be_within(1.second).of(@course_updated_at)
        end
      end

      context 'when one of the schools is not found,' do
        before do
          do_request(bad_merge_params)
        end

        it 'should return failure' do
          expect(response.status).to_not eq(200)
        end

        it 'should not update school users and courses' do
          expect(school_user.school).to eq(losing_school)
          expect(course.school).to eq(losing_school)
        end
      end
    end
  end
end
