require 'media_item'

describe Unzippable do
  include FakeFS::SpecHelpers

  before do
    FakeFS::FileSystem.add '/tmp'
    FakeFS::FileSystem.add Rails.root
    Dir.chdir Rails.root
  end

  describe "#unzip_with_subdirs" do
    def create_payload_zipfile(subdirs = '')

      zip_filename = '/tmp/spec_test.vocab_group.zip'
      File.unlink(zip_filename) if File.exist?(zip_filename)

      Zip::File.open(zip_filename, Zip::File::CREATE) do |zip|
        unless subdirs.blank?
          path = subdirs.dup
          stack = []
          until path == stack.last
            stack.push path
            path = File.dirname(path)
          end
          stack.reverse_each do |path|
            zip.mkdir(path)
          end
        end
        subdirs << '/' unless subdirs.blank?

        master_csv_string =  "Literatura,header.mp3,group\n" +
                              "el alma,soul,soul.mp3"
        zip.get_output_stream("#{subdirs}master.csv") {|file| file.write(master_csv_string)}
        zip.get_output_stream("#{subdirs}header.mp3") {|file| file.write("header")}
        zip.get_output_stream("#{subdirs}soul.mp3")   {|file| file.write("soul")}
      end

      File.read(zip_filename)
    end

    before(:each) do
      @media_item = MediaItem.new(:filename => 'test.vocab_group.zip', :media_type => 'vocab_group')
      @media_item.id = 101010
      @media_item.save!
      @media_dir = File.join(File.dirname(@media_item.full_filename), '1010')
    end

    context "when an extracted file already exists in the media item directory," do
      it "should replace the existing file with a newly extracted file from the zip" do
        target_file = File.join(@media_dir, 'soul.mp3')

        FileUtils.mkdir_p @media_dir
        File.open(target_file, 'w') {|f| f.write('old_soul') }

        @media_item.payload = create_payload_zipfile

        expect(File.exist?(target_file)).to be_truthy
        expect(File.read(target_file)).to eql 'soul'
      end
    end

    context "when the zip file contains no directory structure," do
      before(:each) do
        @media_item.payload = create_payload_zipfile
      end

      it "should extract the csv file from the zip file" do
        expect(File.exist?(File.join(@media_dir, 'master.csv'))).to be_truthy
      end

      it "should extract any mp3 files from the zip file" do
        expect(File.exist?(File.join(@media_dir, 'header.mp3'))).to be_truthy
        expect(File.exist?(File.join(@media_dir, 'soul.mp3'))).to be_truthy
      end
    end

    context "when the zip file contains subdirectories," do
      it "should not extract the directories" do
        @media_item.payload = create_payload_zipfile(subdirs = 'subdir1')
        expect(File.exist?(File.join(@media_dir, 'subdir1'))).to be_falsey
      end

      it "should flatten the directory structure when extracting the files" do
        @media_item.payload = create_payload_zipfile(subdirs = 'subdir1/subdir2')
        expect(File.exist?(File.join(@media_dir, 'master.csv'))).to be_truthy
        expect(File.exist?(File.join(@media_dir, 'header.mp3'))).to be_truthy
        expect(File.exist?(File.join(@media_dir, 'soul.mp3'))).to be_truthy
      end

      it "should ignore files inside directories named __MACOSX" do
        @media_item.payload = create_payload_zipfile(subdirs = '__MACOSX')
        expect(File.exist?(File.join(@media_dir, 'master.csv'))).to be_falsey
        expect(File.exist?(File.join(@media_dir, 'header.mp3'))).to be_falsey
        expect(File.exist?(File.join(@media_dir, 'soul.mp3'))).to be_falsey
      end
    end
  end

  describe "#unzip_without_subdirs" do
    before(:each) do
      @files = ['file1.jpg', 'file2.mp3']
      tutorial_zip_file = create_zipfile(subdirs = 'subdir', file_list = @files)
      @tutorial_zip_contents = File.read(tutorial_zip_file)

      @media_item = MediaItem.new(:filename => 'tutorial_vocab.zip', :media_type => 'vocab_tutorial')
      @media_item.id = 101010
      @media_item.save!
      @media_dir = File.join(File.dirname(@media_item.full_filename), '1010')
    end

    context "when an extracted file already exists in the media item directory," do
      it "should replace the existing file with a newly extracted file from the zip" do
        @media_item.payload = @tutorial_zip_contents

        target_file = File.join(@media_dir, 'subdir', 'file1.jpg')
        File.open(target_file, 'w') {|f| f.write('old_version_contents') }

        file_contents = File.read(target_file)
        expect(file_contents).to eql 'old_version_contents'

        @media_item.payload = @tutorial_zip_contents
        file_contents = File.read(target_file)
        expect(file_contents).not_to eql 'old_version_contents'
      end
    end

    it "should unzip all files, preserving directory structure" do
      @media_item.payload = @tutorial_zip_contents
      ['file1.jpg', 'file2.mp3'].each do |file|
        target_file = File.join(@media_dir, 'subdir', file)
        expect(File.exist?(target_file)).to be_truthy
      end
    end

    it "should create symlinks to the unzip directory for the player swf files" do
      @media_item.payload = @tutorial_zip_contents

      players = ['cloader', 'contextos', 'dragndropimage', 'dragndropwords', 'matching', 'multiplechoice', 'vocabtetris']
      players.each do |player|
        player_filename = "#{player}.swf"
        player_path = Rails.root.join('public', 'players', player_filename)
        player_link = File.join(@media_dir, player_filename)
        expect(File.symlink?(player_link)).to be_truthy

        expect(File.readlink(player_link)).to eql(player_path.to_s)
      end
    end
  end
end
