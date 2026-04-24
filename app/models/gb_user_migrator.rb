require 'etl/user_etl'
class GbUserMigrator < AbstractGbObjectMigrator
  def model_name
    'User'
  end
end
