# extend your controller by adding the line:
# has_help
# all actions in the controller will be assumed to have help,
# and they will receive a help url (if defined), tagged by page = controller#action
module HasHelp
  extend ActiveSupport::Concern

  included do
    helper_method :show_support_center_link?
  end

  def has_help?
    true
  end

  def contextual_help_url(custom_page = nil)
    page = custom_page.nil? ? controller_action : custom_page
    help_entry = HelpEntry.where(page: page, published: true).first

    @contextual_help_url = ''
    @contextual_help_url = help_entry.url unless help_entry.nil?
  end

  def show_support_center_link?
    user_agent = UserAgent.parse(request.user_agent)
    user_agent.browser == 'Chrome' &&
      user_agent.version >= UserAgent::Version.new('42.0')
  end

  private

  def controller_action
    self.controller_path.to_s + '#' + request[:action]
  end
end
