require 'axlsx'

class A11ySpreadsheet
  NON_REPORTABLE_ISSUES = %i[
    BlankHeading
    DirectionLineMentionsBold
    DirectionLineMentionsItalics
    DirectionLineMentionsUnderline
    UnderscoresInPrompt
  ].freeze

  attr_accessor :file_name, :file_path, :include_details, :program_id

  def initialize(program_id, include_details)
    self.program_id = program_id
    self.include_details = include_details
    timestamp = Time.zone.now.utc.strftime('%FT%T')
    self.file_name = "a11y_report_program_#{program_id}_#{timestamp}.xlsx"
    self.file_path = File.join('/tmp', file_name)
  end

  def data
    @data ||= activity_query.map do |activity|
      next unless activity.content_object

      row_data(activity)
    end.compact
  end

  private def row_data(activity)
    {
      'Lesson' => activity.lesson.unit.name,
      'Strand' => normalize(activity.concept.name),
      'Title' => normalize(activity.title),
      'Rating' => a11y_rating(activity),
      'Link' => m3_link(activity),
      'Type' => activity.activity_type,
      'IssueList' => reportable_issues(activity).inspect,
      'SubActivityTypes' => sub_activity_types(activity)
    }
  end

  # rubocop:disable Layout/MultilineMethodCallIndentation,Style/AsciiComments
  private def normalize(string)
    # unicode_normalize deals with the evil Combining Diacritical Marks
    # e.g. U+0300, U+0301, U+0302
    # See:
    # https://en.wikipedia.org/wiki/Combining_Diacritical_Marks
    # https://blog.daftcode.pl/fixing-unicode-for-ruby-developers-60d7f6377388
    string.unicode_normalize
          .strip_tags
          .html_decode # convert &amp; to & and &gt; to >
          .gsub("\u279e", '->') # handles "Stem-changing verbs: <b>e➞i</b>"
          .gsub("\u2794", '->') # handles "Stem-changing verbs: <b> e ➔ i</b>"
          .gsub("\u2212", '-') # changes minus sign char to regular dash
          .delete("\u0085") # gets rid of pesky "next line" control code
  end
  # rubocop:enable Layout/MultilineMethodCallIndentation,Style/AsciiComments

  private def a11y_rating(activity)
    if reportable_issues(activity).present?
      'Not Accessible'
    else
      'Accessible'
    end
  end

  private def reportable_issues(activity)
    case activity.activity_type
    when 'quick_check_drag_and_drop'
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES)
              .except(:BlankPrompt)
    when 'open_ended'
      open_ended_blank_prompt_issues(activity)
    when 'interactive_video'
      interactive_video_reportable_issues(activity)
    else
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES)
    end
  end

  private def open_ended_blank_prompt_issues(activity)
    if activity.content_object.items.grep(
      MaestroActivityEngine::ActivityContent::OpenEnded::Item
    ).size == 1
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES, :BlankPrompt)
    else
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES)
    end
  end

  private def interactive_video_reportable_issues(activity)
    if activity.content_object.quick_check&.any? { |item| item.type == 'quick_check_drag_and_drop' }
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES)
              .except(:BlankPrompt)
    else
      activity.a11y_issues.except(*NON_REPORTABLE_ISSUES)
    end
  end

  private def sub_activity_types(activity)
    return '' unless activity.activity_type == 'smart_book'

    activity.content_summary.inspect
  end

  private def m3_link(activity)
    "https://m3a.vhlcentral.com/sections/0/activities/#{activity.id}"
  end

  # rubocop:disable Layout/MultilineMethodCallIndentation
  private def activity_query
    Activity.joins(lesson: :unit)
            .joins(:concept)
            .includes(lesson: :unit)
            .includes(:concept)
            .where(units: { program_id: program_id })
            .where('activities.cms_activity_id is not null')
            .order('units.rank, lessons.rank, concepts.rank, activities.concept_rank')
  end
  # rubocop:enable Layout/MultilineMethodCallIndentation

  def write
    return if data.empty?

    Workbook.new(data, include_details).write_file(file_path)
  end

  class Workbook
    attr_accessor :data
    attr_writer :include_details

    def initialize(data, include_details)
      self.data = data
      self.include_details = include_details
    end

    def write_file(file_path)
      generate_sheet
      package.serialize(file_path)
      # `open #{file_path}`
    end

    private def include_details?
      @include_details.present? && @include_details != 'false'
    end

    private def package
      @package ||= Axlsx::Package.new
    end

    private def generate_sheet
      workbook = package.workbook

      workbook.styles do |styles|
        head = styles.add_style(head_opts.merge(left_opts))
        body = styles.add_style(left_opts)

        center_head = styles.add_style(head_opts.merge(center_opts))
        accessible_body = styles.add_style(accessible_opts)
        inaccessible_body = styles.add_style(inaccessible_opts)
        link_body = styles.add_style(link_opts)

        head_styles = [head, head, head, center_head, head, head, head, head]
        accessible_row = [body, body, body, accessible_body, link_body, body, body, body]
        inaccessible_row = [body, body, body, inaccessible_body, link_body, body, body, body]

        workbook.add_worksheet(name: 'Sheet1') do |sheet|
          sheet.add_row(filtered_hash(data.first).keys, style: head_styles)
          data.each do |hash|
            body_styles = if hash['Rating'] == 'Accessible'
                            accessible_row
                          else
                            inaccessible_row
                          end
            row = sheet.add_row(filtered_hash(hash).values, style: body_styles)
            sheet.add_hyperlink(location: hash['Link'], ref: row.last)
          end
          format_sheet(sheet)
        end
      end
    end

    private def filtered_hash(hash)
      if include_details?
        hash
      else
        hash.except('Type', 'IssueList', 'SubActivityTypes')
      end
    end

    private def auto_filter_range(end_row)
      end_col = include_details? ? 'G' : 'E'
      "A1:#{end_col}#{end_row}"
    end

    private def format_sheet(sheet)
      sheet.column_widths 24, 32, 36, 12, 36, 12, 36, 36
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = 'A2'
        pane.state = :frozen
        pane.y_split = 1
        pane.active_pane = :bottom_left
      end
      end_row = data.size + 1
      sheet.auto_filter = auto_filter_range(end_row)
    end

    private def head_opts
      { b: true, border: { color: '000000', style: :medium, edges: %i[bottom] } }
    end

    private def left_opts
      { alignment: { horizontal: :left, vertical: :top, wrap_text: true }, sz: 10 }
    end

    private def center_opts
      { alignment: { horizontal: :center, vertical: :top, wrap_text: true }, sz: 10 }
    end

    private def accessible_opts
      center_opts.merge(bg_color: 'C6EFCF', fg_color: '076100')
    end

    private def inaccessible_opts
      center_opts.merge(bg_color: 'D9D9D9')
    end

    private def link_opts
      left_opts.merge(fg_color: '0B63C1', u: true)
    end
  end

  # :nocov:
  # rubocop:disable Rails/Output
  # This is helpful for debugging encoding issues.
  def write_csv
    return if data.empty?

    CSV.open(file_path, 'wb', csv_opts) do |csv|
      data.each do |row_hash|
        last_hash = row_hash
        csv << row_hash
      rescue StandardError => e
        puts "#{e.message} #{last_hash.inspect}"
      end
    end
  end
  # rubocop:enable Rails/Output
  # :nocov:

  # :nocov:
  private def csv_opts
    {
      encoding: 'windows-1252:utf-8',
      headers: data.first.keys,
      force_quotes: true,
      write_headers: true
    }
  end
  # :nocov:
end
