# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ApplicationRecord
  has_many :roles_users, :dependent => :delete_all
  has_many :users, :through => :roles_users

  ACCESS_GRANTOR           = 'access_grantor'.freeze
  AI_DEVELOPER             = 'ai_developer'.freeze
  AI_GRADING_EDITOR        = 'ai_grading_editor'.freeze
  ANNOUNCEMENT_CREATOR     = 'announcement_creator'.freeze
  APPLICATION_ADMIN        = 'application_admin'.freeze
  COMMON_CARTRIDGE_CREATOR = 'common_cartridge_creator'.freeze
  COURSE_PACKAGE_CREATOR   = 'course_package_creator'.freeze
  CUSTOMER_SERVICE         = 'customer_service'.freeze
  DEVELOPER                = 'developer'.freeze
  HOMEPAGE_EDITOR          = 'homepage_editor'.freeze
  PASSCODE_ADMIN           = 'passcode_admin'.freeze
  PHANTOM_ACTIVITY_DELETER = 'phantom_activity_deleter'.freeze
  PROGRAM_CONFIG_MANAGER   = 'program_config_manager'.freeze
  PROOFER                  = 'proofer'.freeze
  QUESTION_BANK_EDITOR     = 'question_bank_editor'.freeze
  RESOURCE_EDITOR          = 'resource_editor'.freeze
  REVIEWER                 = 'reviewer'.freeze
  SALES_MANAGER            = 'sales_manager'.freeze
  SALES_REP                = 'sales_rep'.freeze
  SITE_LICENSE_MANAGER     = 'site_license_manager'.freeze
  SITE_LICENSE_VIEWER      = 'site_license_viewer'.freeze
  SUPPORT_REP              = 'support_rep'.freeze
  SUPPORT_VENDOR           = 'support_vendor'.freeze
  UNRELEASED_UNIT_VIEWER   = 'unreleased_unit_viewer'.freeze
  VTEXT_CREATOR            = 'vtext_creator'.freeze

  def self.find_sales_rep(rep_username)
    username = rep_username.downcase
    username = 'oup' if username == 'oxford'
    username << "_admin"

    user = User.find_by_username(username)

    role = includes(:users).where(roles: { name: SALES_REP }, users: { username: username }).first

    role && role.users.first
  end
end
