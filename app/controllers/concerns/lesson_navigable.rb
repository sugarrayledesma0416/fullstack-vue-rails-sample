module LessonNavigable
  extend ActiveSupport::Concern

  # 12 hours TTL
  LESSON_NAVIGABLE_REDIS_TTL = 43_200
  TOC_NAVIGATION_KEY = 'lesson_navigation_toc'.freeze
  GRADEBOOK_NAVIGATION_KEY = 'lesson_navigation_gradebook'.freeze

  def load_activities_toc_navigation_data
    toc_data['activities_toc_data'] || {}
  end

  def load_assessments_toc_navigation_data
    toc_data['assessments_toc_data'] || {}
  end

  def load_gradebook_navigation_data
    gradebook_data['gradebook_navigation_data'] || {}
  end

  def update_gradebook_navigation(gradebook_navigation_data)
    new_gradebook_navigation_data = { gradebook_navigation_data: }
    cache_manager(GRADEBOOK_NAVIGATION_KEY).cache_put(
      current_program.id.to_s,
      new_gradebook_navigation_data.to_json,
      LESSON_NAVIGABLE_REDIS_TTL
    )
    @gradebook_data = nil
  end

  def update_toc_lesson_navigation(
    activities_toc_data: {},
    assessments_toc_data: {}
  )
    toc_data_update = {
      'activities_toc_data' => load_activities_toc_navigation_data,
      'assessments_toc_data' => load_assessments_toc_navigation_data
    }
    trigger_update = false

    if activities_toc_data.present? &&
       toc_data_update['activities_toc_data'] != activities_toc_data.stringify_keys
      toc_data_update['activities_toc_data'] = activities_toc_data
      trigger_update = true
    end
    if assessments_toc_data.present? &&
       toc_data_update['assessments_toc_data'] != assessments_toc_data.stringify_keys
      toc_data_update['assessments_toc_data'] = assessments_toc_data
      trigger_update = true
    end
    if trigger_update
      cache_manager(TOC_NAVIGATION_KEY).cache_put(
        current_program.id.to_s,
        toc_data_update.to_json,
        LESSON_NAVIGABLE_REDIS_TTL
      )
      @toc_data = nil
    end
  end

  private def cache_manager(navigation_key)
    @cache_manager = {} unless defined? @cache_manager

    @cache_manager[navigation_key] ||= CacheManager.new(
      "#{navigation_key}:#{current_user.id}"
    )
  end

  private def toc_data
    return @toc_data if defined?(@toc_data) && !@toc_data.nil?

    @toc_data = retrieve_data(TOC_NAVIGATION_KEY)
  end

  private def gradebook_data
    return @gradebook_data if defined?(@gradebook_data) && !@gradebook_data.nil?

    @gradebook_data = retrieve_data(GRADEBOOK_NAVIGATION_KEY)
  end

  private def retrieve_data(navigation_key)
    stored_gradebook_data = cache_manager(navigation_key).cache_get(current_program.id.to_s)
    if stored_gradebook_data
      JSON.parse(stored_gradebook_data)
    else
      {}
    end
  end
end
