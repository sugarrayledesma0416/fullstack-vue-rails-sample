feature 'As an instructor, I can load chat',
        chrome: true, js: true do

  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor) }

  let(:program) { create(:program) }
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      school_id: school.id,
      chat_level: "partner_chat_and_live_chat"
    )
  end
  let!(:section) { create(:section, course: course, instructor: instructor) }


  before do
    create(:school_user,
           user: instructor,
           school: school
          )
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, I have all all the dependencies I need to boot chat ' do

#   visit instructor_dashboard_path(program)
#    expect(page).to have_selector('.js-spec-chat-dependencies-ok')

  end

end
