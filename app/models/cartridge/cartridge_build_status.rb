module Cartridge
  class CartridgeBuildStatus < ApplicationRecord
    include Radner::FilesS3Bucket

    VERSIONS = [
      MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
      MultiVersionCommonCartridge::CartridgeVersions::CC_1_2_0,
      MultiVersionCommonCartridge::CartridgeVersions::CC_1_3_0,
      MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_2_0,
      MultiVersionCommonCartridge::CartridgeVersions::THIN_CC_1_3_0
    ].freeze
    STATUS_SUCCESS = 'success'.freeze
    STATUS_FAILURE = 'failure'.freeze

    scope :success, -> { where(status: STATUS_SUCCESS) }

    belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
    belongs_to :program
    validates :status, inclusion: { in: [STATUS_SUCCESS, STATUS_FAILURE] }
    validates :file_name, presence: true, if: :success?
    validates :file_name, presence: false, unless: :success?
    validates :error_message, presence: false, if: :success?
    validates :error_message, presence: true, unless: :success?

    before_destroy :delete_file

    def success?
      status == STATUS_SUCCESS
    end

    def failure?
      status == STATUS_FAILURE
    end

    def file_path
      return '' unless has_file_name?

      File.join(
        'datafiles',
        M3::Application.config.current_deployed_env_name,
        'common_cartridges',
        file_name
      )
    end
  end
end
