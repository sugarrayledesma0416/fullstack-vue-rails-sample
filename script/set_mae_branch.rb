#!/usr/bin/env ruby

class MaeBranchUpdater
  attr_accessor :branch_name, :gemfile_path, :package_json_path

  def initialize(branch_name)
    self.branch_name = branch_name
    self.gemfile_path = 'Gemfile'
    self.package_json_path = 'package.json'
  end

  def run_command(description, command)
    puts "Running: #{description}..."
    if system(*command)
      puts "✓ #{description} completed successfully"
      true
    else
      puts "✗ #{description} failed"
      exit 1
    end
  end

  def update_gemfile
    content = File.read(gemfile_path)

    # Pattern to match the maestro_activity_engine gem line
    # Handles both tag and branch formats
    pattern = /gem 'maestro_activity_engine', git: vhl_repo\('mae'\), (?:tag|branch): '[^']*'/
    replacement = "gem 'maestro_activity_engine', git: vhl_repo('mae'), branch: '#{branch_name}'"

    if content.match?(pattern)
      updated_content = content.gsub(pattern, replacement)
      File.write(gemfile_path, updated_content)
      puts "✓ Updated Gemfile: maestro_activity_engine now points to branch '#{branch_name}'"
    else
      puts "✗ Could not find maestro_activity_engine gem line in Gemfile"
      exit 1
    end
  end

  def update_package_json
    content = File.read(package_json_path)

    # Pattern to match the mae package line
    pattern = /"mae": "https:\/\/github\.com\/vhl\/mae#[^"]*"/
    replacement = "\"mae\": \"https://github.com/vhl/mae##{branch_name}\""

    if content.match?(pattern)
      updated_content = content.gsub(pattern, replacement)
      File.write(package_json_path, updated_content)
      puts "✓ Updated package.json: mae package now points to branch '#{branch_name}'"
    else
      puts '✗ Could not find mae package line in package.json'
      exit 1
    end
  end

  def run
    puts "Updating maestro_activity_engine to branch: #{branch_name}"
    puts '=' * 50

    update_gemfile
    update_package_json

    # Update Gemfile.lock and yarn.lock with new mae branch
    run_command('script/update-mae', ['script/update-mae'])

    puts '=' * 50

    # Add the changed files
    run_command(
      'git add',
      ['git', 'add', 'Gemfile', 'package.json', 'Gemfile.lock', 'yarn.lock']
    )

    # Check if GPG signing is enabled
    gpg_sign = `git config --get --type=bool commit.gpgsign`.strip == 'true'

    # Create commit
    commit_message = "gems+yarn: Point maestro_activity_engine to branch #{branch_name}."
    commit_args = ['git', 'commit']
    commit_args << '-S' if gpg_sign
    commit_args += ['-m', commit_message]

    run_command('git commit', commit_args)
  end
end

# Get branch name from command line argument or default to current git branch
branch_name = ARGV[0]

if branch_name.nil? || branch_name.empty?
  # Get current git branch name
  current_branch = `git branch --show-current`.strip
  if current_branch.empty?
    puts "Error: No branch name provided and not in a git repository"
    puts "Usage: #{$0} <branch_name>"
    puts "Example:"
    puts "  #{$0} mae-12345"
    exit 1
  end
  branch_name = current_branch
  puts "Using current branch: #{branch_name}"
end

# Run the updater
updater = MaeBranchUpdater.new(branch_name)
updater.run
