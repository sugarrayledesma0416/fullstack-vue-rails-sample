
namespace :vtext do
  require 'csv'

  class VTextCSV

    def self.csv_headers
       [ 'cmd', 'href', 'activity_name', 'lesson', 'strand']
    end

    def self.convert_to_ansi(csv_path)
      utf8_csv = File.open(csv_path).read
      ansi_csv = utf8_csv.encode("Windows-1252", "UTF-8", {:undef => :replace})
      File.open(csv_path, "w") { |f| f.puts ansi_csv }
    end

  end

  desc "create list of activities to be linked into vtext"
  task :generate_activity_list => :environment do |task|
    include Rails.application.routes.url_helpers

    if ENV['program_id'].blank?
      puts "usage: rake #{task} program_id=<id>"
      exit(1)
    end
    program = Program.find(ENV['program_id'])

    desired_activity_types = ['html_reading', 'audio_hotspots', 'tutorial_grammar', 'flash_reading',
                              'map', 'vocab_list', 'flashcards', 'diagnostic', 'video_v2']

    activities = program.activities(nil).select do | activity |
      desired_activity_types.include?(activity.activity_type) || activity.icon =~ /textbook/
    end

    csv_path = Rails.root.join('tmp', "#{program.prefix_abbreviation}_maestro3_vtext_activity_links.csv")

    CSV.open(csv_path, "w") do |csv|
      csv << VTextCSV.csv_headers
      activities.sort.each do | activity |
        cmd = "open_m3_activity('#{activity.id}');"
        activity_name = activity.title.to_str.html_decode.strip_tags.gsub(/\n|\t/, '').strip
        href = activity_permalink_url(activity, :host => 'm3a.vhlcentral.com')
        csv << [cmd, href, activity_name, activity.lesson.display_name, activity.strand.name]
      end
    end

    VTextCSV.convert_to_ansi(csv_path)
  end

  desc "create list of strands to be linked into vtext"
  task :generate_strand_list => :environment do |task|
    include Rails.application.routes.url_helpers

    if ENV['program_id'].blank?
      puts "usage: rake #{task} program_id=<id>"
      exit(1)
    end

    program = Program.find(ENV['program_id'])

    csv_path = Rails.root.join('tmp', "#{program.prefix_abbreviation}_maestro3_vtext_strand_links.csv")

    CSV.open(csv_path, "w") do |csv|
      csv << VTextCSV.csv_headers
      program.lessons.each do |lesson|
        lesson.strands.each do | strand |
          if strand.location.present?
            cmd = "open_m3_toc_location('#{lesson.id}', '#{strand.location}');"
            href = student_strand_permalink_url(lesson, strand.location, :host => 'm3a.vhlcentral.com')
            csv << [cmd, href, activity_name = '', lesson.display_name, strand.name]
          end
          strand.children.each do | substrand |
            next if substrand.location.blank?
            cmd = "open_m3_toc_location('#{lesson.id}', '#{substrand.location}');"
            href = student_strand_permalink_url(lesson, substrand.location, :host => 'm3a.vhlcentral.com')
            strand_and_substrand_name = "#{strand.name} -> #{substrand.name.strip_tags}"
            csv << [cmd, href, activity_name = '', lesson.display_name, strand_and_substrand_name]
          end
        end
      end
    end

    VTextCSV.convert_to_ansi(csv_path)
  end

  desc "Create vocab list to be linked into vtext"
  task :generate_vocab_list => :environment do |task|

    if ENV['program_id'].blank?
      puts "usage: rake #{task} program_id=<id>"
      exit(1)
    end

    program = Program.find(ENV['program_id'])
    csv_path = Rails.root.join('tmp', "#{program.prefix_abbreviation}_maestro3_vtext_vocab_links.csv")

    CSV.open(csv_path, "w") do |csv|
      csv << ['BookTitle', 'Lesson', 'Strand', 'Page', 'Link Type', 'Activity name', 'Placement', 'Nav Code', 'Link']
      program.lessons.each do |lesson|
        # find all vocab_list activities for each lesson
        lesson.activities.all(:conditions => { :activity_type => 'vocab_list' }).each do |activity|
          # for each group in the content object, set the media dirs
          groups = activity.content_object.groups.each do | group |
            next if group.id.blank?
            group_media      = MediaItem.find(group.id)
            group.base_dir   = group_media.base_dir
            group.public_dir = group_media.public_dir
            group.populate_content_from_csv
          end

          groups.each do |group|
            group.rows.each do |row|
              # grab the audio_path + the vocab word out of the row
              audio_path = "http://m3a.vhlcentral.com#{row[:audio_path]}"
              vocab_word = row[:target_word]
              csv << [program.title, lesson.name, activity.strand.name, '', 'Audio', '', vocab_word, '', audio_path]
            end
          end
        end
      end
    end

    VTextCSV.convert_to_ansi(csv_path)
  end
end
