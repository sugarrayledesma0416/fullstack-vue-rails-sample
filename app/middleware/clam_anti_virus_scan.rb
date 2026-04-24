#  encoding: utf-8

class ClamAntiVirusScan

  cattr_accessor :enabled, :detect_fakes
  attr_accessor :file, :scan_state, :virus_name, :original_file

  def detect_fakes?
    @@detect_fakes || false
  end

  def enabled?
    @@enabled || false
  end

  VALID_SCAN_STATES = [:clean, :infected, :unparseable]
  FAKE_DETECTED_VIRUS_NAME = 'Virus.Based.0N.Filename'

  def initialize(tempfile, original_filename = nil)
    raise "A file to scan must be specified." if tempfile.blank?
    raise "Specified file '#{tempfile.to_s}' does not exist." unless File.exist?(tempfile)
    self.file = tempfile.to_s
    self.original_file = original_filename || File.basename(tempfile).to_s

    if media_file?
      flag_as_clean
    else
      do_scan_and_parse_results
      scan_for_fake_virus if clean? && detect_fakes?
    end
  end

  VALID_SCAN_STATES.each do |state|
    define_method("#{state}?".to_sym) do
      self.scan_state == state
    end
  end

  private def media_file?
    # clamscan is blocking significantly for media files and increasing the passenger queue
    # we will therefore ignore media files. We will start with mp3s and mp4s
    # Delivering malware through media files is generally an advanced hack and would require
    # the media file to be played/passed through a player to deliver the pawn
    %w[.mp3 .mp4].include? File.extname(file)
  end

  def do_scan_and_parse_results
    flag_as_clean and return if disabled?
    #TODO: Find a way to mock results of backticks in order to test parse errors
    #    See: http://jakescruggs.blogspot.com/2007/11/mocking-backticks-and-other-kernel.html
    response = %x{clamscan #{file}}
    if $?.success?
      flag_as_clean
    else
      parse_response(response)
      raise "unable to parse scan results\n\n===#{response}\n===" if unparseable?
    end
  end
  private :do_scan_and_parse_results

  def scan_for_fake_virus
    filename_without_extension = File.basename(original_file, File.extname(original_file))
    if filename_without_extension == 'virus'
      flag_as_infected
      self.virus_name = FAKE_DETECTED_VIRUS_NAME
    end
  end
  private :scan_for_fake_virus

  def parse_response(response)
    scan_message = response.lines.first
    flag_as_unparseable and return if scan_message.blank?
    parse_virus_name(scan_message)
  end
  private :parse_response

  def parse_virus_name(scan_message)
    if scan_message =~ /#{file}\: (.*) FOUND/
      self.scan_state = :infected
      self.virus_name = $1
    else
      flag_as_unparseable
    end
  end
  private :parse_virus_name

  def disabled?
    !@@enabled
  end
  private :disabled?

  def method_missing(method, *args, &block)
    super unless method.to_s[0..7] == 'flag_as_'
    scan_state = method.to_s[8..-1].to_sym
    if VALID_SCAN_STATES.include?(scan_state)
      self.scan_state = scan_state
    else
      raise "cannot set scan state of #{scan_state}. Valid states are #{VALID_SCAN_STATES.join(', ')}"
    end
  end

end
