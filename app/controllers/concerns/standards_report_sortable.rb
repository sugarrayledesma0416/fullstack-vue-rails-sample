module StandardsReportSortable
  extend ActiveSupport::Concern

  included do
    # Set column header sort link parameters. Default direction is ascending.
    # Reverse the direction when the current column is already sorted.
    private def column_sort_params(column_name)
      direction = params[:sort] == column_name ? next_direction : 'asc'
      {
        direction: direction,
        sort: column_name
      }
    end

    private def next_direction
      params[:direction] == 'asc' ? 'desc' : 'asc'
    end
  end
end
