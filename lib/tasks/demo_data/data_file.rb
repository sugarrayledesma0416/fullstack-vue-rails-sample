
module DemoData

  module DataFile
    require 'fileutils'

    def self.read(filepath)
      File.read(filepath)
    end

    def self.write(filepath, contents)
      FileUtils.makedirs( File.dirname(filepath) )
      File.open(filepath, 'w') {|file| file.write(contents) }
    end

    def self.write_binary(filepath, contents)
      FileUtils.makedirs( File.dirname(filepath) )
      File.open(filepath, 'wb') {|file| file.write(contents) }
    end

    def self.copy(orig_path, dest_path)
      FileUtils.makedirs( File.dirname(dest_path) )
      FileUtils.cp(orig_path, dest_path)
    end

    def self.delete_dir(dir)
      FileUtils.rm_r(dir) if File.exist?(dir) && File.directory?(dir)
    end

    def self.download(remote_host, remote_path, local_path)
      unless File.exist?(local_path)
        Net::HTTP.start(remote_host) do |http|
          resp = http.get(remote_path)
          DemoData::DataFile.write_binary(local_path, resp.body)
        end
      end
    end

  end
  
end