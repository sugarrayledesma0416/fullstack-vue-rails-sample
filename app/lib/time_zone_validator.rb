class TimeZoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    all_time_zones = ActiveSupport::TimeZone.all.map(&:name)
    unless value.nil? || all_time_zones.include?(value)
      record.errors.add attribute, 'must be a valid time zone.'
    end
  end
end
