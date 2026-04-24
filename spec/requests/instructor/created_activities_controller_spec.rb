require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::CreatedActivitiesController do
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:school_user) { create(:school_user, user: instructor, school: school) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:default_page) { 1 }
  let(:concept) do
    create(
      :concept,
      lesson: lesson,
      id: strand.location,
      program: program
    )
  end

  let(:instructor_created_activity) do
    create(
      :instructor_created_activity,
      instructor: instructor,
      lesson: lesson,
      title: 'Title example',
      toc_location: strand.location
    )
  end

  let(:activity_copy) do
    create(
      :instructor_created_activity,
      instructor: instructor,
      lesson: lesson,
      title: 'Title example',
      toc_location: strand.location
    )
  end

  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }

  let(:original_composition_attrs) do
    {
      direction_line: 'original direction line',
      hide_from_my_content: false,
      question_prompt: 'original question prompt',
      title: 'original title'
    }
  end

  let(:original_video_attrs) do
    {
      direction_line: 'original direction line',
      hide_from_my_content: false,
      title: 'original title',
      video_url: 'http://www.youtube.com/watch?v=videoslug01',
      video_platform: 'youtube'
    }
  end
  let!(:image_media_item_1) { create(:media_item, :id => 247, :media_type => 'image', :height => 100) }

  let(:original_references_params) do
    {
      '0' => {
        body: 'original body',
        header: 'original header',
        type: 'text'
      },
      '1' => {
        instructor_media_item_id: image_media_item_1.id,
        type: 'image'
      },
      '2' => {
        id: '123',
        recording_path: 'original_audio_path',
        type: 'audio'
      },
      '3' => {
        body: 'original wordbank body',
        type: 'wordbank'
      }
    }
  end

  let(:composition_create_params) do
    {
      activity_type: 'composition',
      instructor_created_activity: original_composition_attrs.merge(
        references: original_references_params
      )
    }
  end

  let(:video_create_params) do
    {
      activity_type: 'external_video',
      instructor_created_activity: original_video_attrs.merge(
        references: original_references_params
      )
    }
  end

  let(:mock_s3_bucket) { instance_double(Radner::S3Storage, move_file: true) }
  let(:test_blob) { File.read('spec/fixtures/media_items/test.jpg') }
  let(:verifier_klass) do
    MaestroActivityEngine::ActivityContent::ExternalVideoContent::YouTubeVerifier
  end
  let(:mock_youtube_api) do
    instance_double(verifier_klass, video_exists?: true)
  end
  # Need to mock this image because MiniMagick.open is called with a remote
  # url pointing to the media CDN, and webmock doesn't stub the response well.
  let(:mock_image) do
    instance_double(MiniMagick::Image, dimensions: [123, 456])
  end
  let(:content_sharing_disabled_msg) do
     Instructor::CreatedActivitiesController::CONTENT_SHARING_DISABLED_MESSAGE
  end

  def disable_sharing_by_school(course)
    course.school.school_config = create(
      :school_config,
      school_content_sharing: false
    )
  end

  def disable_sharing_by_program(course)
    program_content_sharing_json = { course.program_id.to_s => false }
    course.school.school_config = create(
      :school_config,
      school_content_sharing: true,
      program_content_sharing_json:
    )
  end

  before do
    create(:concept, id: strand.location, lesson: lesson, program: program)

    # mock external network api calls
    allow(Radner::S3Storage).to receive(:new).and_return(mock_s3_bucket)
    allow(mock_s3_bucket).to receive(:fetch).and_return(test_blob)
    allow(MiniMagick::Image).to receive(:open).and_return(mock_image)
    allow(verifier_klass).to receive(:new).and_return(mock_youtube_api)
    allow(Maestro::LicenseGroup).to receive(:all)
      .and_return([Maestro::LicenseGroup.new('name' => '01-Supersite')])
  end

  describe 'when a institution admin share IGC' do

    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::CompositionContent,
        activity_type: 'composition',
        content_summary: { question_1: 1 },
        grading_method: 'instructor_graded',
        max_attempts: 2,
        points_possible: 10,
        submittable?: true,
        randomizable?: true
      )
    end

    before do
      log_in_user_with_access_to_programs(instructor, [program])
      document = Nokogiri::XML::Document.new
      direction_line = Nokogiri::XML::Node.new('dl', document)
      bold_text = Nokogiri::XML::Node.new('b', document)
      bold_text.content = 'direction line'
      direction_line.add_child(bold_text)

      allow(content_object).to receive(:dl).and_return(direction_line)
      allow(content_object).to receive(:title).and_return('Title example')
      allow_any_instance_of(InstructorCreatedActivityForCopy).to receive(:content_object).and_return(content_object)
    end

    context '#shared_content_index' do
      let(:shared_content_index) do
        instructor_shared_content_path(program_id: program.id)
      end

      def do_request
        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Course,#{course.id}", return_to: '' }
        )
        get(shared_content_index)
      end

      it 'go to instructor shared content path' do
        do_request
        expect(response).to render_template(:index)
      end

      it 'redirects to my content if the school has disabled sharing content' do
        disable_sharing_by_school(course)
        do_request
        expect(response).to redirect_to(instructor_mycontent_path(program.id))
        expect(flash[:warning]).to eq(content_sharing_disabled_msg)
      end

      it 'redirects to my content if the school has disabled sharing content for the program' do
        disable_sharing_by_program(course)
        do_request
        expect(response).to redirect_to(instructor_mycontent_path(program.id))
        expect(flash[:warning]).to eq(content_sharing_disabled_msg)
      end
    end

    context '#copy_to_mycontent' do
      let(:shared_library_activity) { create(:shared_library_activity,
                                             source_activity: instructor_created_activity,
                                             activity: activity_copy,
                                             school: school) }
      let(:copy_to_mycontent) do
        instructor_created_activities_copy_to_mycontent_path(id: activity_copy.id,
                                                             lesson_id: lesson.id,
                                                             program_id: program.id,
                                                             toc_entry_id: strand.location,
                                                             display_lesson: lesson.id)
      end

      def do_request(page_number = 1)
        put(copy_to_mycontent, params: {page: page_number})
      end

      context 'when instructor with program access is logged in,' do
        before do
          allow(Maestro::User).to receive(:accessible_programs).with(instructor.guid).and_return([program])
          allow(Maestro::LicenseGroup).to receive(:all).and_return([])
          allow(instructor_created_activity).to receive(:direction_line).and_return('It is a new direction line')
          allow_any_instance_of(InstructorCreatedActivity).to receive(:language).and_return('fr')
          shared_library_activity
        end

        it 'creates a new instructor created activity record successfully' do
          do_request

          expect(flash[:notice]).to include('Content successfully copied.')
        end

        it 'redirect to instructor shared content path with page 1 as default' do
          expect(do_request).to redirect_to(instructor_shared_content_path(program.id, page: 1))
        end

        it 'redirects to the same shared content page you were' do
          page_number = 3
          do_request(page_number)

          expect(response).to redirect_to(instructor_shared_content_path(program_id: program.id, page: page_number))
        end
      end
    end

    context '#convert_to_shared' do
      let(:convert_to_shared) do
        instructor_created_activities_convert_to_shared_path(id: instructor_created_activity.id,
                                                             lesson_id: lesson.id,
                                                             program_id: program.id,
                                                             toc_entry_id: strand.location,
                                                             display_lesson: lesson.id)
      end

      def do_request
        put(convert_to_shared)
      end

      before do
        school_user
        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Course,#{course.id}", return_to: '' }
        )
      end

      it 'create a share library activity record' do
        expect { do_request }.to change(SharedLibraryActivity, :count).by(1)
      end

      it 'request to share an activity' do
        do_request
        expect(flash[:notice]).to match("#{instructor_created_activity.title} has successfully been requested to share with #{school.name}")
      end

      it 'redirect to instructor content path' do
        expect(do_request).to redirect_to(instructor_mycontent_path(program.id,
                                                                    display_lesson: lesson.id))
      end
    end

    context '#remove_as_shared' do
      let(:instructor_created_activity) { create(:instructor_created_activity,
                                                 lesson: lesson,
                                                 toc_location: strand.location,
                                                 instructor: instructor) }
      let(:shared_library_activity) { create(:shared_library_activity,
                                             source_activity: instructor_created_activity,
                                             school: school) }

      let(:remove_as_shared) do
        instructor_created_activities_remove_as_shared_path(id: instructor_created_activity.id,
                                                            lesson_id: lesson.id,
                                                            program_id: program.id,
                                                            toc_entry_id: strand.location,
                                                            display_lesson: lesson.id)
      end

      def do_request
        delete(remove_as_shared)
      end

      it 'destroy share library activities records' do
        shared_library_activity
        expect { do_request }.to change(SharedLibraryActivity, :count).by(-1)
      end

      it 'delete the request to share an activity record successfully' do
        do_request
        expect(flash[:notice]).to match("#{instructor_created_activity.title} has successfully been deleted.")
      end

      it 'redirect to instructor content path by default' do
        expect(do_request).to redirect_to(instructor_mycontent_path(program.id,
                                                                    display_lesson: lesson.id))
      end
    end
  end

  describe 'GET /confirm_destroy' do
    def do_request
      get(
        confirm_destroy_instructor_my_content_path(
          id: instructor_created_activity.id,
          program_id: instructor_created_activity.program.id
        ),
        xhr: true
      )
    end

    context 'when the instructor is not the owner' do
      let(:other_instructor) { create(:instructor) }

      before do
        log_in_user_with_access_to_programs(other_instructor, [program])
      end

      it 'does not allow to destroy the activity' do
        do_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the instructor is the owner' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

       it 'responds with 200 status' do
        do_request
        expect(response).to have_http_status(:ok)
      end

      it 'renders the confirm_destroy template' do
        do_request
        expect(response).to render_template(:confirm_destroy)
      end
    end
  end

  describe 'DELETE /destroy' do
    before { create(:course, owner: instructor, program: program)  }

    def do_request
      delete(
        instructor_my_content_path(
          id: instructor_created_activity.id,
          program_id: instructor_created_activity.program.id,
          from_my_content: true
        )
      )
    end

    context 'when the instructor is not the owner' do
      let(:other_instructor) { create(:instructor) }
      let(:default_path) { BestDefaultPath.best_default_path(other_instructor, program, nil, {}) }

      before do
        log_in_user_with_access_to_programs(other_instructor, [program])
      end

      it 'does not allow to destroy the activity' do
        do_request
        expect(flash[:error]).to eq(Instructor::CreatedActivitiesController::NOT_AUTHORIZED_MESSAGE)
        expect(response).to redirect_to(default_path)
      end
    end

    context 'when the instructor is the owner' do
      let(:remover_message) { 'Test removal message' }
      let(:remover) do
        instance_double(InstructorActivityRemover, successful?: successful, message: remover_message)
      end

      before do
        allow(InstructorActivityRemover).to receive(:new)
          .with(instructor_created_activity).and_return(remover)
        allow(remover).to receive(:remove).and_return(remover)
        log_in_user_with_access_to_programs(instructor, [program])
      end

      context 'when successful' do
        let(:successful) { true }

        it 'redirects to my content page' do
          do_request
          expect(response).to redirect_to(
            instructor_mycontent_url(
              program_id: instructor_created_activity.program.id,
              selected_lesson_ids: lesson.id,
              selected_strands: strand.title,
              filtered: true,
              page: default_page
            )
          )
        end

        it 'sets a success flash message' do
          do_request
          follow_redirect!
          expect(flash[:success]).to eq(remover_message)
        end
      end

      context 'when unsuccessful' do
        let(:successful) { false }

        it 'redirects to my content page' do
          do_request
          expect(response).to redirect_to(
            instructor_mycontent_url(
              program_id: instructor_created_activity.program.id,
              selected_lesson_ids: lesson.id,
              selected_strands: strand.title,
              filtered: true,
              page: default_page
            )
          )
        end

        it 'sets an error flash message' do
          do_request
          follow_redirect!
          expect(flash[:error]).to eq(remover_message)
        end
      end
    end
  end

  describe 'POST /create' do
    let(:target_path) do
      instructor_created_activities_path(
        lesson_id: lesson.id,
        program_id: program.id,
        toc_entry_id: strand.location
      )
    end

    def do_request(opts = {})
      post(target_path, params: composition_create_params.deep_merge(opts))
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        # create non-focused course
        create(:course, owner: instructor, program: program)
        log_in_user_with_access_to_programs(instructor, [program])
        # explicitly set focused course
        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Course,#{course.id}", return_to: '' }
        )
      end

      it 'requires a root key :instructor_created_activity in the params' do
        expect { post(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: instructor_created_activity/
        )
      end

      it 're-renders the new view when invalid params are specified' do
        do_request(instructor_created_activity: { title: ''  })

        expect(flash[:notice]).not_to match(/has been created/)

        expect(response).to render_template(:new)

        expect(assigns(:created_activity).errors.full_messages).to eq(
          ['Title is required']
        )
      end

      it 'creates a new instructor_created_activity record when valid ' \
         'composition params are specified' do
        do_request

        expect(response).to redirect_to(
          instructor_toc_path(
            display_lesson: lesson.id,
            program_id: program.id,
            start_unit: lesson.unit.rank,
            toc_location: strand.location
          )
        )
        expect(flash[:notice]).to match(/has been created/)

        activity = InstructorCreatedActivity.last

        # Verify that posted params were permitted and saved.
        expect(activity).to have_attributes(
          original_composition_attrs.merge(activity_type: 'composition')
        )

        references = activity.content_object.reference_items

        original_references_params.each do |key, expected|
          reference = references[key.to_i]
          expect(reference.type).to eq(expected[:type])
          expect(reference.body_html).to eq(expected[:body]) if expected[:body]
          expect(reference.header_html).to eq(expected[:header]) if expected[:header]
          if expected[:type] == 'audio'
            expect(reference.recording_id).to eq(expected[:id])
          elsif expected[:type] == 'image'
            expect(reference.image.media_item_id).to eq(image_media_item_1.id.to_s)
          end
        end

        # Verify non-posted attributes were set in the controller action.
        expect(activity).to have_attributes(
          concept_id: strand.location.to_i,
          instructor_id: instructor.id,
          lesson_id: lesson.id,
          toc_location: strand.location.to_i
        )
        expect(activity.content_object.language).to eq(program.language_code)

        # We check that we don't create a record to course_library_activities
        # table because, that way of showing IGCs in the ToC it's going to be
        # deprecated.
        expect(
          CourseLibraryActivity.where(
            activity_id: activity.id,
            course_id: course.id
          )
        ).not_to exist
      end

      it 'redirects to the first page of My Content if from_my_content param is true' do
        do_request(from_my_content: 'true')

        expect(response).to redirect_to(
          instructor_mycontent_url(
            program_id: program.id,
            selected_lesson_ids: lesson.id,
            selected_strands: strand.title,
            filtered: true,
            page: default_page
          )
        )
        expect(flash[:notice]).to match(/has been created/)
      end

      it 'creates a new instructor_created_activity record when valid ' \
         'external_video params are specified' do
        post(target_path, params: video_create_params)

        expect(response).to redirect_to(
          instructor_toc_path(
            display_lesson: lesson.id,
            program_id: program.id,
            start_unit: lesson.unit.rank,
            toc_location: strand.location
          )
        )
        expect(flash[:notice]).to match(/has been created/)

        activity = InstructorCreatedActivity.last

        # Verify that posted params were permitted and saved.
        expected_attrs = {
          direction_line: 'original direction line',
          hide_from_my_content: false,
          title: 'original title',
          video_url: 'https://www.youtube.com/embed/videoslug01?rel=0',
          video_platform: 'youtube',
          activity_type: 'external_video'
        }
        expect(activity).to have_attributes(expected_attrs)

        references = activity.content_object.reference_items

        original_references_params.each do |key, expected|
          reference = references[key.to_i]
          expect(reference.type).to eq(expected[:type])
          expect(reference.body_html).to eq(expected[:body]) if expected[:body]
          expect(reference.header_html).to eq(expected[:header]) if expected[:header]
          if expected[:type] == 'audio'
            expect(reference.recording_id).to eq(expected[:id])
          elsif expected[:type] == 'image'
            expect(reference.image.media_item_id).to eq(image_media_item_1.id.to_s)
          end
        end

        # Verify non-posted attributes were set in the controller action.
        expect(activity).to have_attributes(
          concept_id: strand.location.to_i,
          instructor_id: instructor.id,
          lesson_id: lesson.id,
          toc_location: strand.location.to_i
        )
        expect(activity.content_object.language).to eq(program.language_code)
      end

      it 'sets assignment_group if submitted with form' do
        do_request(instructor_created_activity: { assignment_group: 'Communicate'})

        expect(InstructorCreatedActivity.last.assignment_group)
          .to eq('Communicate')
      end
    end
  end

  describe 'PUT /update' do
    let(:source_activity) { create(:activity) }
    let(:activity) do
      InstructorCreatedActivity.create!(
        original_composition_attrs.merge(
          activity_type: 'composition',
          instructor_id: instructor.id,
          language_code: program.language_code,
          lesson: lesson,
          references: original_references_params,
          toc_entry_id: strand.location
        )
      )
    end

    let(:target_path) do
      instructor_created_activity_path(
        id: activity.id,
        lesson_id: lesson.id,
        program_id: program.id,
        toc_entry_id: strand.location
      )
    end

    let(:new_composition_attrs) do
      {
        direction_line: 'new direction line',
        question_prompt: 'new question prompt',
        title: 'new title'
      }
    end
    let!(:image_media_item_2) { create(:media_item, :id => 248, :media_type => 'image', :height => 100) }

    let(:new_references_params) do
      {
        '0' => {
          body: 'new body',
          header: 'new header',
          type: 'text'
        },
        '1' => {
          instructor_media_item_id: image_media_item_2.id,
          type: 'image'
        },
        '2' => {
          id: '123',
          recording_path: 'new',
          type: 'audio'
        },
        '3' => {
          body: 'new wordbank body',
          type: 'wordbank'
        }
      }
    end

    let(:composition_update_params) do
      {
        activity_type: 'composition',
        instructor_created_activity: new_composition_attrs.merge(
          references: new_references_params
        )
      }
    end

    def do_request(opts = {})
      put(target_path,
          params: composition_update_params
                    .deep_merge(opts)
                    .merge({ focus: "Course,#{course.id}", return_to: '' })
        )
    end

    include_examples 'require instructor with program access'

    context 'with a valid instructor, who is not the owner of the activity' do
      it 'redirects the user to best default path' do
        non_owner_instructor = create(:instructor)
        log_in_user_with_access_to_programs(non_owner_instructor, [program])
        best_default_path = BestDefaultPath.best_default_path(non_owner_instructor, program, nil, {})

        do_request

        expect(flash[:error]).to eq(Instructor::CreatedActivitiesController::NOT_AUTHORIZED_MESSAGE)
        expect(response).to redirect_to(best_default_path)
      end
    end

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :instructor_created_activity in the params' do
        expect { put(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: instructor_created_activity/
        )
      end

      it 're-renders the edit view when invalid params are specified' do
        do_request( instructor_created_activity: { title: ''  })

        expect(flash[:notice]).not_to match(/has been updated/)

        expect(response).to render_template(:edit)

        expect(assigns(:created_activity).errors.full_messages).to eq(
          ['Title is required']
        )
      end

      it 'updates the activity xml if rubric_json is specified' do
        rubric_xml = <<~XML
          <rubric id="123" rubric_revision_id="456">
            <header_row>
              <header_column id="1">old_col_header</header_column>
            </header_row>
            <criteria>
              <title>old_row_title</title>
              <performance header_id="1">
                <description>old_description</description>
                <score>5</score>
              </performance>
            </criteria>
          </rubric>
        XML

        posted_data = {
          criterias: [
            {
              Criteria: {
                performances: [
                  { description: 'new_description', header_id: '1', score: 5 }
                ],
                title: 'new_row_title'
              }
            },
          ],
          header_row: {
            HeaderRow: {
              header_columns: [{ id: '1', label: 'new_col_header' }]
            }
          }
        }

        original_xml = activity.content
        doc = Nokogiri::XML.parse(original_xml)
        doc.root.add_child(rubric_xml)

        activity.generated_content = doc.to_xml
        activity.save!

        old_revision_id = activity.instructor_revision_id

        activity.custom_rubrics.create!(
          activity_revision_id: old_revision_id,
          course_id: course.id,
          draft: true,
          instructor_id: instructor.id,
          source_activity_id: source_activity.id,
          stored_rubric: rubric_xml
        )

        put(
          target_path,
          params: {
            instructor_created_activity: { rubric_json: posted_data.to_json },
            focus: "Course,#{course.id}",
            return_to: ''
          }
        )

        expect(flash[:notice]).to match(/has been updated/)

        # Just calling activity.reload isn't sufficient because it
        # doesn't clear instance variables, which hold stale information.
        reloaded_activity = InstructorCreatedActivity.find(activity.id)

        # Verify that posted params were permitted and saved.
        rubric = reloaded_activity.content_object.rubric

        # Verify the changes to the rubric stored in the activity xml
        expect(rubric).to be_a(
          MaestroActivityEngine::ActivityContent::Common::Rubric
        )

        expect(
          rubric.header_row.header_columns.first[:label]
        ).to eq('new_col_header')

        criterion = rubric.criterias.first
        expect(criterion.title).to eq('new_row_title')

        expect(
          criterion.performances.first[:description]
        ).to eq('new_description')

        # Verify that the original CustomRubric record exists, keyed to
        # the old revision id, and has the original rubric xml.
        old_custom_rubric = reloaded_activity.custom_rubrics.find_by(
          activity_revision_id: old_revision_id
        )

        expect(old_custom_rubric[:stored_rubric]).to eq(rubric_xml)

        # Verify that the new CustomRubric record exists, keyed to
        # the new revision id, and has the updated rubric xml.
        new_custom_rubric = reloaded_activity.custom_rubrics.find_by(
          activity_revision_id: reloaded_activity.instructor_revision_id
        )

        expect(new_custom_rubric[:stored_rubric]).to match(
          %r{<rubric.*>.*new_col_header.*new_description.*</rubric>}m
        )
      end

      it 'updates the activity with the specified id when valid ' \
         'params are specified' do
        do_request

        expect(flash[:notice]).to match(/has been updated/)

        expect(response).to redirect_to(
          instructor_toc_path(
            program_id: program.id,
            display_lesson: lesson.id,
            start_unit: lesson.unit.rank,
            toc_location: strand.location
          )
        )

        # Just calling activity.reload isn't sufficient because it
        # doesn't clear instance variables, which hold stale information.
        reloaded_activity = InstructorCreatedActivity.find(activity.id)

        # Verify that posted params were permitted and saved.
        expect(reloaded_activity).to have_attributes(
          new_composition_attrs.merge(activity_type: 'composition')
        )
      end

      it 'sets assignment_group if submitted with form' do
        do_request(instructor_created_activity: { assignment_group: 'Communicate'})

        expect(
          InstructorCreatedActivity.last.assignment_group
        ).to eq('Communicate')
      end

      it 'redirects to the activity show page if popup param is true' do
        put(target_path, params: composition_update_params.merge(popup: 'true'))

        expect(response).to redirect_to(
          section_activity_path(id: activity.id, popup: '1', section_id: 0)
        )
        expect(flash[:notice]).to match(/has been updated/)
      end

      context 'when the popup param is not true,' do
        it 'deletes the activity and redirects to the My Content page if ' \
           'hide_from_my_content param is true' do
          put(
            target_path,
            params: composition_update_params.deep_merge(
              instructor_created_activity: { hide_from_my_content: true }
            )
          )

          activity.reload

          expect(activity.hide_from_my_content).to be_truthy

          expect(response).to redirect_to(
            instructor_mycontent_url(
              display_lesson: lesson.id,
              program_id: program.id,
              start_unit: lesson.unit.rank,
              toc_location: strand.location
            )
          )
          expect(flash[:notice]).to match(/has been deleted/)
        end

        context 'when the hide_from_my_content param is not set,' do
          it 'redirects to the first page of My Content if from_my_content ' \
             'param is true' do
            put(
              target_path,
              params: composition_update_params.deep_merge(
                from_my_content: 'true',
                instructor_created_activity: { hide_from_my_content: nil },
                popup: false
              )
            )

            expect(response).to redirect_to(
              instructor_mycontent_url(
                program_id: program.id,
                selected_lesson_ids: lesson.id,
                selected_strands: strand.title,
                filtered: true,
                page: default_page
              )
            )
            expect(flash[:notice]).to match(/has been updated/)
          end
        end

        it 'redirects to the edit assessment when assessment json is specified' do
          assessment_strand = create(:assessment_toc_entry)
          lesson.toc_entries = [strand, assessment_strand]
          lesson.save!
          assessment_concept = create(
            :concept_for_quiz,
            id: assessment_strand.location,
            lesson: lesson
          )
          original_assessment = create(
            :activity,
            concept: assessment_concept,
            lesson: lesson,
            toc_location: assessment_strand.location
          )

          # Stub the call to retrieve activity xml from s3 bucket so the
          # assessment can be copied.
          allow(Activity).to receive(:filepath_from_revision_id)
            .and_return(File.join('spec', 'fixtures', 'xml', 'exam.xml'))

          copied_assessment_id = AssessmentCopier.new(
            original_assessment.id, instructor.id
          ).copy.created_activity.id

          content_json = File.read(
            'spec/fixtures/instructor_created_activity_content.json'
          )
          assessment_target_path = instructor_created_activity_path(
            id: copied_assessment_id,
            lesson_id: lesson.id,
            program_id: program.id,
            toc_entry_id: assessment_strand.location
          )
          new_title = 'new asssessment title'

          put(
            assessment_target_path,
            params: {
              from_my_content: 'false',
              instructor_created_activity: {
                content_json: content_json,
                hide_from_my_content: nil,
                title: new_title,
                save_action: 'save'
              },
              popup: false
            }
          )

          copied_assessment = Activity.find(copied_assessment_id)
          expect(response).to redirect_to(
            edit_instructor_created_activity_path(
              {
                lesson_id: copied_assessment.lesson_id,
                toc_entry_id: copied_assessment.toc_location,
                program_id: copied_assessment.program.id,
                id: copied_assessment
              }
            )
          )
          expect(flash[:notice]).to match(/has been updated/)

          # Just calling .reload isn't sufficient because it
          # doesn't clear instance variables, which hold stale information.
          new_activity = InstructorCreatedActivity.find(copied_assessment_id)

          expect(new_activity.title).to eq(new_title)
          expect(new_activity.content_json).to eq(content_json)
        end
      end
    end
  end

  describe 'POST /share' do
    let(:activity) do
      InstructorCreatedActivity.create!(
        original_composition_attrs.merge(
          activity_type: 'composition',
          instructor_id: instructor.id,
          language_code: program.language_code,
          lesson: lesson,
          references: original_references_params,
          toc_entry_id: strand.location
        )
      )
    end

    def do_request
      put(
        instructor_focus_path(program_id: program.id),
        params: { focus: "Course,#{course.id}", return_to: '' }
      )
      post(
        instructor_share_activity_path(
          id: activity.id,
          lesson_id: lesson.id,
          program_id: program.id,
          toc_entry_id: strand.location
        )
      )
    end

    it 'does not allow non-owner to share' do
      non_owner_instructor = create(:instructor)
      best_default_path = BestDefaultPath.best_default_path(non_owner_instructor, program, nil, {})
      log_in_user_with_access_to_programs(non_owner_instructor, [program])

      do_request

      expect(flash[:error]).to eq(Instructor::CreatedActivitiesController::NOT_AUTHORIZED_MESSAGE)
      expect(response).to redirect_to(best_default_path)
    end

    it 'does not allow sharing if the school has disabled sharing content' do
      disable_sharing_by_school(course)
      log_in_user_with_access_to_programs(instructor, [program])
      do_request
      expect(response).to redirect_to(instructor_mycontent_path(program.id))
      expect(flash[:warning]).to eq(content_sharing_disabled_msg)
    end

    it 'does not allow sharing if school has disabled sharing content for the program' do
      disable_sharing_by_program(course)
      log_in_user_with_access_to_programs(instructor, [program])
      do_request
      expect(response).to redirect_to(instructor_mycontent_path(program.id))
      expect(flash[:warning]).to eq(content_sharing_disabled_msg)
    end

    it 'allows the owner of the activity to share' do
      log_in_user_with_access_to_programs(instructor, [program])

      do_request
      expect(flash[:notice]).to eq(
        'Your activity is now shared with other instructors within your schools.'
      )
      expect(do_request).to redirect_to(
        instructor_mycontent_path(program.id)
      )
    end

    it 'creates a new shared library activity record for every school' do
      instructor.schools = create_list(:school, 3)

      log_in_user_with_access_to_programs(instructor, [program])
      do_request

      shared_activities = SharedLibraryActivity.where(
        source_activity_id: activity.id,
        school_id: instructor.schools.map(&:id)
      )
      expect(shared_activities.count).to eq(3)
    end
  end

  describe 'POST /set_private' do
    let(:activity) do
      InstructorCreatedActivity.create!(
        original_composition_attrs.merge(
          activity_type: 'composition',
          instructor_id: instructor.id,
          language_code: program.language_code,
          lesson: lesson,
          references: original_references_params,
          toc_entry_id: strand.location
        )
      )
    end

    let(:schools) do
      create_list(:school, 2)
    end

    def do_request
      put(
        instructor_focus_path(program_id: program.id),
        params: { focus: "Course,#{course.id}", return_to: '' }
      )
      post(
        instructor_set_private_path(
          id: activity.id,
          lesson_id: lesson.id,
          program_id: program.id,
          toc_entry_id: strand.location
        )
      )
    end

    it 'does not allow non-owner to stop sharing activities' do
      non_owner_instructor = create(:instructor)
      best_default_path = BestDefaultPath.best_default_path(non_owner_instructor, program, nil, {})
      log_in_user_with_access_to_programs(non_owner_instructor, [program])

      do_request

      expect(flash[:error]).to eq(Instructor::CreatedActivitiesController::NOT_AUTHORIZED_MESSAGE)
      expect(response).to redirect_to(best_default_path)
    end

    it 'does not allow to set the activity private if the school has disabled sharing content' do
      disable_sharing_by_school(course)
      log_in_user_with_access_to_programs(instructor, [program])
      do_request
      expect(response).to redirect_to(instructor_mycontent_path(program.id))
      expect(flash[:warning]).to eq(content_sharing_disabled_msg)
    end

    it 'does not allow to set the activity private if the school has disabled sharing content for the program' do
      disable_sharing_by_program(course)
      log_in_user_with_access_to_programs(instructor, [program])
      do_request
      expect(response).to redirect_to(instructor_mycontent_path(program.id))
      expect(flash[:warning]).to eq(content_sharing_disabled_msg)
    end

    it 'allows the owner of the activity to stop sharing the activity' do
      log_in_user_with_access_to_programs(instructor, [program])
      do_request
      expect(flash[:notice]).to eq(
        'Your activity has been set to private.'
      )
      expect(do_request).to redirect_to(
        instructor_mycontent_path(program.id)
      )
    end

    it 'it removes all shared library activity records for the activity' do
      instructor.schools = schools

      schools.map do |school|
        SharedLibraryActivity.create!(
          source_activity_id: activity.id,
          school_id: school.id,
          is_shared: true
        )
      end
      log_in_user_with_access_to_programs(instructor, [program])
      expect { do_request }.to change(SharedLibraryActivity, :count).by(-2)
    end
  end

  describe 'GET /edit' do
    let(:activity) do
      InstructorCreatedActivity.create!(
        original_composition_attrs.merge(
          activity_type: 'composition',
          instructor_id: instructor.id,
          language_code: program.language_code,
          lesson: lesson,
          references: original_references_params,
          toc_entry_id: strand.location
        )
      )
    end

    def do_request
      get(
        edit_instructor_created_activity_path(
          id: activity.id,
          lesson_id: lesson.id,
          program_id: program.id,
          toc_entry_id: strand.location
        )
      )
    end

    it 'does not allow non-owner to edit' do
      non_owner_instructor = create(:instructor)
      best_default_path = BestDefaultPath.best_default_path(non_owner_instructor, program, nil, {})
      log_in_user_with_access_to_programs(non_owner_instructor, [program])

      do_request

      expect(flash[:error]).to eq(Instructor::CreatedActivitiesController::NOT_AUTHORIZED_MESSAGE)
      expect(response).to redirect_to(best_default_path)
    end

    it 'allows the owner of the activity to edit' do
      log_in_user_with_access_to_programs(instructor, [program])

      do_request

      expect(response).to render_template(:edit)
    end
  end
end
