feature 'ua_student_work_transfer' do
  let(:basic_auth_user) { 'iron_keep_b6eef' }
  let(:basic_auth_password) { 'test' }
  let(:basic_auth_credentials) do
    HTTP_AUTHENTICATIONS[basic_auth_user] = basic_auth_password
    ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, basic_auth_password)
  end

  let(:program) { create(:program) }
  let(:course) { create(:course, program: program) }
  let(:other_course) { create(:course, program: create(:program)) }
  let(:student) { create(:student) }
  let(:origin_section) { create(:section, course: course) }
  let(:destination_section) { create(:section, course: course) }
  let(:work_transfer_queue) { double(WorkTransfer::PreviousSectionTransferWorker) }

  describe 'work_transfer', type: :request do
    scenario 'when origin section has activities it transfer the student work' do
      expect(WorkTransfer::PreviousSectionTransferWorker).to receive(:perform_async)
        .with(student.id, origin_section.id, destination_section.id)
        .and_return(work_transfer_queue)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => student.guid,
             'origin_section_guid' => origin_section.guid,
             'destination_section_guid' => destination_section.guid
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['message'])
        .to eq 'Student work is being transfered, please check in a few minutes.'
    end

    scenario 'when there is an origin section but no destination section does not transfer the student work' do
      expect(WorkTransfer::PreviousSectionTransferWorker).not_to receive(:perform_async)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => student.guid,
             'origin_section_guid' => origin_section.guid,
             'destination_section_guid' => nil
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      expect(JSON.parse(response.body)['message']).to eq 'Destination section not found.'
    end

    scenario 'when there is a destination section but no origin section does not transfer the student work' do
      expect(WorkTransfer::PreviousSectionTransferWorker).not_to receive(:perform_async)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => student.guid,
             'origin_section_guid' => nil,
             'destination_section_guid' => destination_section.guid
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      expect(JSON.parse(response.body)['message']).to eq 'Origin section not found.'
    end

    scenario 'when there is neither an origin section nor a destination section does not transfer the student work' do
      expect(WorkTransfer::PreviousSectionTransferWorker).not_to receive(:perform_async)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => student.guid,
             'origin_section_guid' => nil,
             'destination_section_guid' => nil
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      expect(JSON.parse(response.body)['message'])
        .to eq 'Origin section not found. Destination section not found.'
    end

    scenario 'when sections are not for the same program does not transfer the student work' do
      origin_section.course = other_course
      origin_section.save

      expect(WorkTransfer::PreviousSectionTransferWorker).not_to receive(:perform_async)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => student.guid,
             'origin_section_guid' => origin_section.guid,
             'destination_section_guid' => destination_section.guid
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      expect(JSON.parse(response.body)['message'])
        .to eq 'Sections you want to transfer student work are not from the same program.'
    end

    scenario 'when student is not specified does not transfer the student work' do
      expect(WorkTransfer::PreviousSectionTransferWorker).not_to receive(:perform_async)

      post '/ua/student_work_transfers/work_transfer.json',
           params: {
             'student_guid' => nil,
             'origin_section_guid' => origin_section.guid,
             'destination_section_guid' => destination_section.guid
           },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      expect(JSON.parse(response.body)['message']).to eq 'Student not found.'
    end
  end

  describe 'completed_activities_per_section', type: :request do
    scenario 'when the student is enrolled in a section and has scores' do
      create(:attempt_submitted, user_id: student.id, section_id: origin_section.id)
      create(:attempt_opened, user_id: student.id, section_id: origin_section.id)
      origin_section.students << student

      post '/ua/student_work_transfers/completed_activities_per_section.json',
           params: { 'student_guid' => student.guid, 'program_id' => program.id },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 200

      response_hash = JSON.parse(response.body)
      completed_activities = response_hash['completed_activities']
      expect(completed_activities[origin_section.guid]).to eq 1
      expect(response_hash['message']).to eq ''
    end

    scenario 'when the student is enrolled in a section and does not has scores' do
      origin_section.students << student
      post '/ua/student_work_transfers/completed_activities_per_section.json',
           params: { 'student_guid' => student.guid, 'program_id' => program.id },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 200

      response_hash = JSON.parse(response.body)
      completed_activities = response_hash['completed_activities']

      expect(completed_activities[origin_section.guid]).to eq 0
      expect(response_hash['message']).to eq ''
    end

    scenario 'when the student is not enrolled in any section' do
      post '/ua/student_work_transfers/completed_activities_per_section.json',
           params: { 'student_guid' => student.guid, 'program_id' => program.id },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 200
      response_hash = JSON.parse(response.body)
      completed_activities = response_hash['completed_activities']
      expect(completed_activities).to eq({})
      expect(response_hash['message']).to eq ''
    end

    scenario 'when the student is not sent' do
      post '/ua/student_work_transfers/completed_activities_per_section.json',
           params: { 'student_guid' => nil, 'program_id' => program.id },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      response_hash = JSON.parse(response.body)
      expect(response_hash['message']).to eq 'Student not found.'
      completed_activities = response_hash['completed_activities']
      expect(completed_activities).to eq({})
    end

    scenario 'when the program id is not sent' do
      post '/ua/student_work_transfers/completed_activities_per_section.json',
           params: { 'student_guid' => student.guid, 'program_id' => nil },
           headers: { 'HTTP_AUTHORIZATION' => basic_auth_credentials }

      expect(response.status).to eq 422
      response_hash = JSON.parse(response.body)
      expect(response_hash['message']).to eq 'Program not found.'
      completed_activities = response_hash['completed_activities']
      expect(completed_activities).to eq({})
    end
  end

end
