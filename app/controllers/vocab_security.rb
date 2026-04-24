module VocabSecurity
  def require_vocab_license(message)
    unless access_guardian.has_vocab_words?
      flash[:error] = "You do not have access to #{message}."
      redirect_to BestDefaultPath.best_default_path(
        current_user, current_program, current_section, session
      )
    end
  end
end
