class HelpRequestsPresenter

  attr_accessor :user, :status_scope, :type_scope, :request_groups, :section

  def initialize(section, user, status_scope = 'open', type_scope = :instructor_respondable)
    self.user = user
    self.status_scope = status_scope
    self.type_scope = type_scope
    self.request_groups = []
    self.section = section
  end

  def populate
    requests.each do |activity_id, request_list|
      self.request_groups << RequestInfoForActivity.new(request_list)
    end
    self
  end

  def help_requests_info
    request_groups.sort{ |a, b| a.created_at <=> b.created_at }
  end

  def requests
    #TODO: Find a cleaner way to construct these scopes.
    if status_scope == 'closed'
      results = user.help_requests.processed
    else
      results = user.help_requests.unprocessed
    end

    if type_scope == :instructor_respondable
      results = results.by_section(section).instructor_respondable
    else
      results = results.reported_problems
    end

    results.includes(activity: :lesson).group_by(&:activity_id)
  end
  private :requests

  class RequestInfoForActivity
    attr_accessor :requests, :activity

    delegate :id, :to => :activity, :prefix => true

    def initialize(help_requests)
      self.requests = help_requests
      self.activity = requests.first.activity
    end

    def activity_title
      activity.title
    end

    def count
      requests.size == 1 ? '' : "(#{requests.size})"
    end

    def anchor
      requests.size > 1 ? '' : "##{requests.first.helpable_item_id}"
    end

    def request_type
      request_types = requests.map(&:request_type)
      if request_types.uniq.size == 1
        humanize_type(request_types.first)
      else
        'varies'
      end
    end

    def created_at
      requests.map(&:created_at).min
    end

    def updated_at
      requests.map(&:updated_at).max
    end

    def comment
      requests.size > 1 ? 'varies' : requests.first.student_comment
    end

    def humanize_type(request_type)
      case request_type
      when 'request_help' then 'Help request'
      when 'request_review' then 'Review request'
      when 'report_technical_problem' then 'Technical problem report'
      when 'report_content_problem' then 'Content problem report'
      end
    end
    private :humanize_type
  end
end
