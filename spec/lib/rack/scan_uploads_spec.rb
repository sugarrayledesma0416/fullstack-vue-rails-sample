require 'clam_anti_virus_scan'

describe ScanUploads do
  include FakeFS::SpecHelpers

  require 'rack/mock'
  require 'rack/test'

  before do
    FakeFS::FileSystem.add File.join(Rails.root, 'tmp')
    FakeFS::FileSystem.add '/tmp' # need this for rack tempfiles
    @downstream_app = lambda do |env|
      [200, { 'Content-Type' => 'text/plain' }, Rack::Request.new(env)]
    end
  end

  def do_request(env)
    status, headers, response = ScanUploads.new(@downstream_app).call(env)
    response
  end

  def new_uploaded_file(filename = 'file.txt')
    file_path = File.join(Rails.root, 'tmp', filename)
    File.open(file_path, 'w+') { |f| f.write 'contents' }
    Rack::Multipart::UploadedFile.new(file_path, 'text/plain')
  end

  it 'should not scan GET requests' do
    query_params = { 'foo' => 'bar' }
    env = Rack::MockRequest.env_for '/', method: 'GET', params: query_params
    response = do_request(env)
    expect(response.env.keys).not_to include 'scanned'
  end

  it 'should not scan POST requests if the content-type is not a form' do
    post_params = { 'foo' => 'bar' }
    env = Rack::MockRequest.env_for '/', method: 'POST', params: post_params
    env["CONTENT_TYPE"] = 'text/plain'

    response = do_request(env)
    expect(response.env.keys).not_to include 'scanned'
  end

  it 'should not scan POST requests without a multipart form' do
    post_params = { 'foo' => 'bar' }
    env = Rack::MockRequest.env_for '/', method: 'POST', params: post_params
    response = do_request(env)
    expect(response.env.keys).not_to include 'scanned'
  end

  context 'when a multipart form is posted,' do
    let(:file) { new_uploaded_file('no_virus.txt') }

    before do
      allow(ClamAntiVirusScan).to receive(:new)
        .and_return(double(ClamAntiVirusScan, :infected? => false))
    end

    it 'should scan and add a scanned header if the form has a file ' \
       'upload as the only param' do
      params = { 'file' => file }

      env = Rack::MockRequest.env_for '/', method: 'POST', params: params
      response = do_request(env)
      expect(response.env.keys).to include 'scanned'
    end

    it 'should not lose params' do
      params = { 'file' => file, 'other_key' => 'other_value' }
      env = Rack::MockRequest.env_for '/', method: 'POST', params: params

      response = do_request(env)
      expect(response.params['other_key']).to eq('other_value')
    end

    it 'should scan and add a scanned header if the form has a file upload ' \
       'as a deeply nested param' do
      params = {
        'object' => {
          'subobject' => {
            'subsubobject' => {
              'bottomobject' => {
                'file' => file,
                'name' => 'xyz'
              }
            }
          }
        }
      }

      env = Rack::MockRequest.env_for '/', method: 'POST', params: params
      response = do_request(env)
      expect(response.env.keys).to include 'scanned'
    end
  end

  context 'when there are multiple uploaded files in the same POST request,' do
    let(:file_1) { new_uploaded_file('file1.txt') }
    let(:file_2) { new_uploaded_file('file2.txt') }

    it 'should find and scan all uploaded files' do
      params = {
        'multiple_files' => {
          'file1' => file_1,
          'buried_file_root' => {
            'buried_file_node' => {
              'buried_file' => file_2
            }
          }
        }
      }

      env = Rack::MockRequest.env_for '/', method: 'POST', params: params

      clean_scan = double(ClamAntiVirusScan, :infected? => false)
      expect(ClamAntiVirusScan).to receive(:new).twice.and_return(clean_scan)
      response = do_request(env)
    end
  end

  context "when a virus is uploaded" do
    let(:filename) { 'virus.txt' }
    let(:virus_name) { 'Detect3d!V1rus.31' }
    let(:infected_file_replacement) { { 'infected' => 'true', 'filename' => filename, 'virus_name' => virus_name } }
    let(:file) { new_uploaded_file(filename) }

    before do
      scan = double(ClamAntiVirusScan, :infected? => true, :file => filename, :virus_name => virus_name, :original_file => 'virus.txt')
      allow(ClamAntiVirusScan).to receive(:new).and_return(scan)
    end

    it "should return params with the infected file replaced" do
      params = {'file' => file}
      env = Rack::MockRequest.env_for '/', { method: "POST", params: params }

      response = do_request(env)
      expect(response.params['file']).to eq(infected_file_replacement)
    end

    it "should not lose params" do
      params = {'other_key' => 'other_value'}
      env = Rack::MockRequest.env_for '/', { method: "POST", params: params }

      response = do_request(env)
      expect(response.params['other_key']).to eq('other_value')
    end

    it "should return deep params with the infected file replaced" do
      params = { 'resource' => { 'name' => 'my_new_resource', 'file' => file } }
      env = Rack::MockRequest.env_for '/', { method: "POST", params: params }

      response = do_request(env)
      expect(response.params).to eq(
        'resource' => {
          'file' => infected_file_replacement,
          'name' => 'my_new_resource'
        }
      )
    end
  end

  context 'when multiple viruses are uploaded in the same POST request,' do
    it 'should find and scan all uploaded files' do
      file_1 = new_uploaded_file('virus1.txt')
      file_2 = new_uploaded_file('virus2.txt')

      scan_1 = double(
        ClamAntiVirusScan,
        :infected? => true,
        file: file_1.original_filename,
        virus_name: 'virus1',
        original_file: file_1.original_filename
      )
      scan_2 = double(
        ClamAntiVirusScan,
        :infected? => true,
        file: file_2.original_filename,
        virus_name: 'virus2',
        original_file: file_2.original_filename
      )
      expect(ClamAntiVirusScan).to receive(:new)
        .with(anything, file_1.original_filename)
        .and_return(scan_1)
      expect(ClamAntiVirusScan).to receive(:new)
        .with(anything, file_2.original_filename)
        .and_return(scan_2)

      infected_file_1_replacement = {
        'filename' => file_1.original_filename,
        'infected' => 'true',
        'virus_name' => 'virus1'
      }
      infected_file_2_replacement = {
        'filename' => file_2.original_filename,
        'infected' => 'true',
        'virus_name' => 'virus2'
      }

      params = {
        'multiple_files' => {
          'file1' => file_1,
          'buried_file_root' => {
            'buried_file_node' => {
              'buried_file' => file_2
            }
          }
        }
      }

      env = Rack::MockRequest.env_for '/', method: 'POST', params: params

      response = do_request(env)
      expect(response.params).to eq(
        'multiple_files' => {
          'file1' => infected_file_1_replacement,
          'buried_file_root' => {
            'buried_file_node' => {
              'buried_file' => infected_file_2_replacement
            }
          }
        }
      )
    end
  end
end
