module StudentsHelper
  include ActionView::Helpers::TextHelper

  def format_table_row_class(counter)
    return "even_row" if ((counter % 2) == 0)
    "odd_row"
  end

  def format_table_col_class(counter)
    return "even_column" if ((counter % 2) == 0)
    "odd_column"
  end
end
