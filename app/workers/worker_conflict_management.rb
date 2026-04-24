module WorkerConflictManagement
  def cache
    @cache ||= M3::Application.config.job_conflict_cache
  end

  def conflict?(conflict_keys)
    return unless cache
    conflict_keys.detect { |key| cache.keys(key).count.positive? }
  end

  def in_progress(cache_key)
    return unless cache
    cache.set(cache_key, true)
  end

  def completed_progress(cache_key)
    return unless cache
    cache.del(cache_key)
  end
end
