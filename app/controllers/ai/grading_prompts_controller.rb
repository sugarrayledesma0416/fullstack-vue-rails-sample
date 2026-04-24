module AI
  class GradingPromptsController < ApplicationController
    before_action :require_user

    layout 'music_v1/default'

    def index
      authorize! :index, self.class

      # Ensure all AI experiments are synced before displaying
      GradingSuggestionPrompt.sync_experiment_prompts_if_needed
      OverallCommentPrompt.sync_experiment_prompts_if_needed

      @presenter = GradingPromptsPresenter.new
    end

    def new
      authorize! :create, self.class

      # Create new prompt based on current prompt
      current_prompt = prompt_class.current
      @prompt = prompt_class.new(
        template_body: current_prompt.template_body,
        model: current_prompt.model,
        temperature: current_prompt.temperature,
        active_for_instructor_grading: false
      )
    end

    def edit
      authorize! :update, self.class

      @prompt = prompt_class.find(params[:id])

      # Prevent editing AI Core prompts
      return unless @prompt.source == 'ai_core'

      flash[:error] = 'Cannot edit AI Core prompts'
      redirect_to ai_grading_prompts_path
      nil
    end

    def create
      authorize! :create, self.class

      @prompt = prompt_class.new(safe_create_params)

      if @prompt.save
        handle_active_flag
        flash[:notice] = 'Successfully saved new experimental prompt'
        redirect_to ai_grading_prompts_path
      else
        flash[:error] = 'Failed to save new prompt'
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize! :update, self.class

      @prompt = prompt_class.find(params[:id])

      @prompt.update!(safe_update_params)
      handle_active_flag
      redirect_to ai_grading_prompts_path
    end

    def generate_internal_grading_suggestions
      authorize! :generate_internal_grading_suggestions, self.class

      prompt = GradingSuggestionPrompt.find(params[:grading_prompt_id])

      AI::LiveData::GradingSuggestionsForPromptGenerator.new(
        prompt
      ).generate

      flash[:notice] = 'Successfully scheduled grading suggestions generation'
      redirect_to ai_grading_prompts_path
    end

    def generate_internal_overall_comments
      authorize! :generate_internal_overall_comments, self.class

      prompt = OverallCommentPrompt.find(params[:grading_prompt_id])

      AI::LiveData::OverallCommentsForPromptGenerator.new(
        prompt
      ).generate

      flash[:notice] = 'Successfully scheduled overall comments generation'
      redirect_to ai_grading_prompts_path
    end

    # Only one prompt can be active for instructor grading. If the current
    # prompt is being set to the active one, find the existing active one
    # and make it not active.
    private def handle_active_flag
      return unless @prompt.active_for_instructor_grading

      # Prevent M3 prompts from being set as active if AI Core is managing prompts
      if prompt_class.using_ai_core_source?
        @prompt.update!(active_for_instructor_grading: false)
        flash[:warning] = 'Cannot set M3 prompt as active while AI Core is managing prompts'
        return
      end

      # Deactivate other active prompts
      prompt_class.where(active_for_instructor_grading: true).find_each do |prompt|
        next if prompt.id == @prompt.id

        prompt.update!(active_for_instructor_grading: false)
      end
    end

    private def safe_create_params
      permitted_params = params.require(:prompt).permit(
        :active_for_instructor_grading,
        :model,
        :temperature,
        :template_body,
        :provider
      )

      # Set defaults for new prompts
      result = permitted_params.merge(
        model: permitted_params[:model] || VHL::AI::Constants::Models::OpenAI::GPT_4O,
        temperature: permitted_params[:temperature] || VHL::AI::Constants::Parameters::Temperature::CONSERVATIVE
      )

      # Handle provider parameter by encoding it in the model field
      if permitted_params[:provider].present?
        result[:model] = "#{result[:model]}|provider:#{permitted_params[:provider]}"
      end

      result.except(:provider)
    end

    private def safe_update_params
      params.require(:prompt).permit(:active_for_instructor_grading)
    end

    private def prompt_class
      if params[:prompt_type] == 'overall'
        OverallCommentPrompt
      else
        GradingSuggestionPrompt
      end
    end
  end
end
