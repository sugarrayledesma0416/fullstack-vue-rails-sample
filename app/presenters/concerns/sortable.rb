module Sortable
  def sort_link_direction(column)
    if !current_sort_column.nil? && column == current_sort_column
      "#{link_sort_direction}ending"
    else
      'unsorted'
    end
  end

  def sort_link(column)
    base_url(sort_link_options(column))
  end

  private def sort_directions
    @sort_directions ||= %i[asc desc].freeze
  end

  private def sort_link_params(column)
    if valid_sort_column?(column)
      direction = current_sort_column == column ? next_sort_direction : default_sort_direction

      { sort_column: column, sort_direction: direction }
    else
      {}
    end
  end

  private def sort_direction
    current_sort_direction || default_sort_direction
  end

  private def current_sort_direction
    return @current_sort_direction if defined?(@current_sort_direction)

    direction = @req_params[:sort_direction]&.to_sym
    sort_directions.include?(direction) ? direction : nil
  end

  private def default_sort_direction
    sort_directions.first
  end

  private def next_sort_direction
    link_sort_direction == :asc ? :desc : :asc
  end

  private def link_sort_direction
    current_sort_direction || default_sort_direction
  end

  private def sort_column
    sort_columns[current_sort_column] || default_sort_column
  end

  private def current_sort_column
    return @current_sort_column if defined?(@current_sort_column)

    column = @req_params[:sort_column]&.to_sym
    @current_sort_column = valid_sort_column?(column) ? column : nil
  end

  private def valid_sort_column?(column)
    sort_columns.key?(column)
  end
end
