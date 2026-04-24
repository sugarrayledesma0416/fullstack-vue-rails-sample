class Ua::StudentWorkTransfersController < Ua::ActiveResourceController

  def work_transfer
    processor = WorkTransfer::Processor.new(params).process
    render :json => { message: processor.messages}, :status => processor.status
  end

  def completed_activities_per_section
    activities = WorkTransfer::Activity.new(params)
    render :json => { message: activities.messages, completed_activities: activities.completed_activities }, :status => activities.status
  end
end
