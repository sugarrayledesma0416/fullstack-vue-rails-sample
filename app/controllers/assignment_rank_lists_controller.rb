class AssignmentRankListsController < ApplicationController

  def edit
    @assignments = Assignment.by_type(Activity)
      .where(due_date: params[:due_date].to_date, section_id: params[:section_id])
      .where("activities.toc_location = ?", params[:toc_location])
      .order('assignments.rank, activities.toc_location_rank')
    render layout: false
  end

  def update
    rank_list_updater = AssignmentRankListUpdater.new(params).process
    flash[:notice] = "Activity(ies) assigned successfully."
    render :json => {load_rank_list: false}
  end
end
