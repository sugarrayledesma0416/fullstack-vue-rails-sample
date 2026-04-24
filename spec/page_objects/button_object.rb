class ButtonObject
  delegate :click, to: :element
  attr_reader :element

  def initialize(element)
    @element = element
  end

  def enabled?
    ! disabled?
  end

  def disabled?
    ((element['class'].include? 'disabled-button') || element.disabled?)
  end
end
