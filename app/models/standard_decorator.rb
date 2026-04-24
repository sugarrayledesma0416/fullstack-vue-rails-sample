class StandardDecorator < SimpleDelegator
  def display_number
    @display_number ||= display_number_fallback
  end

  # If the Standard does not have a number, search its ancestors to find the
  # closest relative with a number. Return the ancestor number + this Standard's
  # description.
  private def display_number_fallback
    return number if number.present?

    ancestor_guids =
      JSON.parse(additional_info)['additional_info']['ancestors'].split(',').reverse
    @ancestor_with_number = ancestor_guids.each do |guid|
      std = Standard.where(vendor_guid: guid).first

      break std if std.number.present?
    end

    "#{@ancestor_with_number.number}"
  end
end
