require 'stringio'

# A class that manages reading and writing to our results blob.
class ResultsXmlDatastore
  include DataStorable
  include Radner::FilesS3Bucket

  def stored_responses
    read(@attempt.offset_bytes, @attempt.record_length)
  end

  def saved_responses
    read(@attempt.save_offset_bytes, @attempt.save_record_length)
  end

  def write(results, save_mode = AttemptSubmission::Mode::SUBMITTED)
    if results.is_a?(String)
      offset = write_raw(results)
      bytes = results.bytesize
    else
      offset = write_xml(results, save_mode)
      bytes = xml_length
    end

    @attempt.set_submission(@xml_offset, bytes, 0, save_mode)
    offset
  end

  def write_xml(results, save_mode)
    process_results_to_xml(results, save_mode)
    offset = 0
    @xml_output = doc.to_xml(:encoding => 'UTF-8', :indent => 2)
    Rails.logger.debug("\n\n\nWriting xml submission:\n#{@xml_output}\n\n\n")
    offset = write_raw(@xml_output)
    offset
  end

  def doc
    @xml_doc ||= Nokogiri::XML::Document.new
  end
  private :doc

  def process_results_to_xml(results, save_mode = :submitted)
    doc_root = Nokogiri::XML::Node.new("activity_responses", doc)
    doc_root['id'] = "#{@attempt.activity_id}"
    doc_root['mode'] = 'unsubmitted' if save_mode == :unsubmitted
    doc.root = doc_root

    results.each do |result|
      node = Nokogiri::XML::Node.new("response", doc)
      node['label'] = result[:label]
      node.content = result[:response]
      doc.root << node
    end
  end
  private :process_results_to_xml

  # For ruby 1.8.7 xml_length was calculated using String#length,
  # in ruby 1.9.3 that method doesn't return the real length in bytes but,
  # String#bytesize does. This method will be used given that it exists
  # in both versions and returns the real length in bytes.
  def xml_length
    @xml_output.bytesize
  end

  private :xml_length

  def read
    read(@attempt.offset_bytes, @attempt.record_length)
  end

  def read(offset, bytes)
    response_xml = read_raw(offset, bytes)
    Rails.logger.debug("\n\n\nLoading submission xml:\n#{response_xml}\n\n\n")
    doc = Nokogiri::XML.parse(response_xml)
    responses = Hash.new

    if doc.root.blank?
      begin
        raise "No responses found for attempt ID #{@attempt.id} - status: #{@attempt.status}"
      rescue Exception => e
        VHLMonitor.notify(e)
      end
    else
      doc.root.xpath('response').each do |node|
        responses[node.attribute('label').to_s] = node.content
      end
    end

    responses
  end

  def write_raw(xml)
    @xml_offset = file_size
    # because S3 does not allow appending, we append here.
    xml = content_data + xml
    s3_bucket.store_file_contents!(filepath, xml, content_type: 'application/xml')
    @xml_offset
  end

  def read_raw(offset, bytes)
    file = StringIO.new(content_data || '')
    file.pos = offset
    xml = file.read(bytes)
    file.close()
    # The xml file we are reading is utf-8 encoded but when we read a file
    # given an offset it returns a ascii-8 encoded string, that's why
    # it should be force encoded to utf-8.
    xml && xml.force_encoding('utf-8')
  end

  def transfer_results(section_to)
    file_from = filepath
    file_to = File.join(dirpath(section_to.id), "#{@attempt.user_id}.xml")

    # Do not overwrite attempts if they already
    if file_exists?(file_to)
      begin
        raise "Cannot transfer results for student #{@attempt.user_id} from section #{@attempt.section_id} to section #{section_to.id}"
      rescue Exception => e
        VHLMonitor.notify(e)
      end
    else
      s3_bucket.move_file(file_from, file_to)
    end
  end

  def dirpath(sid = nil)
    File.join("datafiles", M3::Application.config.current_deployed_env_name,
              "responses", (sid || @attempt.section_id).to_s)
  end
  private :dirpath

  def filepath
    File.join(dirpath, "#{@attempt.user_id}.xml")
  end
  alias_method :file_path, :filepath
end
