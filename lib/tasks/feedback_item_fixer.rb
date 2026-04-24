class FeedbackItemFixer

  def initialize
    @feedback_items = []
  end
  
  def duplicate_feedback_items
    @feedback_items = FeedbackItem.find(:all, 
                                        :select => "count(*) AS record_count, user_id, attempt_id, question_label",
                                        :having => "record_count > 1",
                                        :group  => "user_id, attempt_id, question_label")
  end

  def total_to_fix
    @feedback_items.inject(0) {|count, feedback_item| count += feedback_item.record_count.to_i; count}
  end

  def perform
    @feedback_items.each do |feedback_item|
      RecordFixer.new(feedback_item.user_id, feedback_item.attempt_id, feedback_item.question_label).fix
    end
  end

  class RecordFixer
    def initialize(user_id, attempt_id, question_label)
      @duplicate_items = FeedbackItem.find(:all, :conditions => { :user_id => user_id, 
                                                                  :attempt_id => attempt_id,
                                                                  :question_label => question_label })
    end

    def fix
      if @duplicate_items.size > 0
        set_winner
        if @winner  
          update_winner
          destroy_defeated_records
        end
      end
    end

    def set_winner
      @winner = winner_by_points_earned
      @winner = winner_by_oldest(@winner) if draw_exists_with?(@winner)
    end
    private :set_winner

    def winner_by_points_earned
      @duplicate_items.max{ |a, b| a.points_earned.to_f <=> b.points_earned.to_f }
    end
    private :winner_by_points_earned

    def draw_exists_with?(winner)
      draw_record = @duplicate_items.detect{ |item| item.id != winner.id && item.points_earned == winner.points_earned }
      draw_record.present?
    end
    private :draw_exists_with?

    def winner_by_oldest(prev_winner)
      draws = @duplicate_items.select{ |item| item.points_earned == prev_winner.points_earned }
      draws.min{ |a, b| a.id <=> b.id }
    end
    private :winner_by_oldest

    def update_winner
      other_records = defeated_records
      if @winner.inline_corrections.to_s.empty?
        with_data = other_records.detect{ |item| item.inline_corrections.present? }
        @winner.inline_corrections = with_data.inline_corrections if with_data
      end
      if @winner.comment.to_s.empty?
        with_data = other_records.detect{ |item| item.comment.present? }
        @winner.comment = with_data.comment if with_data
      end
      if @winner.recording_id.nil?
        with_data = other_records.detect{ |item| item.recording_id.present? }
        @winner.recording_id = with_data.recording_id if with_data
      end
      if @winner.attachment_id.nil?
        with_data = other_records.detect{ |item| item.attachment_id.present? }
        @winner.attachment_id = with_data.attachment_id if with_data
      end
      @winner.save
    end
    private :update_winner

    def destroy_defeated_records
      defeated_records.each{ |item| item.destroy }
    end
    private :destroy_defeated_records

    def defeated_records
      @duplicate_items.select{ |item| item.id != @winner.id }
    end
    private :defeated_records

  end
end
