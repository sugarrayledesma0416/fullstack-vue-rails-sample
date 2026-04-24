require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe ResourcesController do
  include ActionDispatch::TestProcess::FixtureFile

  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:unit_1) { program.units.first }
  let(:unit_2) { program.units[1] }
  let(:unit_3) { program.units.last }
  let(:virus_name) { 'my_bad_virus' }
  let(:infected_file_params) { { infected: 'true', virus_name: virus_name } }
  let(:original_resource_component) { create(:resource_component) }

  let(:default_return_to) do
    instructor_program_resources_path(program_id: program.id)
  end

  let(:original_attrs) do
    {
      description: 'original description',
      first_unit: unit_1.id,
      last_unit: unit_2.id,
      title: 'original title',
      resource_component_id: original_resource_component.id
    }
  end

  describe 'POST /create' do
    let(:original_upload) do
      fixture_file_upload('spec/fixtures/media_items/test.jpg', 'image/jpg')
    end

    let(:create_params) do
      {
        resource: original_attrs,
        return_to: default_return_to,
        unit_options: instructor_program_resources_path(
          program_id: program.id,
          start_unit_id: unit_1.id
        ),
        uploaded_file: original_upload
      }
    end

    let(:target_path) { create_resource_path(program_id: program.id) }

    def do_request
      post(target_path, params: create_params)
    end

    include_examples 'require instructor or grader with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :resource in the params' do
        expect { post(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: resource/
        )
      end

      it 'does not save a resource when invalid params are specified' do
        post(
          target_path,
          params: create_params.deep_merge(resource: { title: '' })
        )

        expect(assigns(:resource).errors.full_messages).to eq [
          'Title is required.'
        ]
        expect(Resource.count).to eq(0)
        expect(response).to render_template(:new)
      end

      it 'does not save a resource when a file infected with a virus ' \
         'is uploaded' do
        post(
          target_path,
          params: create_params.merge(uploaded_file: infected_file_params)
        )

        expect(flash[:error]).to match(/infected with the virus '#{virus_name}'/)
        expect(Resource.count).to eq(0)
        expect(response).to render_template(:new)
      end

      it 'creates a new instructor-uploaded resource record when valid ' \
         'params are specified and user is not a resource editor' do
        do_request

        resource = Resource.last

        expect(flash[:notice]).to match(/resource created/)
        expect(response).to redirect_to(
          instructor_program_resources_path(
            component_id: original_resource_component.id,
            page: 1,
            program_id: program.id,
            start_unit_id: unit_1.id
          )
        )

        # Verify that posted params were permitted and saved.
        expect(resource).to have_attributes(original_attrs)
        expect(resource.file_path).to end_with('test.jpg')

        # Verify non-posted attributes were set in the controller action.
        expect(resource).to have_attributes(
          end_unit_id: unit_2.id,
          file_type: 'Image',
          lesson_id: nil,
          owner_id: instructor.id,
          program_id: program.id,
          source: 'Instructor',
          start_unit_id: unit_1.id,
          uploaded: true,
          vhl_student_resource: false
        )
      end

      it 'creates a new VHL-created resource record when valid ' \
         'params are specified and user is a resource editor' do
        instructor.roles.create!(name: Role::RESOURCE_EDITOR)
        post(target_path, params: create_params.deep_merge(
            resource: { protected: 1 },
            resource_student_visibility: 'true'
          ))

        resource = Resource.last

        # Verify that posted params were permitted and saved.
        expect(resource).to have_attributes(original_attrs)
        expect(resource.file_path).to end_with('test.jpg')

        # Verify non-posted attributes were set in the controller action.
        expect(resource).to have_attributes(
          end_unit_id: unit_2.id,
          file_type: 'Image',
          lesson_id: nil,
          owner_id: nil,
          program_id: program.id,
          protected: true,
          source: 'VHL',
          start_unit_id: unit_1.id,
          uploaded: false,
          vhl_student_resource: true
        )
      end

      %w[Chapter Lesson Section Theme Module].each do |label|
        it "recognizes #{label} as an alias for start/end unit attrs" do
          program.update!(unit_label: label)

          post(
            target_path,
            params: create_params.merge(
              resource: original_attrs.except(:first_unit, :last_unit).merge(
                "first_#{label.downcase}": unit_1.id,
                "last_#{label.downcase}": unit_2.id
              )
            )
          )

          expect(Resource.last).to have_attributes(
            end_unit_id: unit_2.id,
            start_unit_id: unit_1.id
          )
        end
      end
    end
  end

  describe 'PUT /update' do
    let(:new_resource_component) { create(:resource_component) }

    let(:new_attrs) do
      {
        description: 'new description',
        first_unit: unit_2.id,
        last_unit: unit_3.id,
        title: 'new title',
        resource_component_id: new_resource_component.id
      }
    end

    let(:new_upload) do
      fixture_file_upload('spec/fixtures/media_items/test2.jpg', 'image/jpg')
    end

    let(:update_params) do
      {
        file_uploading: 'needed',
        resource: new_attrs,
        return_to: default_return_to,
        unit_options: instructor_program_resources_path(
          program_id: program.id,
          start_unit_id: unit_1.id
        ),
        uploaded_file: new_upload
      }
    end

    let(:previous_attrs) do
      original_attrs.merge(
        end_unit_id: unit_2.id,
        file_name: 'test.jpg',
        owner_id: instructor.id,
        program_id: program.id,
        source: 'Instructor',
        start_unit_id: unit_1.id,
        uploaded: true
      )
    end

    let(:resource) { create(:resource, previous_attrs) }

    let(:target_path) do
      update_resource_path(id: resource.id, program_id: program.id)
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :resource in the params' do
        expect { put(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: resource/
        )
      end

      it 'does not save a resource when invalid params are specified' do
        put(
          target_path,
          params: update_params.deep_merge(resource: { title: '' })
        )

        expect(assigns(:resource).errors.full_messages).to eq [
          'Title is required.'
        ]

        resource.reload
        expect(resource).to have_attributes(previous_attrs)
      end

      it 'does not save a resource when a file infected with a virus ' \
         'is uploaded' do
        put(
          target_path,
          params: update_params.merge(uploaded_file: infected_file_params)
        )

        expect(flash[:error]).to match(/infected with the virus '#{virus_name}'/)

        resource.reload
        expect(resource).to have_attributes(previous_attrs)
      end

      context 'with an instructor-uploaded resource' do
        it 'does not save changes if the user is not the resource owner' do
          other_instructor = create(:instructor)
          resource.update!(owner_id: other_instructor.id)

          do_request

          expect(flash[:error]).to match(/not authorized/)
          expect(response).to redirect_to(root_url)

          resource.reload
          expect(resource).to have_attributes(
            previous_attrs.merge(owner_id: other_instructor.id)
          )
        end

        it 'updates the resource record when valid params are specified ' \
           'and the user is the owner of the resource' do
          do_request

          resource.reload

          expect(flash[:notice]).to match(/changes.*were saved/)
          expect(response).to redirect_to(default_return_to)

          # Verify that posted params were permitted and saved.
          expect(resource).to have_attributes(new_attrs)
          expect(resource.file_path).to end_with('test2.jpg')

          # Verify non-posted attributes were set in the controller action.
          expect(resource).to have_attributes(
            end_unit_id: unit_3.id,
            file_type: 'Image',
            lesson_id: nil,
            owner_id: instructor.id,
            program_id: program.id,
            source: 'Instructor',
            start_unit_id: unit_2.id,
            uploaded: true,
            vhl_student_resource: false
          )
        end
      end

      context 'with a VHL-published resource' do
        let(:vhl_attrs) do
          {
            owner_id: nil,
            source: 'VHL',
            uploaded: false
          }
        end

        before do
          resource.update!(vhl_attrs)
        end

        it 'does not save changes if the user is not a resource editor' do
          do_request

          expect(flash[:error]).to match(/not authorized/)
          expect(response).to redirect_to(root_url)

          resource.reload
          expect(resource).to have_attributes(previous_attrs.merge(vhl_attrs))
        end

        it 'updates the resource record when valid params are specified ' \
           'and the user is a resource editor' do
          instructor.roles.create!(name: Role::RESOURCE_EDITOR)

          put(
            target_path,
            params: update_params.deep_merge(
              resource: { protected: 1 },
              resource_student_visibility: 'true'
            )
          )

          expect(flash[:notice]).to match(/changes.*were saved/)
          expect(response).to redirect_to(default_return_to)

          resource.reload

          # Verify that posted params were permitted and saved.
          expect(resource).to have_attributes(new_attrs)
          expect(resource.file_path).to end_with('test2.jpg')

          # Verify non-posted attributes were set in the controller action.
          expect(resource).to have_attributes(
            end_unit_id: unit_3.id,
            file_type: 'Image',
            lesson_id: nil,
            owner_id: nil,
            program_id: program.id,
            protected: true,
            source: 'VHL',
            start_unit_id: unit_2.id,
            uploaded: false,
            vhl_student_resource: true
          )
        end
      end

      %w[Chapter Lesson Section Theme Module].each do |label|
        it "recognizes #{label} as an alias for start/end unit attrs" do
          program.update!(unit_label: label)

          put(
            target_path,
            params: update_params.merge(
              resource: new_attrs.except(:first_unit, :last_unit).merge(
                "first_#{label.downcase}": unit_2.id,
                "last_#{label.downcase}": unit_3.id
              )
            )
          )

          expect(Resource.last).to have_attributes(
            end_unit_id: unit_3.id,
            start_unit_id: unit_2.id
          )
        end
      end
    end
  end

  describe 'GET /download_multiple' do
    let(:target_path) do
      download_multiple_resources_path(program_id: program.id)
    end
    let(:resource_file_name) { 'my_resource.pdf' }
    let!(:program_resource) do
      create(
        :resource,
        original_attrs.merge(
          file_name: resource_file_name,
          protected: false,
          vhl_student_resource: true,
          program:
        )
      )
    end
    let(:zip_streamer) do
      instance_double(ZipTricks::Streamer, write_deflated_file: nil, close: nil)
    end

    def do_request(custom_params = {})
      get(
        target_path,
        params: { selected_resources: [program_resource.id] }.merge(custom_params)
      )
    end

    before do
      allow(ZipTricks::Streamer).to receive(:new).and_return(zip_streamer)
    end

    include_examples 'require logged in user'
    include_examples 'require program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'downloads the selected resources' do
        do_request
        expect(zip_streamer).to have_received(:write_deflated_file).with(resource_file_name)
      end

      it 'makes sure the files in the zip file have a unique name' do
        other_resource_with_same_name = create(
          :resource,
          original_attrs.merge(file_name: resource_file_name, program:)
        )

        do_request(selected_resources: [program_resource.id, other_resource_with_same_name.id])
        expect(zip_streamer).to have_received(:write_deflated_file).once.with(resource_file_name)
        expect(zip_streamer).to have_received(:write_deflated_file).once.with('my_resource (1).pdf')
      end

      it 'does not include resources from another program' do
        other_resource_name = 'other_resource_name.pdf'
        other_program_resource = create(
          :resource,
          original_attrs.merge(
            file_name: other_resource_name,
            program: create(:program)
          )
        )

        do_request(selected_resources: [program_resource.id, other_program_resource.id])
        expect(zip_streamer).to have_received(:write_deflated_file).with(resource_file_name)
        expect(zip_streamer).not_to have_received(:write_deflated_file).with(other_resource_name)
      end

      it 'does not include protected resources, if user is a student' do
        student = create(:student)
        log_in_user_with_access_to_programs(student, [program])
        protected_resource_name = 'answer_keys.pdf'
        protected_resource = create(
          :resource,
          original_attrs.merge(
            file_name: protected_resource_name,
            protected: true,
            vhl_student_resource: true,
            program:
          )
        )
        instructor_resource_name = 'instructor_manual.pdf'
        instructor_resource = create(
          :resource,
          original_attrs.merge(
            file_name: instructor_resource_name,
            protected: false,
            vhl_student_resource: false,
            program:
          )
        )

        do_request(selected_resources: [program_resource.id, protected_resource.id])
        expect(zip_streamer).to have_received(:write_deflated_file).with(resource_file_name)
        expect(zip_streamer).not_to have_received(:write_deflated_file).with(protected_resource_name)
        expect(zip_streamer).not_to have_received(:write_deflated_file).with(instructor_resource_name)
      end
    end
  end
end
