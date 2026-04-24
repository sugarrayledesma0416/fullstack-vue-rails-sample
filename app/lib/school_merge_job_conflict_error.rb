# if StudentWorkTransfer interferes with SchoolMerge or
# DropLowScores job interferes with SchoolMerge
# they will throw this error which
# will force a retry;
# if either StudentWorkTransfer or DropLowScore
# jobs are running then SchoolMerge can't
# and will throw this error to force a retry
class SchoolMergeJobConflictError < StandardError
end
