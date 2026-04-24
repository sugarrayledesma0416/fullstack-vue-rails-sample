describe ResourceUpdater do

  let(:user) { build_stubbed(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:resource) { build_stubbed(:resource) }
  let(:section) { build_stubbed(:section) }
  let(:unit) { build_stubbed(:unit, :program => program) }
  let(:default_params) { { :program_id => program.id, :id => resource.id } }
  let(:updater) { ResourceUpdater.new(user, default_params, resource) }
  let(:unit_label) { resource.program.unit_label.downcase }
  let(:instructor_settings) { build_stubbed(:instructor_resource_setting) }

  before do
    allow(Unit).to receive(:resource_only_unit_for_program).and_return(unit)
    default_params.merge!( {:resource => {} })
  end

  describe '#initialize' do
    it 'creates a new ResourceUpdater with the supplied user and params' do
      expect(updater.user).to eq(user)
      expect(updater.params).to eq(default_params)
      expect(updater.resource).to eq(resource)
    end
  end

  describe '#update' do

    before do
      allow(Resource).to receive(:find_by_id).and_return(resource)
      old_file_path = ""
      current_file_name = ""
    end

    context 'when unit options is set to no_unit' do
      before do
        default_params.merge!({:unit_options => 'no_unit' })
      end

      context 'when a resource unit exists' do
        it 'updates the resource with first_unit and last_unit' do
          expect(resource).to receive(:update).with( hash_including(  "last_#{unit_label}".to_sym => nil, "first_#{unit_label}".to_sym => unit.id ))
          updater.update
        end
      end

      context 'when a resource unit does not exist' do
        it 'updates the resource with first unit set to nil' do
          allow(Unit).to receive(:resource_only_unit_for_program).and_return(nil)
          expect(resource).to receive(:update).with( hash_including( "first_#{unit_label}".to_sym => nil ))
          updater.update
        end
      end
    end

    context 'when unit options is set to single_unit' do
      it 'updates the resource with last unit set to nil' do
        default_params.merge!( { :unit_options => 'single_unit'} )
        expect(resource).to receive(:update).with( hash_including( "last_#{unit_label}".to_sym => nil))
        updater.update
      end
    end

    context 'when file uploading is set to "needed"' do

      before do
        default_params.merge!( { :file_uploading => "needed" } )
      end

      context 'if uploaded file is blank' do
        it 'it sets file name to an empty string' do
          default_params.merge!( {:uploaded_file => ""})
          expect(resource).to receive(:update).with( hash_including( :file_name => "" ))
          updater.update
        end
      end

      context 'if uploaded file is not blank' do
        it 'sets the file name and file type' do
          file_params = { :file_name => 'blah', :file_type => 'blah type'}
          allow(updater).to receive(:process_uploaded_file).and_return(file_params)
          default_params.merge!( { :uploaded_file => 'fake_file'} )
          expect(resource).to receive(:update).with( hash_including( :file_name => file_params[:file_name], :file_type => file_params[:file_type] ))
          updater.update
        end
      end
    end

    context 'when file uploading is not set to "needed"' do
      it 'updates the resource without file name or file type' do
        default_params.merge!( {:file_uploading => "dismissed"} )
        expect(resource).not_to receive( :update ).with( hash_including(:file_name, :file_type) )
        updater.update
      end
    end

    context 'when upload is virus free' do
      before do
        allow(updater).to receive(:upload_is_virus_free?).and_return(true)
      end
      context 'when update attributes succeeds' do
        before do
          allow(resource).to receive(:update).and_return(true)
        end

        it 'finds the appropriate instructor setting' do
          expect(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).with(user.id, resource.id)
          updater.update
        end

        context 'when uploaded file is blank' do
          it 'keeps the old file' do
            default_params.merge!( {:uploaded_file => ""})
            expect(Resource).not_to receive(:dispose_file)
            expect(resource).not_to receive(:upload_file)
            updater.update
          end
        end

        context 'when uploaded file is not blank' do
          it 'deletes the old file and uploads the replacement' do
            allow(resource).to receive(:file_path).and_return('fake file path')
            file_params = { :file_name => 'blah', :file_type => 'blah type'}
            allow(updater).to receive(:process_uploaded_file).and_return(file_params)
            allow(resource).to receive(:upload_file)
            default_params.merge!( { :uploaded_file => 'fake_file', :file_uploading => 'needed' } )
            expect(resource).to receive(:dispose_file).with(resource.file_path)
            expect(resource).to receive(:upload_file).with( "fake_file" )
            updater.update
          end
        end

        context 'when instructor settings are present' do
          before do
            allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).and_return(instructor_settings)
          end

          it 'sets visibility to shown if resource student visibility is set to true' do
            default_params.merge!( { resource_student_visibility: 'true' } )
            expect(instructor_settings).to receive(:update).with(hash_including(student_visibility: 'shown'))
            updater.update
          end

          it 'sets visibility to hidden if resource student visibility is set to false' do
            expect(instructor_settings).to receive(:update).with(hash_including(student_visibility: 'hidden'))
            updater.update
          end
        end

        context 'when instructor settings are not present but resource student visibility is' do
          before do
            allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).and_return(nil)
          end

          it 'creates a new InstructorResourceSetting' do
            default_params.merge!( { resource_student_visibility: 'true' } )
            expect(InstructorResourceSetting).to receive(:new).and_return(instructor_settings)
            expect(instructor_settings).to receive(:save)
            updater.update
          end

        end

        it 'returns true when successful? is called' do
          updater.update
          expect(updater.successful?).to eq(true)
        end

      end

      context 'and update attributes fails' do
        before do
          allow(resource).to receive(:update).and_return(false)
        end

        it 'keeps the old file' do
          expect(Resource).not_to receive(:dispose_file)
          expect(resource).not_to receive(:upload_file)
          updater.update
        end

        it 'returns false when successful? is called' do
          updater.update
          expect(updater.successful?).to eq(false)
        end

      end
    end

    context 'when upload is not virus free' do
      before do
        allow(updater).to receive(:upload_is_virus_free?).and_return(false)
      end

      it 'keeps the old file' do
        expect(Resource).not_to receive(:dispose_file)
        expect(resource).not_to receive(:upload_file)
        expect(resource).not_to receive(:save)
        updater.update
      end

      it 'should return false when successful? is called' do
        updater.update
        expect(updater.successful).to eq(false)
      end
    end

    context 'when user is not a resource editor' do
      it 'cannot update the overall student visibility of the resource' do
        default_params[:resource_student_visibility] = 'true'
        expect(resource).not_to receive(:update).with(hash_including(vhl_student_resource: true))
        updater.update
      end
    end

    context 'when user is a resource editor' do
      it 'updates the overall student visibility of the resource' do
        allow(user).to receive(:is_resource_editor?).and_return(true)
        default_params[:resource_student_visibility] = 'true'
        expect(resource).to receive(:update).with(hash_including(vhl_student_resource: true))
        updater.update
      end
    end

  end

  describe '#old_file_path' do
    context 'when file upload is needed and there is an uploaded file' do
      it 'returns the existing resource file path' do
        allow(updater).to receive(:needs_uploading?).and_return(true)
        allow(updater).to receive(:uploaded_file?).and_return(true)
        expect(updater.old_file_path).to eq(resource.file_path)
      end
    end

    context 'when the file uploaded needed and there is not an uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(true)
        allow(updater).to receive(:uploaded_file?).and_return(false)
        expect(updater.old_file_path).to eq('')
      end
    end

    context 'when file uploaded is not needed and there is an uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(false)
        allow(updater).to receive(:uploaded_file?).and_return(true)
        expect(updater.old_file_path).to eq('')
      end
    end

    context 'when file uploaded is not needed and there is not uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(false)
        allow(updater).to receive(:uploaded_file?).and_return(false)
        expect(updater.old_file_path).to eq('')
      end
    end
  end

  describe '#current_file_name' do
    context 'when file upload is needed and there is no uploaded file' do
      it 'returns the existing resource file name' do
        allow(updater).to receive(:needs_uploading?).and_return(true)
        allow(updater).to receive(:uploaded_file?).and_return(false)
        expect(updater.current_file_name).to eq(resource.file_name)
      end
    end

    context 'when file uploaded is needed and there is an uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(true)
        allow(updater).to receive(:uploaded_file?).and_return(true)
        expect(updater.current_file_name).to eq('')
      end
    end

    context 'when file uploaded is not needed and there no uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(false)
        allow(updater).to receive(:uploaded_file?).and_return(false)
        expect(updater.current_file_name).to eq('')
      end
    end

    context 'when file uploaded is not needed and there is an uploaded file' do
      it 'returns an empty string' do
        allow(updater).to receive(:needs_uploading?).and_return(false)
        allow(updater).to receive(:uploaded_file?).and_return(true)
        expect(updater.current_file_name).to eq('')
      end
    end
  end

  describe '#needs_uploading?' do
    context 'when file_uploading is needed' do
      it 'returns true' do
        params = { :file_uploading => 'needed' }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.needs_uploading?).to be_truthy
      end
    end

    context 'when file uploading is not needed' do
      it 'returns false' do
        params = { :file_uploading => 'not needed' }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.needs_uploading?).to be_falsey
      end
    end
  end

  describe '#uploaded_file?' do
    context 'when there is an uploaded file' do
      it 'returns true' do
        params = { :uploaded_file => 'something' }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.uploaded_file?).to be_truthy
      end
    end

    context 'when there is not an uploaded file' do
      it 'returns false' do
        params = { :uploaded_file => nil }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.uploaded_file?).to be_falsey
      end
    end
  end

  describe '#visible_to_students?' do
    context 'when resource student visibility is set to "true"' do
      it 'returns true' do
        params = { resource_student_visibility: 'true' }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.visible_to_students?).to be_truthy
      end
    end

    context 'when resource student visibility not set to "true"' do
      it 'returns false' do
        params = { resource_student_visibility: 'false' }
        allow(updater).to receive(:params).and_return(params)
        expect(updater.visible_to_students?).to be_falsey
      end
    end

  end


  describe '#update_resource_attributes' do
    it 'updates the resource model' do
      params = { :resource => 'foo' }
      allow(updater).to receive(:params).and_return(params)
      expect(resource).to receive(:update).with(params[:resource])
      updater.update_resource_attributes
    end
  end

  describe '#swap_files' do
    it 'deletes the file at the specified file path and uploads the replacement' do
      expect(resource).to receive(:dispose_file)
      expect(resource).to receive(:upload_file)
      updater.swap_files("this is a file_path")
    end
  end

  describe '#update_instructor_resource_settings' do
    before do
      allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).and_return(instructor_settings)
    end
    context 'when an instructor resource setting exists' do
      it 'updates the existing instructor setting' do
        allow(instructor_settings).to receive(:present?).and_return(true)
        expect(updater).to receive(:update_student_visibility).with(instructor_settings)
        updater.update_instructor_resource_settings
      end
    end
    context 'when resource student visibility is defined' do
      it 'creates an instructor resource setting' do
        allow(instructor_settings).to receive(:present?).and_return(false)
        allow(updater).to receive(:visible_to_students?).and_return(true)
        expect(updater).to receive(:create_instructor_resource_setting)
        updater.update_instructor_resource_settings
      end
    end

    context 'when user is a resource editor' do
      it 'does not do anything' do
        allow(user).to receive(:is_resource_editor?).and_return(true)
        expect(InstructorResourceSetting).not_to receive(:find_by_user_id_and_resource_id)
        updater.update_instructor_resource_settings
      end
    end
  end

  describe '#update_student_visibility' do
    it 'updates visibility to shown if resource_student_visibility is set to true' do
      updater.params.merge!( { resource_student_visibility: 'true' } )
      expect(instructor_settings).to receive(:update).with(hash_including(student_visibility: 'shown'))
      updater.update_student_visibility(instructor_settings)
    end

    it 'updates visibility to hidden if resource_student_visibility not present' do
      expect(instructor_settings).to receive(:update).with( hash_including(:student_visibility => 'hidden'))
      updater.update_student_visibility(instructor_settings)
    end
  end



end
