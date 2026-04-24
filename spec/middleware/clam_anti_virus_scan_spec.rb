describe ClamAntiVirusScan do
  include FakeFS::SpecHelpers

  before do
    FakeFS::FileSystem.add 'tmp'
  end

  def new_virus_file(filename = 'virus.txt')
    file_path = File.join('tmp', filename)
    virus_body = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$' + 'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
    File.open(file_path, 'w') { |f| f.write virus_body }
    file_path
  end

  def new_clean_file(filename = 'novirus.txt')
    file_path = File.join('tmp', filename)
    File.open(file_path, 'w') { |f| f.write 'ok' }
    file_path
  end

  describe "a new virus scan instance" do
    it "should require a file to scan" do
      expect{ ClamAntiVirusScan.new(nil) }.to raise_error "A file to scan must be specified."
      expect{ ClamAntiVirusScan.new('')  }.to raise_error "A file to scan must be specified."
    end

    it "should require that the specified file to be scanned exists" do
      file = File.join('tmp', 'no_such_file.txt')
      File.unlink(file) if File.exist?(file)
      expect{ ClamAntiVirusScan.new(file) }.to raise_error "Specified file '#{file}' does not exist."
    end

    context "when an original filename is passed," do
      it "should expose the original file" do
        scan = ClamAntiVirusScan.new(new_clean_file('tempfile.txt'), 'original.file')
        expect(scan.original_file).to eq('original.file')
      end
    end

    context "when no original filename is passed," do
      it "should return the tempfile filename as the original file" do
        scan = ClamAntiVirusScan.new(new_clean_file('tempfile.txt'), nil)
        expect(scan.original_file).to eq('tempfile.txt')
      end
    end

    context 'when the specified file is an mp3, ' do
      it 'does not run the scan' do
        expect_any_instance_of(ClamAntiVirusScan).not_to receive(:do_scan_and_parse_results)
        ClamAntiVirusScan.new(new_clean_file('file.mp3'))
      end

      it 'flags the file as clean' do
        expect(ClamAntiVirusScan.new(new_clean_file('file.mp3'))).to be_clean
      end
    end

    context 'when the specified file is an mp4,' do
      it 'does not run the scan' do
        expect_any_instance_of(ClamAntiVirusScan).not_to receive(:do_scan_and_parse_results)
        ClamAntiVirusScan.new(new_clean_file('file.mp4'))
      end

      it 'flags the file as clean' do
        expect(ClamAntiVirusScan.new(new_clean_file('file.mp4'))).to be_clean
      end
    end

    context "when detecting fake files is enabled," do
      context "when a file has no virus," do
        context "when a scanned file has base filename 'virus' with any extension" do
          it "should be flagged as infected" do
            expect(ClamAntiVirusScan.new(new_clean_file('virus.txt'))).to be_infected
            expect(ClamAntiVirusScan.new(new_clean_file('virus.anything'))).to be_infected
          end

          it "should report a pre-defined detected virus name" do
            scan = ClamAntiVirusScan.new(new_clean_file('virus.txt'))
            expect(scan.virus_name).to eq('Virus.Based.0N.Filename')
          end
        end

        context "when base filename of scanned file is not 'virus'" do
          it "should be flagged as clean" do
            expect(ClamAntiVirusScan.new(new_clean_file('random_name.txt'))).to be_clean
            expect(ClamAntiVirusScan.new(new_clean_file('novirus.anything'))).to be_clean
            expect(ClamAntiVirusScan.new(new_clean_file('virus_is_not_here.jpg'))).to be_clean
          end
        end
      end

      context "when a file has a virus," do
        it "should be flagged as infected no matter what the base filename is" do
          if ClamAntiVirusScan.enabled
            expect(ClamAntiVirusScan.new(new_virus_file('virus.txt'))).to be_infected
            expect(ClamAntiVirusScan.new(new_virus_file('random_name.txt'))).to be_infected
          end
        end
      end
    end

    context "when detecting fake files is not enabled," do
      around do |example|
        ClamAntiVirusScan.detect_fakes = false
        example.run
        ClamAntiVirusScan.detect_fakes = true
      end

      context "when the specified file has no virus," do
        it "should be flagged as clean and report no detect virus name" do
          if ClamAntiVirusScan.enabled
            scan = ClamAntiVirusScan.new(new_clean_file)
            expect(scan).to be_clean
            expect(scan).not_to be_infected
            expect(scan.virus_name).to be_nil
          end
        end

        it "should be flagged as clean even if the specified file has a base filename of 'virus'" do
          if ClamAntiVirusScan.enabled
            expect(ClamAntiVirusScan.new(new_clean_file('virus.txt'))).to be_clean
          end
        end
      end

      context "when the specified file has a virus," do
        it "should be flagged as infected and report the detected virus name" do
          if ClamAntiVirusScan.enabled
            scan = ClamAntiVirusScan.new(new_virus_file)
            expect(scan).not_to be_clean
            expect(scan).to be_infected
            expect(scan.virus_name).to eq('Eicar-Test-Signature')
          end
        end
      end
    end

  end

  describe "#clean?" do
    before do
      @old_value = ClamAntiVirusScan.enabled
      ClamAntiVirusScan.enabled = false
    end

    after do
      ClamAntiVirusScan.enabled = @old_value
    end

    it "should return true when scan state is :clean" do
      scan = ClamAntiVirusScan.new(new_clean_file)
      allow(scan).to receive(:scan_state).and_return(:clean)
      expect(scan).to be_clean
    end

    it "should return false when scan state is :infected" do
      scan = ClamAntiVirusScan.new(new_clean_file)
      allow(scan).to receive(:scan_state).and_return(:infected)
      expect(scan).not_to be_clean
    end

    it "should return false when scan state is :not_parseable" do
      scan = ClamAntiVirusScan.new(new_clean_file)
      allow(scan).to receive(:scan_state).and_return(:not_parseable)
      expect(scan).not_to be_clean
    end
  end

end
