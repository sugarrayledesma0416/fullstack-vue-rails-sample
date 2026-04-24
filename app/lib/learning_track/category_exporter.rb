require_relative '../../../app/models/learning_track/base'

module LearningTrack
  class CategoryExporter < Base
    attr_reader :xls, :headers

    def categories_from_xls
      @categories_from_xls ||= xls.map do |row|
        Hash[headers.zip(row)]
      end
    end

    def parse_attempts(attempts)
      attempts.to_s.downcase == 'unlimited' ? -1 : attempts.to_i
    end
    private :parse_attempts

    def parse_late_work(entry)
      entry.downcase == 'y' ? 1 : 0
    end
    private :parse_late_work

    def parse_late_work_penalty(entry)
      entry.to_s.strip.downcase.parameterize.underscore
    end
    private :parse_late_work_penalty

    # Takes a row from the xls
    private def build_category(row, rank_counter)
      {
        row['Name'].strip => {
          :name => row['Name'].strip,
          :rank => rank_counter,
          :max_attempts => parse_attempts(row['Attempts']),
          :credit_only => row['Graded'].downcase != 'y',
          :weighting_percent => row['Percent'].to_i,
          :accept_late_work => parse_late_work(row['Late_work']),
          :penalty_percent => row['Penalty'].to_i,
          :late_work_penalty => parse_late_work_penalty(row['Penalty_type'])
        }
      }
    end

    private def build_category_sets
      current_category_set = ""
      rank_counter = 0
      categories_from_xls.inject({}) do |memo, row|
        if row['Category Set']
          rank_counter = 1
          current_category_set = row['Category Set']
          memo[current_category_set] = build_category(row, rank_counter)
        else
          rank_counter += 1
          memo[current_category_set].merge!(build_category(row, rank_counter))
        end
        memo
      end
    end

    private def build_categories_json
      JSON.generate({
        'categories' => build_category_sets
      }.as_json)
    end

    def write_categories_json(xls_file_name)
      @xls ||= temp_spreadsheet(file_path(xls_file_name))
      @headers = @xls.shift.map(&:strip)
      s3_bucket.store_file_contents!(file_path('categories.json'), build_categories_json)
    end
  end
end



