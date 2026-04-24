class SummaryCategoryPageObject
  attr_reader :element

  def initialize(element)
    @element = element
  end

  def name
    element.find('.test-category-name').text
  end

  def weight
    element.find('.test-category-weight').text
  end
end
