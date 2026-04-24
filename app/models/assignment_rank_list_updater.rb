# This class was designed to update the rank of a group of
# instructor created activities, in the group we can also find
# regular activities but their ranks won't be updated; their rank will
# serve as a basis to calculate the new instructor created activity's rank.
class AssignmentRankListUpdater

  attr_accessor :current_index

  def initialize(params)
    # Every index of the following arrays is tied to the same index,
    # in the other arrays, e.g. in the second position of each array we
    # could have an instructor created activity, with assignment_id 99
    # and a rank of 3.
    # [145, 99, 101] => assignment ids
    # [9, 3, 5] => ranks
    # [instructor-created, instructor-created, regular] => activity types
    @assignment_ids = params[:assignment_ids]
    @ranks = params[:ranks].map {|rank| rank.to_i }
    @activity_types = params[:activity_types]
  end

  # Rules for this algorithm:
  # 1. If the first element rank is greater than the next element's rank
  # then update rank with next element's rank.
  # 2. If we are in the middle of 2 elements that have the same rank
  # then choose any of the adjacent ranks.
  # 3. For the rest, grab previous written out rank, add one and update
  # current element's rank.
  # List of possible cases:
  # ranks marked with * are instructor created activities,
  # the rest are regular activities.
  # [5*,  2,  3,  4*, 6* ] => [2*,  2,  3,  4*, 5*]
  # [2*,  3,  4,  5*, 6* ] => [2*,  3,  4,  5*, 6*]
  # [5*,  2,  3,  7*, 6* ] => [2*,  2,  3,  4*, 5*]
  # [5*,  2,  7*, 2,  6* ] => [2*,  2,  2*, 2,  3*]
  # [10,  9*, 10, 11, 12 ] => [10, 10*, 10, 11, 12]
  # [1*,  8,  9,  13, 8* ] => [1*,  8,  9, 13, 14*]
  # [1*,  6,  8,  1*, 11 ] => [1*,  6,  8,  9*, 11]
  def process
    @activity_types.each_with_index do |activity_type, index|
      if activity_type == 'instructor-created'
        self.current_index = index
        update_assignment(next_rank) if (update_first_rank? || between_a_tie?)
        update_assignment(previous_rank + 1) if use_previous_rank?
      end
    end
  end

  def use_previous_rank?
    !is_first? && (is_last? || !between_a_tie?)
  end
  private :use_previous_rank?

  def is_first?
    current_index == 0
  end
  private :is_first?

  def is_last?
    current_index == (@ranks.size - 1)
  end
  private :is_last?

  def between_a_tie?
    !is_first? && !is_last? && rank_tie?
  end
  private :between_a_tie?

  def rank_tie?
    previous_rank == next_rank
  end
  private :rank_tie?

  def update_first_rank?
    is_first? && @ranks[current_index] > next_rank
  end
  private :update_first_rank?

  def previous_rank
    @ranks[current_index - 1] unless is_first?
  end
  private :previous_rank

  def next_rank
    @ranks[current_index + 1] unless is_last?
  end
  private :next_rank

  def update_assignment(new_rank)
    Assignment.find(@assignment_ids[current_index]).update!(rank: new_rank)
    @ranks[current_index] = new_rank
  end
  private :update_assignment

end
