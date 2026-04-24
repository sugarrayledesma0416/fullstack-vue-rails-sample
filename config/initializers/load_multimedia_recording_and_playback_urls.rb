file_path = Rails.root.join("config", "multimedia_recording_and_playback_urls.yml")
raw_yaml = file_path.read
multimedia_yml = YAML.safe_load(raw_yaml, aliases: true)[Rails.env]
# extract the yaml configuration to a Rails configuration value and
# convert the Hash into an Object with methods for its keys
# without using something like hashie
# Reference:
# https://coderwall.com/p/74rajw/convert-a-complex-nested-hash-to-an-object
# https://stackoverflow.com/questions/28521571/create-nested-object-from-yaml-to-access-attributes-via-method-calls-in-ruby/40898373#40898373
config = JSON.parse(multimedia_yml.to_json, object_class: OpenStruct)

Rails.configuration.lossless_base_url = config.lossless_base_url
Rails.configuration.smartbook_recording_endpoint = "#{config.lossless_base_url}/smartbook"
Rails.configuration.multimedia = config
