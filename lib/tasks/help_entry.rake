
namespace :help_entry do

  desc "List all controllers and their actions"
  task :list_controllers_and_actions => :environment do

    @controller_actions = ActionController::Routing::Routes.routes.inject({}) do |controller_actions, route|
      (controller_actions[route.requirements[:controller]] ||= []) << route.requirements[:action]
      controller_actions
    end

    exclusions = ['ua/', 'publishing', 'chat_click_logs', 'screencasts', 'plugin_public', 'media_items', 'jobs',
                  'instructor/instructor_resource_settings', 'instructor/categories', 'instructor/focus', 'flashcards', 'flashcards_activities', 'courses']

    @controller_actions.each_pair do |controller, actions|
      next if exclusions.any?{|exclusion| controller =~ /^#{exclusion}/}
      actions.each do |action|
        puts controller + "#" + action
      end
    end
  end
end
