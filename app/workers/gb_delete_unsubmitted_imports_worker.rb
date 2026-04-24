class GbDeleteUnsubmittedImportsWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  # This worker is meant to delete bad imports from the 2017-12-21 ETL.
  #   The problem imports were scores created in m3 for unsubmitted/due
  #   work. These don't have to exist in the gradebook engine, and they
  #   were imported with 'late_work_accepted' = true, which can cause
  #   subsequent late submissions for the same activity to appear as
  #   though they're not late and to have any late penalty waived.

  MOST_RECENT_SCORE_ACTION_QUERY = %((select sa1.* from score_actions sa1
               left join score_actions sa2
               on sa1.section_id = sa2.section_id
               and sa1.user_id = sa2.user_id
               and sa1.activity_id = sa2.activity_id
               and sa1.id < sa2.id
               where sa2.id is null)
               as score_actions).freeze

  STATS_DATA = { vhl_component: 'gradebook_v2',
                 environment: Rails.env,
                 application: 'M3' }.freeze

  def perform(section_id)
    bad_import_ids = bad_imports(
      GradebookEngine::ScoreAction.from(MOST_RECENT_SCORE_ACTION_QUERY),
      section_id
    )

    bad_import_ids.each_slice(200) do |deleted_score_action_ids|
      send_stats(section_id: section_id,
                 mae_40714_deleted_score_action_ids: deleted_score_action_ids)

      GradebookEngine::ScoreAction.where(id: deleted_score_action_ids).delete_all
    end

    # Make a note of the bad imports that weren't deleted.
    remaining_bad_import_ids = bad_imports(GradebookEngine::ScoreAction, section_id)

    if remaining_bad_import_ids.size.positive?
      send_stats(section_id: section_id,
                 mae_40714_remaining_score_action_ids: remaining_bad_import_ids)
    end
  end

  private def bad_imports(relation, section_id)
    relation
      .where(section_id: section_id)
      .where("score_actions.action->>'type' = 'import' and (score_actions.summation->>'submitted_at') is null")
      .pluck(:id).sort
  end

  private def send_stats(hash_to_merge)
    STATS_PROXY.info(STATS_DATA.merge(hash_to_merge))
  end
end
