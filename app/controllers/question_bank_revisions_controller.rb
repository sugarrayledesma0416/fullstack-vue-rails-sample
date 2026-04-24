class QuestionBankRevisionsController < ApplicationController
  include QuestionBankReturnTo

  before_action :require_user
  before_action :assign_topic_id, only: :index
  before_action :assign_question_bank, only: :index
  # This needs to go before the return in order to load things
  # for that method
  load_and_authorize_resource
  before_action :assign_revision_return_to, only: :index

  layout 'music_v1/default'

  def index
    @title = "Question Bank: #{@question_bank.title}"
    @revisions = @question_bank.question_bank_revisions.order('created_at DESC')
  end

  def download
    send_data(
      @question_bank_revision.uploaded_csv,
      type: 'text/csv',
      disposition: "attachment; filename=#{@question_bank_revision.upload_filename}"
    )
  end

  def approve
    current_live_revision = @question_bank_revision.activity.current_live_revision
    current_live_revision&.update!(status: 'archived')

    @question_bank_revision.update!(status: 'live')
    log_revision_change('live')
    redirect_to_revision_list
  end

  def reject
    @question_bank_revision.update!(status: 'rejected')
    log_revision_change('rejected')
    redirect_to_revision_list
  end

  def archive
    @question_bank_revision.update!(status: 'archived')
    log_revision_change('archived')
    redirect_to_revision_list
  end

  private def assign_topic_id
    @topic = QuestionBankTopic.find(params[:question_bank_topic_id])
  end

  private def assign_question_bank
    @question_bank = QuestionBank.find(params[:question_bank_id])
  end

  private def redirect_to_revision_list
    activity = @question_bank_revision.activity
    redirect_to(
      question_bank_topic_question_bank_question_bank_revisions_path(
        question_bank_topic_id: activity.question_bank_topic.id,
        question_bank_id: activity.id
      )
    )
  end

  private def log_revision_change(status)
    QuestionBankRevisionLog.create!(
      question_bank_revision_id: @question_bank_revision.id,
      status: status,
      user_id: current_user.id
    )
  end
end
