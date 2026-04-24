module Enumerable
  def all_same?
    blank? || uniq.count == 1
  end

  def vary?
    present? && uniq.count > 1
  end

  def have_different_values_for?(attribute_name)
    map { |element| element.send(attribute_name) }.vary?
  end

  def hash_map(&block)
    map(&block).to_h
  end
end
