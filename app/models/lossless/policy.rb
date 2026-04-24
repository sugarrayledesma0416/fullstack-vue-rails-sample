module Lossless
  class Policy
    attr_accessor :cache_key, :user

    def initialize(cache_key, user)
      self.cache_key = cache_key
      self.user = user
    end

    def token
      return @token if defined?(@token)
      client = Client.new
      existing_token = client.get_token(cache_key)
      @token = (existing_token.present? && existing_token) || client.send_policy(policy_data)
    end

    def policy_data
      {
        cache_key: cache_key,
        read_policy: read_policy,
        user_guid: user.guid,
        user_type: user.base_account_type,
        write_policy: write_policy
      }
    end

    def read_policy
      if user.student?
        { any: [my_user_rule, my_instructors_rule].compact }
      else
        { any: [my_user_rule, my_section_instructors_read_rule].compact }
      end
    end

    def write_policy
      if user.student?
        { all: [my_user_rule, enrolled_sections_rule] }
      else
        { all: [my_user_rule, my_section_instructors_write_rule] }
      end
    end

    private def my_user_rule
      {
        metadata: { user_guid: user.guid }
      }
    end

    # Anything from a section I'm enrolled into, and anything from section 0.
    private def enrolled_sections_rule
      {
        metadata: { section_guid: user.active_sections.map(&:guid).append('0') }
      }
    end

    # Anything my instructors recorded in a section I'm enrolled into.
    private def my_instructors_rule
      return if user.active_sections.empty?
      {
        metadata: {
          user_guid: user.active_sections.map { |section| section.instructor.guid },
          section_guid: user.active_sections.map(&:guid)
        }
      }
    end

    private def my_section_instructors_read_rule
      sections_guids = user.sections.where(section_instructors: { is_archived: false }).pluck(:guid)
      return if sections_guids.empty?
      { metadata: { section_guid: sections_guids } }
    end

    private def my_section_instructors_write_rule
      sections = user.sections.where(section_instructors: { is_archived: false })
      {
        metadata: {
          section_guid: sections.pluck(:guid).append('0')
        }
      }
    end
  end
end
