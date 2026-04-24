class PageObject
  include RSpec::Matchers
  include FeatureSpecScrollable
  include RspecJsCommonHelpers

  attr_reader :page

  def initialize(page)
    @page = page
  end
end
