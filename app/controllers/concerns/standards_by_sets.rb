module StandardsBySets
  extend ActiveSupport::Concern

  private def standards_by_sets_payload
    standards_by_sets_results.map do |set|
      set.standards.map do |standard|
        { standard_vendor_guid: standard.vendor_guid,
          standard_set_name: set.name,
          standard_number: standard.number,
          standard_label: standard.label,
          standard_description: standard.description }
      end
    end.flatten
  end

  private def standards_by_sets_results
    StandardSet.includes(:standards).find(standards_by_sets_params)
  end
end
