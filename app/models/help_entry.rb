class HelpEntry < ApplicationRecord
  belongs_to :created_by, class_name: 'User'

  validates :page, presence: true, uniqueness: { case_sensitive: true }
  validate :validate_page

  validates :url, presence: true
  validate :validate_url

  def published?
    published
  end

  def self.pages_that_can_have_help
    pages = []
    exclusions = ['ua/', 'publishing', 'chat_click_logs', 'screencasts', 'plugin_public', 'media_items', 'jobs',
                  'instructor/instructor_resource_settings', 'instructor/categories', 'instructor/focus', 'flashcards', 'flashcards_activities', 'courses']

    controller_actions_from_routes.each_pair do |controller, actions|
      next if exclusions.any?{|exclusion| controller =~ /^#{exclusion}/}
      actions.each do |action|
        pages << controller + "#" + action
      end
    end
    pages.uniq
  end

  private

  def self.controller_actions_from_routes
    M3::Application.routes.routes.inject({}) do |controller_actions, route|
      (controller_actions[route.requirements[:controller]] ||= []) << route.requirements[:action]
      controller_actions
    end
  end


  def find_controller_if_exists(my_controller)
    route = M3::Application.routes.routes.detect { |route| route.requirements[:controller] == my_controller }
    route.requirements[:controller] unless route.nil?
  end

  def controller_exists?(my_controller)
    find_controller_if_exists(my_controller) != nil
  end

  def controller_action_exists?(my_controller, my_action)
    route = M3::Application.routes.routes.detect do |route|
      route.requirements[:controller] == my_controller &&
      route.requirements[:action] == my_action
    end
    route != nil
  end

  def validate_page
    return unless self.page.present?

    controller, action = self.page.split '#'

    if controller && action
      errors.add(:page, 'controller does not exist') unless controller_exists?(controller)
      if controller_exists?(controller)
        errors.add(:page, 'action does not exist') unless controller_action_exists?(controller, action)
      end
    else
      errors.add(:page, 'must be in the format "controller#action"')
    end
  end

  def prepend_http_to_url
    self.url = "http://" + self.url if self.url.split.grep(/^http(s)?:\/\//).empty?
  end

  def validate_url
    return unless url.present?

    prepend_http_to_url

    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      errors.add(:url, 'format is not valid')
    end
  end

end
