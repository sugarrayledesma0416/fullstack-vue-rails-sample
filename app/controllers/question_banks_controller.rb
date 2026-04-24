class QuestionBanksController < ApplicationController
  include QuestionBankReturnTo

  before_action :require_user
  # This needs to go before the returns in order to load things
  # for those methods
  load_and_authorize_resource
  before_action :assign_topic, only: %i[new create edit update]
  before_action :assign_return_to, only: %i[create edit]
  before_action :assign_revision_return_to, only: :update

  layout 'music_v1/default'

  def new
    @question_bank = QuestionBank.new(question_bank_topic: @topic)
  end

  def edit; end

  def create
    @question_bank = uploader.question_bank
    if uploader.upload
      flash[:success] = 'Question Bank was successfully created'
      redirect_to_question_bank_preview
    else
      flash[:error] = 'Question Bank creation failed'
      render :new
    end
  end

  def update
    uploader.existing_question_bank = @question_bank
    if uploader.upload
      flash[:success] = 'Revision was successfully created'
      redirect_to_question_bank_preview
    else
      flash[:error] = 'Revision creation failed'
      render :edit
    end
  end

  private def uploader
    @uploader ||= QuestionBanks::Uploader.new(
      @topic, params[:uploaded_file], current_user
    )
  end

  private def assign_topic
    @topic = QuestionBankTopic.find(params[:question_bank_topic_id])
  end

  private def redirect_to_question_bank_preview
    redirect_to section_activity_path(
      id: @question_bank.id, popup: 1, section_id: 0
    )
  end
end
