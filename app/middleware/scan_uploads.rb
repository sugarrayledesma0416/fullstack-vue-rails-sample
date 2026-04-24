class ScanUploads
  attr_accessor :app, :request, :env

  def initialize(app)
    self.app = app
  end

  def call(env)
    self.request = Rack::Request.new(env)
    self.env = env

    # only scan if request is a form upload
    if posted_form? && is_multipart?
      set_scanned_flag_in_headers
      replace_any_infected_files_in_post_data
    end
    app.call(env)
  end

  private def replace_any_infected_files_in_post_data
    clean_params = replace_if_infected(request.params)
    # no need to mess with request if it is clean
    return if clean_params == request.params

    env.merge!(new_request_headers(clean_params))
  end

  private def new_request_headers(params)
    new_headers = { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }
    if params.is_a?(Hash)
      if (data = Rack::Multipart.build_multipart(params))
        rack_input = data
        new_headers['CONTENT_LENGTH'] ||= data.length.to_s
        new_headers['CONTENT_TYPE'] = 'multipart/form-data; boundary=' +
                                      Rack::Multipart::MULTIPART_BOUNDARY
      else
        rack_input = Rack::Utils.build_nested_query(params)
      end
    else
      rack_input = params
    end

    rack_input = StringIO.new(rack_input) if rack_input.is_a?(String)
    rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

    new_headers['rack.input'] = rack_input
    new_headers
  end

  private def set_scanned_flag_in_headers
    env['scanned'] = 'scanned'
  end

  private def replace_if_infected(params)
    params.each_with_object({}) do |(key, value), memo|
      memo[key] = if value.is_a?(Hash)
                    if (scan = scan_for_virus(value)) && scan.infected?
                      infected_file_replacement(scan)
                    else
                      replace_if_infected(value)
                    end
                  else
                    value
                  end
    end
  end

  private def infected_file_replacement(scan)
    {
      'filename' => scan.original_file,
      'infected' => 'true',
      'virus_name' => scan.virus_name
    }
  end

  private def scan_for_virus(param)
    file_to_scan = param.values.detect { |value| value.is_a?(Tempfile) }
    return false if file_to_scan.nil?

    original_filename = param[:filename] || param['filename']
    ClamAntiVirusScan.new(file_to_scan.path, original_filename)
  end

  private def is_multipart?
    !!Rack::Multipart.parse_multipart(request.env)
  end

  private def posted_form?
    (request.post? || request.put?) && request.form_data?
  end
end
