# By default, Psych (Yaml library) doesn't support serializing arbitrary
# classes when writing to a field defined as a yaml type.
#
# Symbol needs to be permitted in order to store data when enqueing
# Sidekiq jobs that sync records between m3 and the gradebook.
#
# ActiveSupport::HashWithIndifferentAccess is needed for jobs that
# do bulk creation of assignments, e.g. in Express Course Wizard or
# Assignment Wizard.
Rails.application.config.active_record.yaml_column_permitted_classes = [
  Symbol,
  ActiveSupport::HashWithIndifferentAccess
]
