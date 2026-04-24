require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::AnnouncementsController do
  include ActionDispatch::TestProcess::FixtureFile

  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:virus_name) { 'my_bad_virus' }
  let(:infected_file_params) { { infected: 'true', virus_name: virus_name } }

  let(:original_upload) do
    fixture_file_upload('spec/fixtures/media_items/test.jpg', 'image/jpg')
  end

  let(:original_attrs) do
    {
      body: 'original body',
      class_cancelled: true,
      external_link_title: 'original link title',
      external_link_url: 'https://original.link/',
      show_on: 3.days.ago.to_date,
      title: 'original title'
    }
  end

  def create_section_with_course
    course = create(:course, owner: instructor, program: program)
    create(:section, course: course, instructor: instructor)
  end

  describe 'POST /create' do
    let(:target_path) do
      instructor_announcements_path(program_id: program.id)
    end

    let(:create_params) do
      { announcement: original_attrs, uploaded_file: original_upload }
    end

    def do_request
      post(target_path, params: create_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'creates a new announcement record when valid params are specified' do
        section = create_section_with_course

        do_request

        expect(flash[:notice]).to match(/successful/)
        expect(response).to redirect_to(instructor_announcements_path(program))

        announcement = Announcement.last

        # verify that posted params were permitted and saved
        expect(announcement).to have_attributes(original_attrs)
        expect(announcement.file_path).to end_with('test.jpg')

        # verify non-posted attributes were set in the controller action
        expect(announcement.author_id).to eq(instructor.id)
        announcement_section_records = announcement.announcement_sections
        expect(announcement_section_records.size).to eq(1)
        expect(announcement_section_records.first.section_id).to eq(section.id)
      end

      it 'does not save an announcement when invalid params are specified' do
        post(
          target_path,
          params: { announcement: original_attrs.merge(title: '') }
        )

        expect(Announcement.count).to eq(0)
        expect(response).to render_template(:new)
      end

      it 'does not save an announcement when a file infected with a virus' \
         'is uploaded' do
        post(
          target_path,
          params: {
            announcement: original_attrs,
            uploaded_file: infected_file_params
          }
        )

        expect(flash[:error]).to match(/infected with the virus '#{virus_name}'/)
        expect(Announcement.count).to eq(0)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT /update' do
    let(:announcement) { create(:announcement, original_attrs) }

    let(:target_path) do
      instructor_announcement_path(id: announcement.id, program_id: program.id)
    end

    let(:new_attrs) do
      {
        body: 'new body',
        class_cancelled: false,
        external_link_title: 'new link title',
        external_link_url: 'https://new.link/',
        show_on: 2.days.ago.to_date,
        title: 'new title'
      }
    end

    let(:new_upload) do
      fixture_file_upload('spec/fixtures/media_items/test2.jpg', 'image/jpg')
    end

    let(:update_params) do
      { announcement: new_attrs, uploaded_file: new_upload }
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
        create_section_with_course
      end

      it 'updates the announcement record with the specified id when ' \
         'valid params are specified' do
        old_section_id = create(:section).id
        AnnouncementSection.create!(
          announcement_id: announcement.id,
          section_id: old_section_id
        )
        do_request

        expect(flash[:notice]).to match(/successful/)
        expect(response).to redirect_to(instructor_announcements_path(program))

        announcement.reload

        # verify that posted params were permitted and saved
        expect(announcement).to have_attributes(new_attrs)
        expect(announcement.file_path).to end_with('test2.jpg')

        # old announcement section records were destroyed
        expect(
          AnnouncementSection.where(section_id: old_section_id)
        ).not_to exist

        # announcement section ids were replaced with current focused section
        expect(
          AnnouncementSection.where(
            announcement_id: announcement.id,
            section_id: instructor.sections.first.id
          )
        ).to exist
      end

      it 'does not update the announcement record with invalid params' do
        put(
          target_path,
          params: { announcement: new_attrs.merge(title: '') }
        )

        expect(response).to render_template(:edit)

        announcement.reload
        expect(announcement).to have_attributes(original_attrs)
      end

      it 'does not save an announcement when a file infected with a virus' \
         'is uploaded' do
        put(
          target_path,
          params: {
            announcement: new_attrs,
            uploaded_file: infected_file_params
          }
        )

        expect(flash[:error]).to match(/infected with the virus '#{virus_name}'/)

        announcement.reload
        expect(announcement).to have_attributes(original_attrs)
      end
    end
  end
end
