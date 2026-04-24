
def create_zipfile(subdirs = '', file_list = nil)
  zip_filename = '/tmp/spec_test.zip'
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

    if file_list && !file_list.empty?
      file_list.each{|file_name| zip.get_output_stream("#{subdirs}#{file_name}") {|file| file.write("content")} }
    else
      zip.get_output_stream("#{subdirs}master.csv") {|file| file.write("csv")}
      zip.get_output_stream("#{subdirs}header.mp3") {|file| file.write("header")}
    end
  end

  zip_filename
end
