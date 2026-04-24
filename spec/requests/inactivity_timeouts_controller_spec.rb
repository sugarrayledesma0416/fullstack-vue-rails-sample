require 'requests/login_helper_methods'

describe InactivityTimeoutsController do
  describe 'PUT /update_session' do
    let(:target_path) { inactivity_timeouts_update_session_path }
    let(:json_response) do
      JSON.parse(response.body, symbolize_names: true)
    end

    def do_request(last_activity_time_epoch: 5.seconds.ago.to_i, school_id: nil)
      put(
        target_path,
        params: {
          inactivity_timeout: {
            last_activity_time_epoch:,
            school_id:
          }
        }
      )
    end

    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    context 'with no logged in user,' do
      it 'returns zero for the time before the next timeout' do
        do_request

        expect(response).to be_ok
        expect(json_response).to eq(
          ttl_to_timeout: 0
        )
      end
    end

    context 'with a logged in user,' do
      let(:program) { create(:program) }
      let(:school) { create(:school) }
      let(:other_school) { create(:school) }
      let(:instructor) { create(:instructor) }

      before do
        log_in_user_with_access_to_programs(instructor, [program])
        # The controller does not require a logged in user but checks if user
        # is logged in.
        # The way the 'current_user' and 'require_user' methods are implemented
        # in the application controller makes that, when executing a request spec,
        # testing for a logged in user in a controller only works if the user
        # already visited a page.
        # To 'fix' that issue, we force the user to visit another page before
        # testing the controller.
        get instructor_announcements_path(program_id: program.id)
      end

      context 'when the user is in a single school,' do
        before do
          instructor.schools << school
        end

        context "when the user's school is configured for inactivity timeout," do
          let!(:school_config) do
            create(
              :school_config,
              school:,
              timeout_enabled: true,
              student_timeout: 50,
              instructor_timeout: 100
            )
          end

          it 'updates the session and returns the time before the next timeout' do
            do_request(school_id: school.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: school_config.instructor_timeout
            )
            expect(Session.last.last_activity_time_epoch).to eq(
              Time.now.to_i
            )
          end

          context 'when the user is not in the specified school' do
            it "defaults to the user's school behavior" do
              do_request(school_id: other_school.id)

              expect(response).to be_ok
              expect(json_response).to eq(
                ttl_to_timeout: school_config.instructor_timeout
              )
              expect(Session.last.last_activity_time_epoch).to eq(
                Time.now.to_i
              )
            end
          end

          context 'when the specified school does not exist,' do
            it "defaults to the user's school behavior" do
              do_request(school_id: 0)

              expect(response).to be_ok
              expect(json_response).to eq(
                ttl_to_timeout: school_config.instructor_timeout
              )
              expect(Session.last.last_activity_time_epoch).to eq(
                Time.now.to_i
              )
            end
          end
        end

        context "when the user's school is not configured for inactivity timeout," do
          it 'does not update the session and returns null for the next timeout' do
            do_request(school_id: school.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: nil
            )
            expect(Session.last.last_activity_time_epoch).to be_nil
          end

          context 'when the user is not in the specified school' do
            before do
              create(
                :school_config,
                school: other_school,
                timeout_enabled: true,
                student_timeout: 50,
                instructor_timeout: 100
              )
            end

            it "defaults to the user's school behavior" do
              do_request(school_id: other_school.id)

              expect(response).to be_ok
              expect(json_response).to eq(
                ttl_to_timeout: nil
              )
              expect(Session.last.last_activity_time_epoch).to be_nil
            end
          end
        end
      end

      context 'when the user is in multiple schools,' do
        let(:school_1) { create(:school) }
        let(:school_2) { create(:school) }
        let(:other_school) { create(:school) }

        before do
          instructor.schools << school_1
          instructor.schools << school_2
        end

        context 'when all the schools are configured for inactivity timeout,' do
          before do
            create(
              :school_config,
              school: school_1,
              timeout_enabled: true,
              student_timeout: 50,
              instructor_timeout: 100
            )
            create(
              :school_config,
              school: school_2,
              timeout_enabled: true,
              student_timeout: 500,
              instructor_timeout: 1000
            )
          end

          it 'updates the session and returns the time before the next timeout' do
            do_request(school_id: school_1.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: school_1.school_config.instructor_timeout
            )
            expect(Session.last.last_activity_time_epoch).to eq(
              Time.now.to_i
            )
          end

          context 'when the user is not in the specified school,' do
            it 'updates the session and returns null for the next timeout' do
              do_request(school_id: other_school.id)

              expect(response).to be_ok
              expect(json_response).to eq(
                ttl_to_timeout: nil
              )
              expect(Session.last.last_activity_time_epoch).to eq(
                Time.now.to_i
              )
            end
          end

          context 'when the specified school does not exist,' do
            it 'updates the session and returns null for the next timeout' do
              do_request(school_id: 0)

              expect(response).to be_ok
              expect(json_response).to eq(
                ttl_to_timeout: nil
              )
              expect(Session.last.last_activity_time_epoch).to eq(
                Time.now.to_i
              )
            end
          end
        end

        context 'when only the specified school is configured for inactivity timeout,' do
          before do
            create(
              :school_config,
              school: school_1,
              timeout_enabled: true,
              student_timeout: 50,
              instructor_timeout: 100
            )
          end

          it 'updates the session and returns the time before the next timeout' do
            do_request(school_id: school_1.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: school_1.school_config.instructor_timeout
            )
            expect(Session.last.last_activity_time_epoch).to eq(
              Time.now.to_i
            )
          end
        end

        context 'when only the non-specified school is configured for inactivity timeout,' do
          before do
            create(
              :school_config,
              school: school_2,
              timeout_enabled: true,
              student_timeout: 50,
              instructor_timeout: 100
            )
          end

          it 'updates the session and returns null for the next timeout' do
            do_request(school_id: school_1.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: nil
            )
            expect(Session.last.last_activity_time_epoch).to eq(
              Time.now.to_i
            )
          end
        end

        context 'when no school is configured for inactivity timeout,' do
          it 'does not update the session and returns null for the next timeout' do
            do_request(school_id: other_school.id)

            expect(response).to be_ok
            expect(json_response).to eq(
              ttl_to_timeout: nil
            )
            expect(Session.last.last_activity_time_epoch).to be_nil
          end
        end
      end
    end
  end

  describe 'GET /log_out' do
    let(:user) { create(:student) }
    let(:target_path) { inactivity_timeouts_log_out_path }

    def do_request
      get target_path
    end

    before do
      log_in_user(user)
    end

    it 'logs the user out and redirects to the UA logout page' do
      do_request

      query_params = '?msg_type=error' \
                     '&flash_msg=You+were+logged+out+of+your+school+due+to+inactivity.'
      expect(response).to redirect_to(
        "#{UA_URL}/logout#{query_params}"
      )
    end
  end
end
