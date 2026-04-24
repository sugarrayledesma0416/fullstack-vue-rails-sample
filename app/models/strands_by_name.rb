module StrandsByName
  def lessons_covered
    raise NotImplementedException
  end

  def strand_ids_by_name(strand_name, include_substrands = false)
    strands = lesson_strands(strand_name)
    substrands = include_substrands ? strands.flat_map(&:children).compact : []
    (strands + substrands).map(&:location)
  end

  def lesson_strands(strand_name)
    lessons_covered.each_with_object([]) do |lesson, strands|
      strands << lesson.toc_entries.detect do |strand|
        strand.title == strand_name || strand.name == strand_name
      end
    end.compact
  end
  private :lesson_strands
end
