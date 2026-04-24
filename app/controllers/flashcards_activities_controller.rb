class FlashcardsActivitiesController < ApplicationController
  include ApplicationHelper
  def flashcards_data

    activity_id = params[:id]
    deck_number = params[:flashcards_deck_id].to_i

    activity = Activity.find(params[:id]).extend(ActivityViewDecorator)
    parser = MaestroActivityEngine::ActivityParser.create_parser(activity.content.to_s, MediaLink)
    activity_content = parser.parse

    decks = Array.new
    vocab_terms = Array.new
    vocab_group_errors = []

    activity_content.items.each do |vocab_group|
      next if vocab_group.id.blank?
      group_media = MediaItem.find(vocab_group.id)
      vocab_group.base_dir   = group_media.base_dir
      vocab_group.public_dir = group_media.unzipped_directory
      vocab_group.content_csv = group_media.csv_content
      vocab_group.populate_content_from_csv
      vocab_terms += convert_response_to_hash(vocab_group.rows)
      vocab_group_errors << vocab_group.error_messages
    end

    send_notification_for(vocab_group_errors)

    vocab_terms = format_terms_from_content(vocab_terms, activity_content.items)

    decks = split_terms_into_decks(vocab_terms, activity_content.number_of_decks)
    render :json => decks[deck_number-1], :root => false
  end

  private def send_notification_for(vocab_group_errors)
    error_messages = vocab_group_errors.compact.join(', ')
    if error_messages.present?
      VHLMonitor.notify(StandardError.new(error_messages),
                        rack_env: request.env)
    end
  end

  def convert_response_to_hash(vocab_group_rows)
    retval = []
    vocab_group_rows.each do |row|

      unless row[:target_word].blank? || row[:native_word].blank? # blank lines in the csv
        retval << {:target => row[:target_word], :base => row[:native_word], :audio_path => row[:audio_path]}
      end
    end
    retval
  end

  def split_terms_into_decks(terms, number_of_decks)
    decks = []
    number_of_decks.times {decks << []}
    terms.each_with_index do |term, term_index|
      decks[term_index % number_of_decks] << term
    end
    decks
  end

  def format_terms_from_content(terms, groups)
    targets = {}
    bases = {}
    groups.each do |group|
      if group.breaks
        group.breaks.each do |br|
          if br[:target]
            br[:target].each do |target|
              if target
                key = normalize_key(target)
                targets[key] = target.strip
              end
            end
          end
          if br[:base]
            br[:base].each do |base|
              if base
                key = normalize_key(base)
                bases[key] = base.strip
              end
            end
          end
        end
      end
    end

    terms.each do |term|
      target_match = normalize_key(term[:target])
      if targets[target_match]
        term[:target] = targets[target_match]
      end
      base_match = normalize_key(term[:base])
      if bases[base_match]
        term[:base] = bases[base_match]
      end
    end

    terms
  end

  def normalize_key(str)
    html_strip_and_decode(str.gsub(/(\s|<br\/>)/, '').downcase)
  end

end
