module PendingTrueFalseEnhancedCheckable
  # TrueFalseEnhanced items are only instructor-gradable if the answer
  # is false and there's a pending correction, otherwise they should
  # behave like auto-graded items.
  private def pending_true_false_enhanced?(target_question)
    target_question.is_a?(
      MaestroActivityEngine::ActivityContent::TrueFalseEnhanced::Item
    ) && results.correctness(target_question.label) == 'pending'
  end

  private def results
    raise NotImplementedError, 'method :results must be defined by includer'
  end
end
