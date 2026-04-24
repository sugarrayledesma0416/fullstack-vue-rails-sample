class AttemptConfig < ApplicationRecord
  belongs_to :attempt

  enum artifact_sharing_status: {
    not_shared: 0,
    partial: 1,
    success: 2,
    failed: 3,
    in_progress: 4
  }
end
