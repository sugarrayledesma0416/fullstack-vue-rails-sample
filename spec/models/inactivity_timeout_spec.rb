describe InactivityTimeout do
  let(:user) { create(:student) }
  let(:district) { create(:district) }
  let(:school) { create(:school, district:) }
  let(:time_since_last_activity) { 55 }
  let(:last_activity_time_epoch) do
    time_since_last_activity.present? ? Time.now.to_i - time_since_last_activity : nil
  end
  let(:session) do
    create(
      :persistent_session,
      user:,
      last_activity_time_epoch:
    )
  end
  let(:inactivity_timeout) { described_class.new(user:, school:, session:) }
  let(:student_timeout) { 100 }
  let(:instructor_timeout) { 200 }
  let(:district_student_timeout) { 500 }
  let(:district_instructor_timeout) { 1_000 }

  describe '#enabled_in_selected_school?' do
    context 'with no logged in user,' do
      let(:user) { nil }
      let(:session) { nil }

      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_selected_school
      end
    end

    context 'with no persistent session,' do
      let(:session) { nil }

      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_selected_school
      end
    end

    context 'when no school is provided,' do
      let(:inactivity_timeout) { described_class.new(user:, school: nil, session:) }

      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_selected_school
      end
    end

    context 'when the school has no configuration,' do
      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_selected_school
      end
    end

    context 'when the school is not configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: false,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        it 'returns false' do
          expect(inactivity_timeout).not_to be_enabled_in_selected_school
        end
      end

      context 'when the district has no configuration,' do
        it 'returns false' do
          expect(inactivity_timeout).not_to be_enabled_in_selected_school
        end
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns false' do
          expect(inactivity_timeout).not_to be_enabled_in_selected_school
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns true' do
          expect(inactivity_timeout).to be_enabled_in_selected_school
        end
      end
    end

    context 'when the school is configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: true,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        it 'returns true' do
          expect(inactivity_timeout).to be_enabled_in_selected_school
        end
      end

      context 'when the district has no configuration,' do
        it 'returns true' do
          expect(inactivity_timeout).to be_enabled_in_selected_school
        end
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns true' do
          expect(inactivity_timeout).to be_enabled_in_selected_school
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns true' do
          expect(inactivity_timeout).to be_enabled_in_selected_school
        end
      end
    end
  end

  describe '#enabled_in_any_school?' do
    let(:inactivity_timeout) { described_class.new(user:, school: nil, session:) }

    context 'with no logged in user,' do
      let(:user) { nil }
      let(:session) { nil }

      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_any_school
      end
    end

    context 'with no persistent session,' do
      let(:session) { nil }

      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_any_school
      end
    end

    context 'when the user is in no school,' do
      it 'returns false' do
        expect(inactivity_timeout).not_to be_enabled_in_any_school
      end
    end

    context 'when the user is in multiple schools and districts,' do
      let(:school_1) { create(:school, district:) }
      let(:school_2) { create(:school) }

      before do
        user.schools << school_1
        user.schools << school_2
      end

      context 'when no school is configured for inactivity timeout,' do
        it 'returns false' do
          expect(inactivity_timeout).not_to be_enabled_in_any_school
        end
      end

      context 'when no school but a district is configured for inactivity timeout,' do
        it 'returns true' do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout:,
            instructor_timeout:
          )

          expect(inactivity_timeout).to be_enabled_in_any_school
        end
      end

      context 'when one of the schools is configured for inactivity timeout,' do
        it 'returns true' do
          create(
            :school_config,
            school: school_2,
            timeout_enabled: true,
            student_timeout:,
            instructor_timeout:
          )

          expect(inactivity_timeout).to be_enabled_in_any_school
        end
      end
    end
  end

  describe '#timeout' do
    shared_examples 'returns the school timeout' do
      context 'when the user is a student,' do
        it 'returns the school timeout for the student' do
          expect(inactivity_timeout.timeout).to eq(student_timeout)
        end
      end

      context 'when the user is an instructor,' do
        let(:user) { create(:instructor) }

        it 'returns the school timeout for the instructor' do
          expect(inactivity_timeout.timeout).to eq(instructor_timeout)
        end
      end
    end

    context 'with no logged in user,' do
      let(:user) { nil }
      let(:session) { nil }

      it 'returns nil' do
        expect(inactivity_timeout.timeout).to be_nil
      end
    end

    context 'with no persistent session,' do
      let(:session) { nil }

      it 'returns nil' do
        expect(inactivity_timeout.timeout).to be_nil
      end
    end

    context 'when the school has no configuration,' do
      it 'returns nil' do
        expect(inactivity_timeout.timeout).to be_nil
      end
    end

    context 'when the school is not configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: false,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        it 'returns nil' do
          expect(inactivity_timeout.timeout).to be_nil
        end
      end

      context 'when the district has no configuration,' do
        it 'returns nil' do
          expect(inactivity_timeout.timeout).to be_nil
        end
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns nil' do
          expect(inactivity_timeout.timeout).to be_nil
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        context 'when the user is a student,' do
          it 'returns the district timeout for the student' do
            expect(inactivity_timeout.timeout).to eq(district_student_timeout)
          end
        end

        context 'when the user is an instructor,' do
          let(:user) { create(:instructor) }

          it 'returns the district timeout for the instructor' do
            expect(inactivity_timeout.timeout).to eq(district_instructor_timeout)
          end
        end
      end
    end

    context 'when the school is configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: true,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        include_examples 'returns the school timeout'
      end

      context 'when the district has no configuration,' do
        include_examples 'returns the school timeout'
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns the school timeout for the student' do
          expect(inactivity_timeout.timeout).to eq(student_timeout)
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        include_examples 'returns the school timeout'
      end
    end

    context 'when no school is provided,' do
      let(:inactivity_timeout) { described_class.new(user:, school: nil, session:) }

      context 'when the user is in no school,' do
        it 'returns nil' do
          expect(inactivity_timeout.timeout).to be_nil
        end
      end

      context 'when the user is in multiple schools and districts,' do
        let(:school_1) { create(:school, district:) }
        let(:school_2) { create(:school) }
        let(:school_3) { create(:school) }

        before do
          user.schools << school_1
          user.schools << school_2
          user.schools << school_3
        end

        before do
          create(
            :school_config,
            school: school_1,
            timeout_enabled: true,
            student_timeout: student_timeout * 2,
            instructor_timeout:
          )
          create(
            :school_config,
            school: school_2,
            timeout_enabled: true,
            student_timeout: student_timeout * 4,
            instructor_timeout: instructor_timeout * 2
          )
          # Create a config where timeout is disabled
          create(
            :school_config,
            school: school_3,
            timeout_enabled: false,
            student_timeout: 1,
            instructor_timeout: 1
          )
          # Create a config for a district
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout:,
            instructor_timeout: instructor_timeout * 4
          )
          # Create a config for a school the user is not in.
          create(
            :school_config,
            school: create(:school),
            timeout_enabled: true,
            student_timeout: 1,
            instructor_timeout: 1
          )
        end

        context 'when the user is a student,' do
          it "returns the smallest timeout of all the student's schools and district" do
            expect(inactivity_timeout.timeout).to eq(student_timeout)
          end
        end

        context 'when the user is an instructor,' do
          let(:user) { create(:instructor) }

          it "returns the smallest timeout of all the instructor's schools and district" do
            expect(inactivity_timeout.timeout).to eq(instructor_timeout)
          end
        end
      end
    end
  end

  describe '#timeout_in' do
    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    context 'with no logged in user,' do
      let(:user) { nil }
      let(:session) { nil }

      it 'returns zero' do
        expect(inactivity_timeout.timeout_in).to eq(0)
      end
    end

    context 'with no persistent session,' do
      let(:session) { nil }

      it 'returns zero' do
        expect(inactivity_timeout.timeout_in).to eq(0)
      end
    end

    context 'when the school has no configuration,' do
      it 'returns nil' do
        expect(inactivity_timeout.timeout_in).to be_nil
      end
    end

    context 'when the school is not configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: false,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        it 'returns nil' do
          expect(inactivity_timeout.timeout_in).to be_nil
        end
      end

      context 'when the district has no configuration,' do
        it 'returns nil' do
          expect(inactivity_timeout.timeout_in).to be_nil
        end
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns nil' do
          expect(inactivity_timeout.timeout_in).to be_nil
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        context 'when the user is a student,' do
          it 'returns the remaining time before the next timeout' do
            expect(inactivity_timeout.timeout_in).to eq(
              district_student_timeout - time_since_last_activity
            )
          end
        end

        context 'when the user is an instructor,' do
          let(:user) { create(:instructor) }

          it 'returns the remaining time before the next timeout' do
            expect(inactivity_timeout.timeout_in).to eq(
              district_instructor_timeout - time_since_last_activity
            )
          end
        end
      end
    end

    context 'when the school is configured for inactivity timeout,' do
      before do
        create(
          :school_config,
          school:,
          timeout_enabled: true,
          student_timeout:,
          instructor_timeout:
        )
      end

      context 'when the school is not in a district,' do
        let(:district) { nil }

        it 'returns the remaining time before the next timeout' do
          expect(inactivity_timeout.timeout_in).to eq(
            student_timeout - time_since_last_activity
          )
        end
      end

      context 'when the district has no configuration,' do
        it 'returns the remaining time before the next timeout' do
          expect(inactivity_timeout.timeout_in).to eq(
            student_timeout - time_since_last_activity
          )
        end
      end

      context 'when the district is not configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: false,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns the remaining time before the next timeout' do
          expect(inactivity_timeout.timeout_in).to eq(
            student_timeout - time_since_last_activity
          )
        end
      end

      context 'when the district is configured for inactivity timeout,' do
        before do
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout: district_student_timeout,
            instructor_timeout: district_instructor_timeout
          )
        end

        it 'returns the remaining time before the next timeout' do
          expect(inactivity_timeout.timeout_in).to eq(
            student_timeout - time_since_last_activity
          )
        end
      end
    end

    context 'when no school is provided,' do
      let(:inactivity_timeout) { described_class.new(user:, school: nil, session:) }

      context 'when the user is in no school,' do
        it 'returns nil' do
          expect(inactivity_timeout.timeout_in).to be_nil
        end
      end

      context 'when the user is in multiple schools and districts,' do
        let(:school_1) { create(:school, district:) }
        let(:school_2) { create(:school) }
        let(:school_3) { create(:school) }

        before do
          user.schools << school_1
          user.schools << school_2
          user.schools << school_3
        end

        before do
          create(
            :school_config,
            school: school_1,
            timeout_enabled: true,
            student_timeout: student_timeout * 2,
            instructor_timeout:
          )
          create(
            :school_config,
            school: school_2,
            timeout_enabled: true,
            student_timeout: student_timeout * 4,
            instructor_timeout: instructor_timeout * 2
          )
          # Create a config where timeout is disabled
          create(
            :school_config,
            school: school_3,
            timeout_enabled: false,
            student_timeout: 1,
            instructor_timeout: 1
          )
          # Create a config for a district
          create(
            :school_config,
            school: district,
            timeout_enabled: true,
            student_timeout:,
            instructor_timeout: instructor_timeout * 4
          )
          # Create a config for a school the user is not in.
          create(
            :school_config,
            school: create(:school),
            timeout_enabled: true,
            student_timeout: 1,
            instructor_timeout: 1
          )
        end

        it 'returns nil' do
          expect(inactivity_timeout.timeout_in).to be_nil
        end
      end
    end
  end

  describe '#update_last_activity_time' do
    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    context 'when the session does not contain the time of the last user activity,' do
      let(:time_since_last_activity) { nil }

      context 'when the provided time is in the past,' do
        it 'sets the last user activity time to now' do
          inactivity_timeout.update_last_activity_time(1.day.ago.to_i)

          expect(session.reload.last_activity_time_epoch).to eq(Time.now.to_i)
        end
      end

      context 'when the provided time is in the future,' do
        it 'sets the last user activity time to the provided time' do
          activity_time = 5.minutes.from_now.to_i
          inactivity_timeout.update_last_activity_time(activity_time)

          expect(session.reload.last_activity_time_epoch).to eq(activity_time)
        end
      end

      context 'when not providing the time of the last user activity,' do
        it 'sets the last user activity time to now' do
          inactivity_timeout.update_last_activity_time

          expect(session.reload.last_activity_time_epoch).to eq(Time.now.to_i)
        end
      end
    end

    context 'when the session contains the time of the last user activity,' do
      context 'when the provided time is before the last user activity,' do
        it 'does not update the last user activity time' do
          inactivity_timeout.update_last_activity_time(1.day.ago.to_i)

          expect(session.reload.last_activity_time_epoch).to eq(last_activity_time_epoch)
        end
      end

      context 'when the provided time is after the time of the last user activity,' do
        it 'sets the last user activity time to the provided time' do
          activity_time = 5.minutes.from_now.to_i
          inactivity_timeout.update_last_activity_time(activity_time)

          expect(session.reload.last_activity_time_epoch).to eq(activity_time)
        end
      end

      context 'when not providing the time of the last user activity,' do
        it 'sets the last user activity time to now' do
          inactivity_timeout.update_last_activity_time

          expect(session.reload.last_activity_time_epoch).to eq(Time.now.to_i)
        end
      end
    end
  end
end
