class BulkResourcesCreationTrackerSerializer < ActiveModel::Serializer
  attributes :creation_in_progress, :state, :logs, :progress

  def creation_in_progress
    object.present? && %w[completed failed processing_files].exclude?(object.state)
  end

  def logs
    object.logs.present? ? JSON.parse(object.logs)['data'] : []
  end

  def progress
    object.logs.present? ? JSON.parse(object.logs)['progress'] : 0
  end
end
