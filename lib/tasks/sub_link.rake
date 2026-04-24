
namespace :sub do
  desc "destroys in-site submodule folder and symlinks to another location"
  task :link do
    config = SubConfig.new

    unless File.exist?(config.link_target)
      puts "link target: #{config.link_target} doesn't exist."
      puts "Exiting..."
      exit
    end

    unless File.exist?(config.submodule_path)
      puts "submodule path #{config.submodule_path} does not exist."
      puts "run these commands to get to a healthy state:"
      puts "> git submodule init"
      puts "> git submodule update"
      puts "Exiting..."
      exit
    end

    if File.symlink?(config.submodule_path)
      puts "already linked."
      puts "Exiting..."
      exit
    end

    unless submodule_clean?(config)
      puts "Sumodule contains modifications:"
      puts submodule_status(config)
      puts "Exiting..."
      exit
    end

    `rm -rf #{config.submodule_path}`
    File.symlink(config.link_target, config.submodule_path)
    puts "linked to #{config.link_target}"
  end

  task :unlink do
    config = SubConfig.new

    unless File.symlink?(config.submodule_path)
      puts "submodule path #{config.submodule_path} is not a link."
      puts "Exiting..."
      exit
    end

    File.unlink(config.submodule_path)
    `cd #{config.app_root}; git submodule update`

    unless File.exist?(config.submodule_path)
      puts "Submodule update FAILED! Restoring symlink..."
      File.symlink(config.link_target, config.submodule_path)
      if File.symlink?(config.submodule_path)
        puts "Symlink restored"
      else
        puts "Symlink restore FAILED!"
      end
    else
      puts "restored submodule"
    end
  end

  def submodule_status(config)
    `cd #{config.submodule_path}; git status`
  end

  def submodule_clean?(config)
    submodule_status(config)=~ /working directory clean/
  end

end


class SubConfig
  attr_accessor :app_root, :link_target, :submodule_path

  CONFIG_FILENAME = 'submodule.def'

  def initialize
    @app_root = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

    read_config_file
  end

  def read_config_file
    unless File.exist?(CONFIG_FILENAME)
      puts "configuration file not found: #{CONFIG_FILENAME}"
      puts "Exiting..."
      exit
    end

    lines = File.read(CONFIG_FILENAME).split("\n")
    lines.each do |line|
      line.strip!
      next if line.length == 0
      next if line=~ /^\#/

      (@submodule_path, @link_target) = line.split(/[\t ]+/)
      break
    end
  end
end
