
class Numeric

  def round_down_to(nearest = 10)
    remainder = self % nearest
    return self if remainder == 0
    (self - remainder)
  end

  def round_up_to(nearest = 10)
    remainder = self % nearest
    return self if remainder == 0
    (self - remainder + nearest)
  end

end
