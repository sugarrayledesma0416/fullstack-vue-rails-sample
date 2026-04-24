describe PartnerChatPermissions do
  let(:dynamo_wrapper) { instance_double(DynamoWrapper) }

  before do
    allow(dynamo_wrapper).to receive(:errors?).and_return(false)
  end

  describe '#status_code' do
    let(:group_chat_users_data) { [] }

    it 'returns "missing_path" if no recording path has been specified' do
      pchat_permission = described_class.new(recording_path: '',
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: nil)

      expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:missing_path]
    end

    it 'returns "unauthorized" if the user is not a student or an instructor' do
      path = 'https://localhost/1234/abc123/archive.mp4'
      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: create(:editor))

      expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
    end

    context 'for student' do
      let(:student) { create(:student) }
      let(:archive_id) { 'abc123' }
      let(:full_path) { "https://localhost/123456/#{archive_id}/archive.mp4" }
      let(:user_1) { { "id" => student.id.to_s, "section_id" => 2 } }
      let(:user_2) { { "id" => (student.id - 1).to_s, "section_id" => 2 } }
      let(:pchat_permission) do
        described_class.new(recording_path: full_path,
                            dynamodb_wrapper: dynamo_wrapper,
                            user: student)
      end

      before do
        allow(dynamo_wrapper).to receive(:find)
          .with(primary_key: [{ 'archive_id' => archive_id }],
                selected_attributes: %w[archive_id course_id user_1 user_2 users])
          .and_return([
                        'archive_id' => archive_id,
                        'course_id' => 1,
                        'user_1' => user_1,
                        'user_2' => user_2,
                        'users' => group_chat_users_data
                      ])
      end

      it 'returns "ok" if the student has access' do
        expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:ok]
      end

      it 'returns "unauthorized" if the student did not record the specified recording' do
        pchat_permission.current_user = create(:student) # Create another student.

        expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
      end

      context 'when the dynamodb returns an error' do
        before do
          allow(dynamo_wrapper).to receive(:errors?).and_return(true)
        end

        it 'returns "unauthorized"' do
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
        end
      end

      context 'when group chat users data is present' do
        let(:group_chat_partner) { create(:student) }
        let(:group_chat_users_data) { ['id' => group_chat_partner.id.to_s] }

        it 'returns "ok" if the group chat student is in the group chat users data hash' do
          pchat_permission = described_class.new(recording_path: full_path,
                                                 dynamodb_wrapper: dynamo_wrapper,
                                                 user: group_chat_partner)
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:ok]
        end

        it 'returns "unauthorized" if the student is not in the group chat users data hash' do
          other_student = create(:student)
          pchat_permission = described_class.new(recording_path: full_path,
                                                 dynamodb_wrapper: dynamo_wrapper,
                                                 user: other_student)
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
        end
      end
    end

    context 'for instructor' do
      let(:archive_id) { 'abc123' }
      let(:instructor) { create(:instructor) }
      let(:course) { create(:course, owner: instructor) }
      let(:section) { create(:section_without_section_instructor_callback, course: course) }
      let(:path) { "https://localhost/123456/#{archive_id}/archive.mp4" }

      let(:pchat_permission) do
        described_class.new(recording_path: path,
                            dynamodb_wrapper: dynamo_wrapper,
                            user: instructor)
      end

      before do
        allow(dynamo_wrapper).to receive(:find)
          .with(primary_key: [{ 'archive_id' => archive_id }],
                selected_attributes: %w{archive_id course_id user_1 user_2 users})
          .and_return(
            [
              {
                'archive_id' => archive_id,
                'course_id' => 1,
                'user_1' => { 'id' => 1, 'section_id' => section.id },
                'user_2' => { 'id' => 2, 'section_id' => section.id },
                'users' => group_chat_users_data
              }
            ]
          )
      end

      it 'returns "ok" if the instructor can grade the section where the recording was made' do
        create(:section_instructor,
               instructor: instructor,
               section: section,
               role: SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])

        expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:ok]
      end

      it 'returns "unauthorized" if the instructor cannot grade the section of the recording' do
        # No section instructor record for instructor, so no access to section.

        expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
      end

      context 'when the dynamodb returns an error' do
        before do
          allow(dynamo_wrapper).to receive(:errors?).and_return(true)
        end

        it 'returns "unauthorized"' do
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
        end
      end

      context 'when group chat users data is present' do
        let(:group_chat_partner) { create(:student) }
        let(:group_chat_users_data) do
          [{ 'id' => group_chat_partner.id.to_s, 'section_id' => section.id }]
        end

        it 'returns "ok" if the group chat student is in the group chat users data hash and '\
           'belongs to a section that the instructor can grade'do
          create(:section_instructor,
                 instructor: instructor,
                 section: section,
                 role: SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:ok]
        end

        it 'returns "unauthorized" if the group chat student is in the group chat users data hash, but '\
           'belongs to a section that the instructor cannot grade'do
          # No section instructor record for instructor, so no access to section.
          expect(pchat_permission.status_code).to eq described_class::STATUS_CODES[:unauthorized]
        end
      end
    end
  end

  describe '#allowed_path' do
    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:archive_id) { 'abc123' }
    let(:section) { create(:section_with_course) }

    def fake_dynamo_wrapper(user:, section_id:)
      allow(dynamo_wrapper).to receive(:find)
        .with(primary_key: [{ "archive_id" => archive_id }],
              selected_attributes: %w{archive_id course_id user_1 user_2 users})
        .and_return([{ "archive_id" => archive_id,
                      "course_id" => 1,
                      "user_1" => { "id" => user.id.to_s, "section_id" => section_id },
                      "user_2" => { "id" => '2', "section_id" => section_id }}])
    end

    before do
      fake_dynamo_wrapper(user: student, section_id: section.id)
    end

    it 'is empty if the user does not have access to the specified recording' do
      path = "https://localhost/123456/#{archive_id}/archive.mp4"
      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: create(:editor))

      expect(pchat_permission.allowed_path).to be_nil
    end

    it 'returns a relative path that can be signed to access the resource (Instructor)' do
      create(:section_instructor, instructor: instructor, section: section) # Instructor can grade section

      path = "https://localhost/123456/#{archive_id}/archive.mp4"

      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: instructor)

      expect(pchat_permission.allowed_path).to eq "123456/#{archive_id}/archive.mp4"
    end

    it 'returns a relative path that can be signed' \
      'when the section can not be graded (Instructor)' do
      fake_dynamo_wrapper(user: instructor, section_id: 0)

      path = "https://localhost/123456/#{archive_id}/archive.mp4"

      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: instructor)

      expect(pchat_permission.allowed_path).to eq "123456/#{archive_id}/archive.mp4"
    end

    it 'returns a relative path that can be signed to access the resource (Student)' do
      path = "https://localhost/123456/abc123/archive.mp4"

      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: student)

      expect(pchat_permission.allowed_path).to eq "123456/#{archive_id}/archive.mp4"
    end

    it 'finds the dynamo record by the relative path, if the student uploaded the video' do
      allow(dynamo_wrapper).to receive(:find).and_return([{}])
      relative_path = "#{SoloVideoRecordingUploader::USER_UPLOADS_PATH}/#{archive_id}/archive.mp4"
      path = "https://localhost/#{relative_path}"
      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: student)
      pchat_permission.allowed_path
      expected_archive_id = relative_path
      expect(dynamo_wrapper).to have_received(:find).with(
        primary_key: [{ "archive_id" => expected_archive_id }],
        selected_attributes: %w{archive_id course_id user_1 user_2 users}
      )
    end

    it 'finds the dynamo record by the uuid component of the full path, if the student recorded using tokbox' do
      path = "https://localhost/123456/#{archive_id}/archive.mp4"
      pchat_permission = described_class.new(recording_path: path,
                                             dynamodb_wrapper: dynamo_wrapper,
                                             user: student)
      pchat_permission.allowed_path
      expected_archive_id = archive_id
      expect(dynamo_wrapper).to have_received(:find).with(
        primary_key: [{ "archive_id" => expected_archive_id }],
        selected_attributes: %w{archive_id course_id user_1 user_2 users}
      )
    end
  end
end
