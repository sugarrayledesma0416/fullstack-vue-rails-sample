class SiteFunction
  attr_reader :name, :license_group_id

  def initialize(name, license_group_id)
    @name = name
    @license_group_id = license_group_id
  end
end
