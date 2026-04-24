module VocabTools
  class UserDefinedWordsController < ApplicationController
    before_action :require_user

    def create
      render json: current_user.user_defined_words.create!(create_params)
    end

    def update
      word = current_user.user_defined_words.where(id: params[:id]).first
      if word.nil? || word.update(update_params)
        head :ok
      else
        render json: word, status: :unprocessable_entity
      end
    end

    def destroy
      word = current_user.user_defined_words.where(id: params[:id]).first
      word && UserDefinedWord.destroy(word.id)
      head :ok
    end

    private def create_params
      params.permit(
        :lesson_id,
        :pinyin,
        :target,
        :translation,
        :definition
      ).merge(
        program_id: current_program.id
      )
    end

    private def update_params
      params.permit(
        :pinyin,
        :target,
        :translation,
        :definition
      )
    end
  end
end
