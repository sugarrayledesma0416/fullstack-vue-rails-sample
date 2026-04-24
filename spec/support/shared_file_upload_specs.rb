#encoding: utf-8

shared_examples_for "an action that uploads a virus-free file" do
  context "when a file is uploaded that is infected with a virus," do
      before do
        @virus_name = 'my_bad_virus'
        @infected_file_params = {'infected' => 'true', 'virus_name' => @virus_name}
      end

      it "should not save current instance" do
        expect(receiver).not_to receive(:save)
        do_request({ :uploaded_file => @infected_file_params })
      end

      it "should not upload the virus-infected file" do
        expect(receiver).not_to receive(:upload_file)
        do_request({ :uploaded_file => @infected_file_params })
      end

      it "should set a flash now error with the virus name" do
        expected_error = "Your file could not be uploaded because it seems to be infected with the virus '#{@virus_name}'"

        allow(controller.instance_eval { flash }).to receive(:sweep)
        do_request({ :uploaded_file => @infected_file_params })
        expect(flash[:error]).to eql expected_error
      end

      it "should re-render the form action" do
        do_request({ :uploaded_file => @infected_file_params })
        if controller.params[:action] == 'create'
          expect(response).to render_template(:new)
        elsif controller.params[:action] == 'update'
          expect(response).to render_template(:edit)
        end
      end
    end

    context "when a file is uploaded that is not infected with a virus," do
      before do
        @valid_file_upload = fixture_file_upload('/media_items/test.jpg', 'image/jpg')
      end

      it "should save the current instance" do
        if controller.params[:action] == 'create'
          expect(receiver).to receive(:save)
        elsif controller.params[:action] == 'update'
          expect(receiver).to receive(:update)
        end
        do_request({ :uploaded_file => @valid_file_upload })
      end

      it "should upload the file" do
        expect(receiver).to receive(:upload_file).with(@valid_file_upload)
        do_request({ :uploaded_file => @valid_file_upload })
      end

    end
end

shared_examples_for "an action that assigns allowed file extensions" do
  it "assigns a list of allowed file types" do
    expected_file_types = [double('file_type',:extension_name => 'asd'), double('file_type',:extension_name => 'fgh')]
    allow(FileType).to receive(:allowed).and_return(expected_file_types)
    do_request
    expect(assigns(:allowed_file_types)).to  eql 'asd,fgh'
  end
end

shared_examples_for "an object that sanitizes uploaded file names" do
  describe "#sanitize_file_name" do
    it "should convert nonPOSIX compatible chars" do
      receiver.file_name = "áéíóú"
      expected_string = "aeiou"
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end

    it "should remove the path before the filename" do
      receiver.file_name = "/folder_1/folder_2/folder_3/folder_4/file_name.ext"
      expected_string = "file_name.ext"
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end

    it "should convert invalid filename chars like ?/* into dashes" do
      receiver.file_name = "<>|:()&;#?*"
      expected_string = "-----------"
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end

    it "should convert blankspace chars into underscores" do
      receiver.file_name = " - "
      expected_string = "_-_"
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end

    it 'converts non-english chatrs to downcase' do
      receiver.file_name = 'Écrire'
      expected_string = 'ecrire'
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end

    it 'converts En Dash to a minus' do
      receiver.file_name = "leccion9#{8211.chr}outline.pdf"
      expected_string = 'leccion9-outline.pdf'
      receiver.save!
      expect(receiver.file_name).to eql expected_string
    end
  end
end

shared_examples_for "an object that has file presence validation methods" do
  describe "#has_file_name?" do
    it "returns true if file_name is set" do
      receiver.file_name = 'some.file'
      receiver.save
      expect(receiver).to have_file_name
    end

    it "returns false if file_name is not set" do
      receiver.file_name = ''
      receiver.save
      expect(receiver).not_to have_file_name
    end
  end

  describe "#has_file?" do

    it "returns false if file does not exists" do
      s3 = double(Radner::S3Storage, file_exist?: false)
      allow(receiver).to receive(:s3_bucket).and_return(s3)
      expect(receiver).not_to have_file
    end

    it "returns true when file_name is set and file exists" do
      receiver.file_name = 'some_file.txt' unless receiver.file_name.present?
      s3 = double(Radner::S3Storage, file_exist?: true)
      allow(receiver).to receive(:s3_bucket).and_return(s3)
      expect(receiver).to have_file
    end

  end
end

shared_examples_for 'an object that can read its related file data from an S3 bucket' do
  describe '#content_data' do
    it 'fetches the data for the related file_path' do
      s3 = double(Radner::S3Storage)
      allow(receiver).to receive(:s3_bucket).and_return(s3)
      expect(s3).to receive(:fetch).with(receiver.file_path)
      receiver.content_data
    end
  end

  describe '#file_size' do
    it 'returns the size of the uploaded file' do
      s3 = double(Radner::S3Storage)
      allow(receiver).to receive(:s3_bucket).and_return(s3)
      expected_file_size = 10000
      allow(s3).to receive(:content_length).with(receiver.file_path).and_return(expected_file_size)
      expect(receiver.file_size).to eql expected_file_size
    end
  end
end
