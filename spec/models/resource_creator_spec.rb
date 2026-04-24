describe ResourceCreator do

  let(:user) { build_stubbed(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:default_params) { { :program_id => program.id } }
  let(:creator) { ResourceCreator.new(user, default_params)  }
  let(:resource) { build_stubbed(:resource) }
  let(:unit) { build_stubbed(:unit) }
  let(:instructor_resource_setting) { build_stubbed(:instructor_resource_setting) }

  before do
    allow(user).to receive(:is_resource_editor?).and_return(false)
    allow(creator).to receive(:process_uploaded_file).and_return( {} )
    allow(creator).to receive(:upload_is_virus_free?).and_return(true)
    allow(resource).to receive(:save).and_return(true)
    allow(resource).to receive(:upload_file)
    allow(Resource).to receive(:new).and_return(resource)
    allow(Unit).to receive(:resource_only_unit_for_program).and_return(unit)
   end

  describe '#initialize' do
    it 'creates a new ResourceCreator with the supplied user and params' do
      expect(creator.user).to eq(user)
      expect(creator.params).to eq(default_params)
    end
  end

  describe '#create' do

    it 'returns self when ResourceCreator.create is called' do
      expect(creator.create).to eq(creator)
    end

    it 'creates a resource using the passed in resource and program_id params' do
      resource_params = { :title => 'abc' }
      expected_params = resource_params.merge(:program_id => program.id)
      expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
      default_params.merge!(:resource => resource_params)
      creator.create
    end

    context 'when the user is a resource editor' do
      before do
        allow(user).to receive(:is_resource_editor?).and_return(true)
      end

      it 'creates a resource with a source of VHL, uploaded false and nil owner_id' do
        expected_params = { :source => 'VHL', :uploaded => false, :owner_id => nil }
        expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
        default_params.merge!(expected_params)
        creator.create
      end

      it 'creates the resource as visible to students if the resource_student_visibility param is set to true' do
        expect(Resource).to receive(:new).with(hash_including(vhl_student_resource: true)).and_return(resource)
        default_params.merge!(resource_student_visibility: 'true')
        creator.create
      end
    end

    context 'when the user is not a resource editor' do
      before do
        allow(user).to receive(:is_resource_editor?).and_return(false)
      end

      it 'creates a resource with a source of Instructor, uploaded true and owner_id of user' do
        expected_params = { :source => 'Instructor', :uploaded => true, :owner_id => user.id }
        expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
        default_params.merge!(expected_params)
        creator.create
      end

      it 'creates the resource as not visible to all students even if the resource_student_visibility params is set' do
        expect(Resource).to receive(:new).with( hash_not_including(vhl_student_resource: true) ).and_return(resource)
        default_params.merge!(resource_student_visibility: true)
        creator.create
      end
    end

    context 'when unit_options params is set to no_unit' do
      before do
        default_params.merge!({:unit_options => 'no_unit'})
      end

      it 'looks for a resource-only unit for the current program' do
        expect(Unit).to receive(:resource_only_unit_for_program).with(program.id).and_return(unit)
        creator.create
      end

      context 'when a resource-only unit exists for the current program' do
        it 'creates a resource with a start_unit_id of the resource-only unit' do
          allow(Unit).to receive(:resource_only_unit_for_program).and_return(unit)
          expected_params = { :first_unit => unit.id }
          expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
          default_params.merge!(expected_params)
          creator.create
        end
      end

      context 'when unit_options params looks like a 2-tier program' do
        before do
          default_params.merge!({ :unit_options => 'lesson_id=15&start_unit_id=1' })
        end

        it 'creates a resource with a lesson id and start_unit_id' do
          expected_params = {
            lesson_id: '15',
            first_unit: '1'
          }
          expect(Resource)
            .to receive(:new)
            .with(hash_including(expected_params)).and_return(resource)
          creator.create
        end
      end

      context 'when no resource-only unit is found for the current program' do
        it 'creates a resource with a nil start_unit_id' do
          allow(Unit).to receive(:resource_only_unit_for_program).and_return(nil)
          expected_params = { :first_unit => nil }
          expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
          default_params.merge!(expected_params)
          creator.create
        end
      end
    end

    context 'when unit_options params is not set to no_unit' do
      it 'creates a resource with the start_unit_id specified in the resource params' do
        default_params.merge!({:unit_options => 'single_unit'})
        allow(Unit).to receive(:resource_only_unit_for_program).and_return(unit)
        expected_start_unit_id = (unit.id + 1)
        expected_params = { :first_unit => expected_start_unit_id }
        expect(Resource).to receive(:new).with( hash_including(expected_params) ).and_return(resource)
        default_params.merge!( :resource => expected_params )
        creator.create
      end
    end

    it 'calls process_uploaded_file, speciying the uploaded_file param' do
      uploaded_file =  "this is my file"
      expect(creator).to receive(:process_uploaded_file).with( uploaded_file ).and_return( {} )
      default_params.merge!(:uploaded_file => uploaded_file)
      creator.create
    end

    it 'creates a resource with the results of the process_uploaded_file call' do
      results = { :some => :results }
      allow(creator).to receive(:process_uploaded_file).and_return( results )
      expect(Resource).to receive(:new).with( hash_including(results) ).and_return(resource)
      creator.create
    end

    context 'when no virus is detected' do
      before do
        allow(creator).to receive(:upload_is_virus_free?).and_return(true)
      end

      it 'saves the created resource' do
        expect(resource).to receive(:save).and_return(true)
        creator.create
      end

      context 'when saving the resource is successful' do
        it 'calls upload_file on the resource specifying the uploaded_file param' do
          allow(resource).to receive(:save).and_return(true)
          fake_uploaded_file = 'string pretending to be a file'
          default_params.merge!(:uploaded_file => fake_uploaded_file)
          expect(resource).to receive(:upload_file).with(fake_uploaded_file)
          creator.create
        end
      end

      context 'when saving the resource fails' do
        it 'does not call uplad_file on the resource' do
          allow(resource).to receive(:save).and_return(false)
          expect(resource).not_to receive(:upload_file)
          creator.create
        end
      end


    end

    context 'when the uploaded_file params file is infected with a virus' do
      it 'does not save the created resource' do
        allow(creator).to receive(:upload_is_virus_free?).and_return(false)
        expect(resource).not_to receive(:save)
        creator.create
      end
    end

    it 'assigns the created resource' do
      allow(Resource).to receive(:new).and_return(resource)
      creator.create
      expect(creator.resource).to eq(resource)
    end

    context 'when resource_student_visibility param is specified as true' do
      it 'creates a instructor_resource_setting with current user and visibility of shown' do
        default_params.merge!(resource_student_visibility: 'true')
        expected_attrs = { user_id: user.id, student_visibility: 'shown' }
        expect(resource.instructor_resource_settings).to receive(:create).with( hash_including(expected_attrs))
        creator.create
      end
    end

    context 'when resource_student_visibility param is specified as false' do
      it 'does not create an instructor_resource setting' do
        expect(resource.instructor_resource_settings).not_to receive(:create)
        creator.create
      end
    end

    context 'when resource_student_visibility is specified as an empty string' do
      it 'does not create an instructor_resource setting' do
        default_params.merge!(:resource_student_visibility => '')
        expect(resource.instructor_resource_settings).not_to receive(:create)
        creator.create
      end
    end


  end

  describe '#successful?' do

    it 'returns true if the resource has been created successfully' do
      allow(resource).to receive(:save).and_return(true)
      creator.create
      expect(creator).to be_successful
    end

    it 'returns false if the resource has not been created' do
      allow(resource).to receive(:save).and_return(false)
      creator.create
      expect(creator).not_to be_successful
    end

    it 'returns false if a virus is detected but the resource has no errors' do
      allow(creator).to receive(:upload_is_virus_free?).and_return(false)
      allow(resource).to receive(:save).and_return(true)
      creator.create
      expect(creator).not_to be_successful
    end

  end



end
