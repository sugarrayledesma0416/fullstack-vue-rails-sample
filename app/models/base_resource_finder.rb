module BaseResourceFinder

  def base_scope
    builder = Resource.by_program(@program)
    builder = builder.by_file_type(@opts[:resource_format]) if @opts[:resource_format].present?
    builder = builder.by_source(@opts[:source])             if @opts[:source].present?
    builder = builder.by_lesson(@opts[:lesson_id])          if @opts[:lesson_id].present?
    builder = restrict_by_unit(builder)                     if @opts[:start_unit_id].present?
    builder = builder.by_component(@opts[:component_id])    if @opts[:component_id].present?
    builder
  end

  def all_sorted_by_unit_rank
    base_scope.sorted_by_unit_rank
  end

  def grouped_by_unit_type
    base_scope.group_by_unit
  end

  def grouped_by_lesson
    base_scope.group_by_lesson
  end

  def grouped_by_component
    base_scope.group_by_component
  end

  def grouped_by_file_type
    base_scope.group_by_file_type
  end

  def grouped_by_source
    base_scope.group_by_source
  end

  def restrict_by_unit(builder)
    if @opts[:start_unit_id].is_a? Array
      builder.multi_unit
    else
      builder.by_unit(@opts[:start_unit_id]).sorted_by_lesson
    end
  end
  private :restrict_by_unit
end
