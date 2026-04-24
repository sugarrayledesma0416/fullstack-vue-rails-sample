describe RosterPresenter do
  include DateTimeHelper

  let(:student_1) { create(:student) }
  let(:student_2) { create(:one_roster_student) }
  let(:student_3) { create(:lti_rostering_student) }
  let!(:student_2_linked_user) { create(:one_roster_linked_user, user: student_2) }
  let!(:student_3_linked_user) { create(:lti_rostering_user_link, user: student_3) }
  let(:course) { section.course }
  let(:section) { create(:section) }
  let(:current_program) { build_stubbed(:program) }

  around do |example|
    Timecop.freeze(Time.local(2019, 9, 25, 7, 51)) do
      example.run
    end
  end

  before do
    create(:enrollment,
           user: student_1,
           section: section,
           sufficient_access: true)

    create(:enrollment,
           user: student_2,
           section: section,
           sufficient_access: false)

    create(:attempt, user: student_1, section: section)
    create(:attempt, user: student_1, section: section)
    create(:attempt, user: student_2, section: section)
    create(:attempt, user: student_3, section: section)
    allow(Maestro::StudentGracePeriod).to receive(:all_for_course).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return([])
    allow(Maestro::UserAccess).to receive(:immediate_access_revoke_list).and_return({})
  end

  let(:students) { section.students.sort_by(&:last_name) }

  let(:presenter) { RosterPresenter.new(section.id, current_program) }

  describe '#student_data' do
    it 'returns an array of hashes of student info' do
      expect(presenter.student_data).to be_a Array
      expect(presenter.student_data[0]).to be_a Hash
    end

    it 'has a hash for each student in the section' do
      expect(presenter.student_data.count).to eq 2
    end

    context 'for each student' do
      it 'provides the name' do
        expect(presenter.student_data[0][:name])
          .to include students[0].last_name
        expect(presenter.student_data[1][:name])
          .to include students[1].last_name
      end

      it 'provides the email address' do
        expect(presenter.student_data[0][:email]).to include students[0].email
        expect(presenter.student_data[1][:email]).to include students[1].email
      end

      it 'includes the date for the last submission' do
        expect(presenter.student_data[0][:last_submission][:date])
          .to eq('Sep 25 2019')
      end

      it 'includes the time for the last submission' do
        expect(presenter.student_data[0][:last_submission][:time])
          .to match(/\A\d{2}:\d{2} (AM|PM)\z/)
      end

      it 'includes the access permissions' do
        expect(presenter.student_data[0][:sufficient_access])
          .to be presenter.students[0].sufficient_access?
        expect(presenter.student_data[1][:sufficient_access])
          .to be presenter.students[1].sufficient_access?
      end

      context 'when a student does not have a last submission' do
        let(:student_without_submissions) { create(:student) }

        before do
          create(:enrollment, user: student_without_submissions, section: section, sufficient_access: true)
        end

        it 'does not include the time' do
          student_data =
            presenter.student_data.find { |s| s[:name].include?(student_without_submissions.last_name) }
          expect(student_data[:last_submission][:time]).to be_nil
        end

        it 'does not include the date' do
          student_data =
            presenter.student_data.find { |s| s[:name].include?(student_without_submissions.last_name) }
          expect(student_data[:last_submission][:date]).to be_nil
        end
      end
    end

    it 'returns only students in the given section' do
      expect(presenter.student_data.each { |s| s[:email] })
        .not_to include(student_3.email)
    end

    describe 'insufficient_access_message key' do
      let(:results) do
        presenter.student_data.filter_map do |student_data|
          student_data[:insufficient_access_message]
        end
      end
      let(:license_group_supersite) do
        instance_double(Maestro::LicenseGroup, name: '01-Supersite')
      end
      let(:license_group_websam) do
        instance_double(Maestro::LicenseGroup, name: 'WebSAM')
      end
      let(:course_license_supersite) do
        instance_double(Maestro::CourseLicense, license_group: license_group_supersite)
      end
      let(:course_license_websam) do
        instance_double(Maestro::CourseLicense, license_group: license_group_websam)
      end

      before do
        allow(Maestro::CourseLicense).to receive(:all).and_return(
          [course_license_supersite, course_license_websam]
        )
      end

      it 'returns a message that describes that the student has no entitlements' do
        expect(results).to include "The student doesn't have access to this program."
      end

      it 'returns a message that describes that the student access has expired' do
        user_license = instance_double(
          Maestro::UserLicense, expired?: true, grace_period?: false, user_guid: student_2.guid
        )
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .with([student_2.guid], current_program.id).and_return([user_license])

        expect(results).to include 'The student access for this program has expired.'
      end

      it 'returns a message that describes that the student is under grace period' do
        user_license = instance_double(
          Maestro::UserLicense, expired?: false, grace_period?: true,
                                user_guid: student_1.guid, expiration_date: 25.days.from_now.to_date
        )
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .with([student_1.guid], current_program.id).and_return([user_license])
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
          .with(student_1.guid, current_program.id).and_return([user_license])
        student_grace_period = instance_double(Maestro::StudentGracePeriod, user_guid: student_1.guid)
        allow(Maestro::StudentGracePeriod).to receive(:all_for_course)
          .with(course.guid).and_return([student_grace_period])

        expect(results).to include 'The student grace period will expire in 25 days.'
      end

      it 'returns zero days remaining, if the student grace period has expired' do
        user_license = instance_double(
          Maestro::UserLicense, expired?: false, grace_period?: true,
                                user_guid: student_1.guid, expiration_date: 10.days.ago.to_date
        )
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .with([student_1.guid], current_program.id).and_return([user_license])
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
          .with(student_1.guid, current_program.id).and_return([user_license])
        student_grace_period = instance_double(Maestro::StudentGracePeriod, user_guid: student_1.guid)
        allow(Maestro::StudentGracePeriod).to receive(:all_for_course)
          .with(course.guid).and_return([student_grace_period])

        expect(results).to include 'The student grace period will expire in 0 days.'
      end

      it 'returns a message that describes that the student is missing entitlements' do
        user_license = instance_double(
          Maestro::UserLicense, expired?: false, grace_period?: false, user_guid: student_2.guid,
                                license_group: license_group_supersite
        )
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return([user_license])

        expect(results).to include "The student doesn't have all the required access to complete the course. " \
                                   'Missing access: WebSAM.'
      end

      it 'does not generate an error if the student that had grace periods now has complete access' do
        user_license = instance_double(
          Maestro::UserLicense, expired?: false, grace_period?: false, user_guid: student_2.guid,
                                license_group: license_group_supersite
        )
        user_license_websam = instance_double(
          Maestro::UserLicense, expired?: false, grace_period?: false, user_guid: student_2.guid,
                                license_group: license_group_websam
        )
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return(
          [user_license, user_license_websam]
        )
        allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
          .with(student_2.guid, current_program.id).and_return([user_license, user_license_websam])
        student_grace_period = instance_double(Maestro::StudentGracePeriod, user_guid: student_2.guid)
        allow(Maestro::StudentGracePeriod).to receive(:all_for_course)
          .with(course.guid).and_return([student_grace_period])

        expect { results }.not_to raise_error
      end

      context 'when the student has an ImmediateAccessRevocation' do
        before do
          allow(Maestro::UserAccess).to receive(:immediate_access_revoke_list).and_return(
            { 'user_guids' => student_2.guid }
          )
        end

        # NOTE: Under normal circumstances, this should not happen because a
        #       student's access cannot be revoked unless the student had access
        #       at some point (which means they should have user licenses).
        it 'returns a message that describes that the student has an ImmediateAccessRevocation ' \
           'for a section' do
          expect(results).to include("The student's Instant Access has been removed.")
        end

        context 'when all user licenses have expired' do
          it 'returns the ImmediateAccessRevocation message with a no access message' do
            user_license = instance_double(
              Maestro::UserLicense, expired?: true, grace_period?: false, user_guid: student_2.guid
            )
            allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
              .with([student_2.guid], current_program.id).and_return([user_license])

            expect(results).to include(
              "The student's Instant Access has been removed. " \
              'They no longer have access to this program.'
            )
          end
        end

        context 'when the student is missing some entitlements' do
          it 'returns the ImmediateAccessRevocation message with missing entitlements' do
            user_license = instance_double(
              Maestro::UserLicense, expired?: false, grace_period?: false, user_guid: student_2.guid,
                                    license_group: license_group_supersite
            )
            allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
              .with([student_2.guid], current_program.id).and_return([user_license])

            expect(results).to include(
              "The student's Instant Access has been removed. " \
              "The student doesn't have all the required access to complete the course. " \
              'Missing access: WebSAM.'
            )
          end
        end
      end
    end
  end

  describe '#students' do
    it 'includes only students who are enrolled in the section' do
      expect(presenter.students.map(&:id)).to match_array(
        [student_1.id, student_2.id]
      )
    end

    context 'for each student' do
      it 'provides the name' do
        expect(presenter.students[0].last_name)
          .to include students[0].last_name
        expect(presenter.students[1].last_name)
          .to include students[1].last_name
      end

      it 'provides the email address' do
        expect(presenter.students[0].email).to include students[0].email
        expect(presenter.students[1].email).to include students[1].email
      end

      it 'includes the access permissions' do
        expect(presenter.students[0].sufficient_access?)
          .to be presenter.students[0].sufficient_access?
        expect(presenter.students[1].sufficient_access?)
          .to be presenter.students[1].sufficient_access?
      end
    end

    it 'returns only students in the given section' do
      expect(presenter.student_data.each { |s| s[:email] })
        .not_to include(student_3.email)
    end
  end

  describe '#update_sufficient_access' do
    it 'update sufficient access field in enrollment model' do
      allow(presenter).to receive(:any_user_licenses_have_expired?).with(student_1.guid).and_return(true)
      allow(presenter).to receive(:any_user_licenses_have_expired?).with(student_2.guid).and_return(false)

      enrollment_1 = Enrollment.find_by(user_id: student_1.id)
      enrollment_2 = Enrollment.find_by(user_id: student_2.id)

      expect {
        presenter.update_sufficient_access
        enrollment_1.reload
      }.to change(enrollment_1, :sufficient_access).from(true).to(false)

      expect {
        presenter.update_sufficient_access
        enrollment_2.reload
      }.not_to change(enrollment_2, :sufficient_access)
    end
  end
  describe '#students_count_label' do
    context 'when there is one student' do
      before do
        allow(presenter).to receive(:students).and_return([student_1])
      end

      it 'returns singular form with count' do
        expect(presenter.students_count_label).to eq '1 Student'
      end
    end

    context 'when there are multiple students' do
      before do
        allow(presenter).to receive(:students).and_return([student_1, student_2])
      end

      it 'returns plural form with count' do
        expect(presenter.students_count_label).to eq '2 Students'
      end
    end
  end
end
