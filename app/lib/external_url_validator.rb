class ExternalUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value =~ %r{^(http|https|ftp):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$}
    record.errors.add(attribute, 'is invalid')
  end
end
