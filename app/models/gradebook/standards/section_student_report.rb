module Gradebook
  module Standards
    class SectionStudentReport
      SECTION_CSV_HEADERS = [
        'Standards',
        'Standard Definition',
        'Standard Items',
        'Correct Percentage',
        'Submitted and Graded',
        'Correct Items',
        'Section',
        'Unit',
        'Assessment'
      ].freeze

      STUDENT_CSV_HEADERS = [
        'Student Name',
        'Standard',
        'Standard Definition',
        'Correct Percentage',
        'Correct Vs Total',
        'Section',
        'Unit',
        'Assessment'
      ].freeze

      def self.extracted_data_from_section(section_report)
        extracted_data = []
        section_report.activities.each do |activity|
          section_report.standards_data.each_row do |standard_data|
            data = {}
            data['Standards'] = standard_data.standard.label
            data['Standard Definition'] = standard_data.standard.description
            data['Standard Items'] = "#{standard_data.total_number_of_items} Items"
            data['Correct Percentage'] = section_report.percentage_format(
              standard_data.percent_correct_by_activity(activity.cms_activity_id)
            )
            data['Submitted and Graded'] = submitted_and_graded(section_report)
            data['Correct Items'] = if standard_data.assessment_summary(activity.cms_activity_id).empty?
                                      '--'
                                    else
                                      section_report.result(
                                        standard_data.assessment_summary(activity.cms_activity_id)
                                      )
                                    end
            data['Section'] = section_report.section_name
            data['Unit'] = section_report.lesson_name
            data['Assessment'] = activity.title
            extracted_data << data
          end
        end
        extracted_data
      end

      def self.submitted_and_graded(section_report)
        result = ''
        section_report.column_headers('standard').each do |key, _value|
          if key != :standard
            result = "#{section_report.submission_count(key)} of #{section_report.student_count}"
          end
        end
        result
      end

      def self.generate_csv(section_report)
        # "\uFEFF" is needed to add BOM to force Excel to realize this file is
        # encoded in UTF-8, so it respects special characters
        # https://stackoverflow.com/questions/30368173/ruby-how-to-generate-csv-files-that-has-excel-friendly-encoding
        CSV.generate("\uFEFF") do |csv_data|
          csv_data << SECTION_CSV_HEADERS
          extracted_data_from_section(section_report).each do |standard|
            csv_data << standard.values_at(*SECTION_CSV_HEADERS)
          end
          csv_data
        end
      end

      def self.extracted_data_from_drill_down(section_report)
        extracted_data = []
        section_report.activities.each do |activity|
          section_report.standards_data.each_row do |standard_data|
            data = {}
            data['Student Name'] = standard_data.student.name
            data['Standard'] = standard_data.standard.label
            data['Standard Definition'] = standard_data.standard.description
            data['Correct Percentage'] = section_report.percentage_format(
              standard_data.percent_correct_by_activity(activity.cms_activity_id)
            )
            data['Correct Vs Total'] = if standard_data.assessment_summary(activity.cms_activity_id).empty?
                                         '--'
                                       else
                                         section_report.result(
                                           standard_data.assessment_summary(activity.cms_activity_id)
                                         )
                                       end
            data['Section'] = section_report.section_name
            data['Unit'] = section_report.unit_name
            data['Assessment'] = activity.title
            extracted_data << data
          end
        end
        extracted_data
      end

      def self.generate_student_csv(section_report)
        # "\uFEFF" is needed to add BOM to force Excel to realize this file is
        # encoded in UTF-8, so it respects special characters
        # https://stackoverflow.com/questions/30368173/ruby-how-to-generate-csv-files-that-has-excel-friendly-encoding
        CSV.generate("\uFEFF") do |csv_data|
          csv_data << STUDENT_CSV_HEADERS
          extracted_data_from_drill_down(section_report).each do |standard|
            csv_data << standard.values_at(*STUDENT_CSV_HEADERS)
          end
          csv_data
        end
      end
    end
  end
end
