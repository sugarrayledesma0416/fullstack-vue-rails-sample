require 'tasks/demo_data/data_file'

describe DemoData::DataFile do
  describe "#read" do
    it "calls File.read" do
      expect(File).to receive(:read).with('filepath')
      DemoData::DataFile.read('filepath')
    end
  end

  describe "#write" do
    it "writes contents to a file" do
      file = double(File)
      expect(File).to receive(:dirname).with('filepath').and_return('dirname')
      expect(FileUtils).to receive(:makedirs).with('dirname')
      expect(File).to receive(:open).with('filepath', 'w').and_yield(file)
      expect(file).to receive(:write).with('contents')
      DemoData::DataFile.write('filepath', 'contents')
    end
  end

  describe "#write_binary" do
    it "writes binary contents to a file" do
      file = double(File)
      expect(File).to receive(:dirname).with('filepath').and_return('dirname')
      expect(FileUtils).to receive(:makedirs).with('dirname')
      expect(File).to receive(:open).with('filepath', 'wb').and_yield(file)
      expect(file).to receive(:write).with('contents')
      DemoData::DataFile.write_binary('filepath', 'contents')
    end
  end

  describe "#cp" do
    it "copies a file, creating destination dirs" do
      expect(File).to receive(:dirname).with('dest_path').and_return('dirname')
      expect(FileUtils).to receive(:makedirs).with('dirname')
      expect(FileUtils).to receive(:cp).with('source_path', 'dest_path')
      DemoData::DataFile.copy('source_path', 'dest_path')
    end
  end

  describe "#delete_dir" do
    it "deletes a dir and all files and sub_dirs" do
      expect(File).to receive(:exist?).with('dirname').and_return(true)
      expect(File).to receive(:directory?).with('dirname').and_return(true)
      expect(FileUtils).to receive(:rm_r).with('dirname')
      DemoData::DataFile.delete_dir('dirname')
    end
  end

  describe "#download" do
    it "downloads a file from a remote location and saves it locally" do
      expect(File).to receive(:exist?).with('local_path').and_return(false)

      http = double(Net::HTTP)
      expect(Net::HTTP).to receive(:start).with('hostname').and_yield(http)

      resp = double('Response', :body => 'resp_body')
      expect(http).to receive(:get).with('remote_path').and_return(resp)
      expect(DemoData::DataFile).to receive(:write_binary).with('local_path', 'resp_body')

      DemoData::DataFile.download('hostname', 'remote_path', 'local_path')
    end
  end
end
