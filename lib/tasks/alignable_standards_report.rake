namespace :alignable_standards do
  require 'csv'
  desc 'Create list of alignable standards'
  task standards_list: :environment do |_task|
    ab_client = MaestroActivityEngine::ABConnect::Client.new
    alignable_standards = ab_client.fetch_alignable_standards(0, 100).with_indifferent_access
    count = alignable_standards[:meta][:count]
    offset = alignable_standards[:meta][:offset]
    guids = []

    p "DATA COUNT FROM API meta: #{count}"
    CSV.open('alignable_standards_guids.csv', 'w') do |csv|
      until offset >= count
        offset += alignable_standards[:meta][:limit]
        alignable_standards[:data].each do |standard_data|
          guids << standard_data[:id]
          csv << [standard_data[:id]]
        end
        alignable_standards = ab_client.fetch_alignable_standards(offset, 100).with_indifferent_access
      end
    end
    p "COMPLETE LIST SIZE: #{guids.count}"
    p "UNIQ LIST COUNT: #{guids.uniq.count}"
  end
end
