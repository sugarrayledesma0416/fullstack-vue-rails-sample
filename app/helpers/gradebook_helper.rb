module GradebookHelper

  include ApplicationHelper

  def format_as_decimal_without_trailing_zero (score_points_earned)
    return 0 if score_points_earned.is_a?(Float) && score_points_earned.nan?
    return score_points_earned if score_points_earned.is_a?(String)
    score_float_value = score_points_earned.to_f
    if  score_float_value == score_float_value.to_i
      return_value = score_float_value.to_i
    else
      return_value = score_float_value.to_f.round(1)
    end
    return_value
  end

  def format_due_date_time(score, format_type)
    format_date_time(score.due_date_time, format_type)
  end

  def format_as_percent_with_one_decimal(float, return_without_percent_sign=false)
    return '' unless float.is_a?(Float) || float.is_a?(BigDecimal)
    percent = number_to_percentage( (float * 100).round(3), :precision => 1)
    return percent.gsub('%','') if return_without_percent_sign
    percent
  end

  def format_mark(ratio)
    return '' if ratio.nil?
    case (ratio * 10).round(1).floor
    when 10,9 then 'A'
    when 8 then 'B'
    when 7 then 'C'
    when 6 then 'D'
    else 'F'
    end
  end
end
