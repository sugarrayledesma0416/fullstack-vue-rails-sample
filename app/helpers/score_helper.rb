module ScoreHelper
  def format_time_spent(time_spent)
    return '' if time_spent.blank?
    if (time_spent == 0)
      ''
    elsif (time_spent < 3600)
      '%1d:%02d' % [(time_spent / 60).floor, (time_spent % 60)]
    else
      '%1d:%02d:%02d' % [(time_spent / 3600).floor, (((time_spent % 3600) / 60)).floor, (time_spent % 60)]
    end
  end

  def format_current_score(score)
    return '' unless score
    return 'Pending' if (score.pending? || score.partial_pending?)
    format_as_percent_with_one_decimal(score.net_ratio)
  end
end
