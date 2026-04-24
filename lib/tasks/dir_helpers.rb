

class DirHelpers
  # Delete folders if they are empty, down to depth.
  # Give this guy a spin in a test file before you use it? 
  # It's on the dangerous side. :)
  def self.clean_folders(filename, depth = 1)
    dirname = File.dirname(filename)
    1.upto(depth) do 
      Dir.rmdir(dirname) if empty?(dirname)
      dirname = File.dirname(dirname)
    end
  end
  
  def self.empty?(dirname)
    return false unless File.directory?(dirname)
    return Dir.entries(dirname).length == 2
  end
end
