
class Array
  def intersect(other_array)
    left_array  = self.sort
    right_array = other_array.sort

    intersect_array = Array.new
    left_index = right_index = 0
    while left_index < left_array.size && right_index < right_array.size
      if left_array[left_index] == right_array[right_index]
        intersect_array << left_array[left_index]
        left_index += 1
        right_index += 1
      elsif left_array[left_index] < right_array[right_index]
        left_index += 1
      else
        right_index += 1
      end
    end
    intersect_array
  end
  
  def most_common_item
    return nil if empty?
    group_by do |e|
      e
    end.values.max_by(&:size).first
  end  

  # Return comma and 'and' separated list.
  def join_english_list
    english_list = ""
    if length > 2
      english_list = slice(0..-2).join(", ") + ", and " + last
    elsif length == 2
      english_list = join(" and ")
    elsif length == 1
      english_list = first
    end

    english_list
  end
end
