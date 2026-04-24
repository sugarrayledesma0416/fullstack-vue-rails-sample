require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::ActivityNotesController do
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:activity) { create(:activity) }

  let(:location_attrs) do
    {
      activity_id: activity.id,
      cms_revision_id: activity.cms_revision_id,
      note_item_id: 'note_item_id_1'
    }
  end

  let(:content_attrs) do
    {
      body_text: 'body text 1',
      note_type: 'inline',
      title: 'title 1',
      recording_path: 'recording_path_1',
      video_recording_path: 'video_recording_path_1'
    }
  end

  describe 'POST /create' do
    let(:target_path) do
      instructor_activity_notes_path(
        activity_id: activity.id,
        program_id: program.id
      )
    end

    let(:create_params) do
      location_attrs.merge(content_attrs)
    end

    def do_request
      post(target_path, params: create_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'creates a new activity note record when valid params are specified' do
        course = create(:course, owner: instructor, program: program)

        do_request

        # debugging output for validatio failures
        puts response.body.inspect unless response.ok?
        expect(response).to be_ok

        activity_note = ActivityNote.last

        # verify the body is a JSON representation of the created note
        expect(response.body).to eq(
          activity_note.to_json
        )

        # verify that posted params were permitted and saved
        expect(activity_note).to have_attributes(content_attrs)
        expect(activity_note).to have_attributes(location_attrs)

        # verify non-posted attributes were set in the controller action
        expect(activity_note).to have_attributes(
          focused_course_id: course.id,
          program_id: program.id
        )
      end

      it 'reports validation errors when invalid params are specified' do
        create(:course, owner: instructor, program: program)

        post(target_path, params: location_attrs)

        expect(response).to be_unprocessable
        expect(JSON.parse(response.body)).to eq(
          'Validation failed: Recording or body text are required.'
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:old_course) { create(:course) }

    let(:activity_note) do
      create(
        :activity_note,
        content_attrs.merge(location_attrs).merge(
          focused_course_id: old_course.id,
          instructor: instructor
        )
      )
    end

    let(:target_path) do
      instructor_activity_note_path(
        activity_id: activity.id,
        id: activity_note.id,
        program_id: program.id
      )
    end

    let(:new_location_attrs) do
      {
        activity_id: activity.id + 1,
        cms_revision_id: activity.cms_revision_id + 1,
        note_item_id: 'note_item_id_2'
      }
    end

    let(:new_content_attrs) do
      {
        body_text: 'body text 2',
        note_type: 'sidebar',
        title: 'title 2',
        recording_path: 'recording_path_2',
        video_recording_path: 'video_recording_path_2'
      }
    end

    let(:update_params) do
      new_location_attrs.merge(new_content_attrs)
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'updates the activity note with the specified id when valid ' \
        'params are specified' do
        # this will be the focused course
        create(:course, owner: instructor, program: program)

        do_request

        # debugging output for validatio failures
        expect(response).to be_ok

        activity_note.reload

        # verify the body is a JSON representation of the created note
        expect(JSON.parse(response.body)).to eq(
          JSON.parse(activity_note.to_json)
        )

        # verify that posted content params were permitted and saved
        expect(activity_note).to have_attributes(new_content_attrs)

        # verify that posted location params were ignored
        expect(activity_note).to have_attributes(location_attrs)

        # verify focused course was not changed
        expect(activity_note.focused_course_id).to eq(old_course.id)
      end

      it 'reports validation errors when invalid params are specified' do
        put(
          target_path,
          params: {
            body_text: '',
            note_type: 'sidebar',
            title: 'title 2',
            recording_path: '',
            video_recording_path: ''
          }
        )

        expect(response).to be_unprocessable
        expect(JSON.parse(response.body)).to eq(
          'Validation failed: Recording or body text are required.'
        )
      end
    end
  end
end
