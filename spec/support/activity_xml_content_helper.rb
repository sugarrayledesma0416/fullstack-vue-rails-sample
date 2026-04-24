module ActivityXmlContentHelper
  # since we store live activity xml on S3 now, we need
  # these methods to write files locally for testing
  def content=(content)
    write_content_to_revision(content, cms_revision_id)
  end

  def write_content_to_revision(content, revision_id, instructor_created = false) #TT
    content_filepath = Activity.filepath_from_revision_id(revision_id, instructor_created, cdn = false)
    begin
      if File.exist?(content_filepath)
        if new_content_is_different?(content_filepath, content)
          raise "Attempt to overwrite existing revision (#{revision_id}) with different content."
        else
          # Nothing to do since the content is the same.
          return
        end
      end
    rescue Exception => e
      raise "Attempt to overwrite existing revision (#{revision_id}) with different content."
    end

    FileUtils.makedirs(File.dirname(content_filepath))
    begin
      file = File.new(content_filepath, "w")
      file.write(content)
    ensure
      file.close if file
    end
  end

  def new_content_is_different?(content_filepath, new_content)
    old_content = File.read(content_filepath)
    activity_content = Nokogiri::XML.parse(old_content, nil, 'utf-8').xpath('activity').to_s
    new_activity_content = Nokogiri::XML.parse(new_content, nil, 'utf-8').xpath('activity').to_s
    activity_content != new_activity_content
  end

  def content_object_from_xml(xml_file)
    doc = Nokogiri::XML.parse(xml_file)
    parser = MaestroActivityEngine::ActivityParser.create_parser(doc.to_s, linked_media_class)
    parser.parse
  end
end
