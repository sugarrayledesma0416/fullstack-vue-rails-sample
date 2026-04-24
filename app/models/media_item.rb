require 'fileutils'
require 'net/http'
require 'uri'

class MediaItem < ApplicationRecord
  include Unzippable
  include MediaItemLocation
  include ImageDimensions
  include SvgContent

  scope :audio_or_video, -> { where(media_type: %w[audio video]) }

  CDN_URL_PREFIX = 'https://media.maestro.vhlcentral.com'.freeze

  before_save :set_alt_tag

  def alt_text
    alt_tag
  end

  # Used by lib/maestro_activity_engine/activity_content/flash_reading_content.rb
  def unzipped_cdn_directory
    return unless cdn? && zip_type?

    "#{path_prefix}#{zip_base_dir}"
  end

  def json_version
    subtitle_version('.js')
  end

  def vtt_version
    subtitle_version('.vtt')
  end

  def cdn_target_filename
    common_path
  end

  def server_url(url)
    (cdn? && CDN_URL_PREFIX) || url
  end

  # This may look crazy as it's just undoing the work in public_filename_for_arc,
  # put it's necessary in order to override it in PreviewMediaItem subclass
  # which may need to pull from the cms host instead of the CDN if the
  # media item is not yet published.
  # TODO: Find all the places using public_filename_for_arc and see if they
  #       can be changed to use this method instead.
  def public_url_for_arc
    "#{CDN_URL_PREFIX}#{public_filename_for_arc}"
  end

  def public_filename_for_arc
    public_filename.gsub(CDN_URL_PREFIX, '')
  end

  # Used by:
  # lib/maestro_activity_engine/activity_content/tutorial_vocab_content.rb
  def unzipped_directory
    if cdn?
      unzipped_cdn_directory
    else
      public_dir
    end
  end

  def tutorial_id
    return @tutorial_id if defined?(@tutorial_id)

    @tutorial_id = if unzipped_cdn_directory.present?
                     cdn_file_content(
                       File.join(
                         unzipped_cdn_directory,
                         'data',
                         'tutorial_id.txt'
                       ).to_s
                     )
                   end
  end

  # Used by:
  # lib/maestro_activity_engine/activity_content/tutorial_vocab_html5_content.rb
  # The vocab tutorials zip file contains a directory with a name that is
  # particular to each vocab tutorial. Because of that, we save the directory
  # name in base_content_folder.txt when publishing from CMS.
  def base_content_folder
    return @base_content_folder if defined?(@base_content_folder)

    @base_content_folder = if unzipped_cdn_directory.present?
                             cdn_file_content(
                               File.join(
                                 unzipped_cdn_directory,
                                 'base_content_folder.txt'
                               ).to_s
                             )
                           end
  end

  def aspect_ratio
    ratio = (width.to_f / (height - 20)).round(2)
    if aspect_4_by_3?(ratio)
      '4_by_3'
    elsif aspect_16_by_9?(ratio)
      '16_by_9'
    else
      raise "Unsupported aspect ratio #{ratio} for media item #{id} width=#{width} height=#{height}"
    end
  end

  def public_dir
    if revision_id
      unzipped_cdn_directory
    else
      File.join(File.dirname(public_filename), subdir_chunk)
    end
  end

  private def common_path
    if revision_id?
      object_key
    else
      super
    end
  end

  private def object_key
    "#{object_key_without_extension}#{extension}"
  end

  private def object_key_without_extension
    "/#{media_type_dir}/m#{id_string}_r#{revision_id_string}"
  end

  private def extension
    File.extname(filename)
  end

  private def zip_type?
    %w[flash_reading vocab_tutorial vocab_group].include?(media_type)
  end

  # When a media item is uploaded to cms as a zip file, this returns the
  # directory into which the zip contents are extracted.
  private def zip_base_dir
    if revision_id?
      object_key_without_extension
    else
      "/#{media_type_dir}/#{dir_chunk}/#{subdir_chunk}"
    end
  end

  private def subtitle_version(subtitle_extension)
    CDN_URL_PREFIX + common_path.gsub(/(\.xml|\.stl)\Z/, subtitle_extension)
  end

  # Used by app/models/image_dimensions.rb
  private def image_file_path
    full_filename && full_filename.gsub(/\s/, '%20')
  end

  private def path_prefix
    (cdn? && CDN_URL_PREFIX) || super
  end

  private def revision_id_string
    format('%<revision_id>08d', revision_id: revision_id)
  end

  private def aspect_4_by_3?(ratio)
    (1.3..1.4).include?(ratio)
  end

  private def aspect_16_by_9?(ratio)
    (1.7..1.8).include?(ratio)
  end

  private def set_alt_tag
    self.alt_tag = nil unless media_type == 'image'
  end

  # Used by lib/maestro_activity_engine/activity_content/vocab_list/group.rb
  def csv_content
    return unless cdn?

    @csv_content ||= CSV.parse(current_csv)
  end

  private def current_csv
    redis_cache = M3::Application.config.cdn_cache
    # TODO: once https://vistahl.atlassian.net/browse/MAE-21911 is merged in deployed.
    # We can change the updated_at part of the key with the cms_revision_id.
    cache_key = "media_item:#{self.id}#{self.updated_at.to_i}"
    csv_string = redis_cache && redis_cache.get(cache_key)
    if csv_string.blank?
      csv_string = cdn_file_content(File.join(unzipped_directory, csv_filename).to_s)
      # Net::HTTP does not know how to identify the encoding. https://bugs.ruby-lang.org/issues/2567
      # so since we know it is windows-1252, we force that encoding.
      csv_string = csv_string.force_encoding('windows-1252').encode('UTF-8')
      redis_cache.set(cache_key, csv_string) if redis_cache
    end
    csv_string
  end

  private def csv_filename
    return @csv_filename if defined?(@csv_filename)
    @csv_filename = if unzipped_cdn_directory.present?
      cdn_file_content(File.join(unzipped_cdn_directory, 'csv_filename.txt').to_s)
    end
  end

  private def cdn_file_content(location)
    Net::HTTP.get(URI.parse(location))
  end


  ## for local files only

  def payload=(payload)
    FileUtils.makedirs( File.dirname(media_file_path) )
    store_unprocessed_payload(payload)
    case media_type
    when 'image'                then set_dimensions
    when 'vocab_group'          then unzip_vocab_group
    when 'vocab_tutorial'       then unzip_vocab_tutorial
    when 'flash_reading', 'zip', 'vocab_tutorial_html5' then unzip_file_in_base_dir
    end
  end

  private def store_unprocessed_payload(payload)
    begin
      file = File.new(media_file_path, "wb")
      file.write(payload)
    ensure
      file.close if file
    end
  end

  private def purge_old_csv_files
    FileUtils.rm(Dir.glob("#{base_dir}/*.csv"))
  end

  private def unzip_vocab_group
    FileUtils.makedirs(base_dir)
    purge_old_csv_files
    unzip_without_subdirs(media_file_path, base_dir)
  end

  private def unzip_vocab_tutorial
    unzip_file_in_base_dir
    discard_invalid_vocab_tutorial_player_swf_files #temporary, to be removed once all zip files are cleaned up
    symlink_local_vocab_tutorial_player_swf_files
  end

  private def unzip_file_in_base_dir
    FileUtils.makedirs(base_dir)
    unzip_with_subdirs(media_file_path, base_dir)
  end

  def full_filename
    return if cdn? # this is the full local filename, so exit if the asset is on the cdn.
    return if new_record?

    File.join(Rails.public_path, public_filename)
  end

  def base_dir
    File.join(File.dirname(media_file_path), subdir_chunk)
  end

  # Seems to be orphaned
  private def read_file
    File.read(full_filename)
  end

  # Seems to be orphaned
  private def public_base_dir
    File.dirname(public_filename)
  end

  private def media_file_path
    File.join(
      'public',
      'media_items',
      "#{Rails.env}#{ENV['TEST_ENV_NUMBER']}",
      media_type_dir,
      dir_chunk,
      filename
    )
  end

  private def discard_invalid_vocab_tutorial_player_swf_files #TT
    # discard invalid swf files coming from zip file
    # TODO: write a task to edit zip files and remove these permanently
    ['contextos.swf', 'cloader.swf'].each do |poisoned_player|
      poisoned_player_path = File.join(base_dir, poisoned_player)
      File.unlink poisoned_player_path if File.exist? poisoned_player_path
    end
  end

  private def symlink_local_vocab_tutorial_player_swf_files
    local_player_dir = Rails.root.join('public', 'players')
    players = ['cloader', 'contextos', 'dragndropimage', 'dragndropwords', 'matching', 'multiplechoice', 'vocabtetris']
    players.each do | player |
      player_file = "#{player}.swf"
      target_path = File.join(local_player_dir, player_file)
      link_path   = File.join(base_dir, player_file)
      FileUtils.symlink(target_path, link_path) unless (File.exist?(link_path) || File.symlink?(link_path))
    end
  end
end
