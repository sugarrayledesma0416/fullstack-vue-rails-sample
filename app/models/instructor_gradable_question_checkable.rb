module InstructorGradableQuestionCheckable
  INSTRUCTOR_GRADABLE_CLASSES = [
    MaestroActivityEngine::ActivityContent::OpenEnded::Item,
    MaestroActivityEngine::ActivityContent::Recording::Question,
    MaestroActivityEngine::ActivityContent::VirtualChat::Item,
    MaestroActivityEngine::ActivityContent::PartnerChat::Item,
    MaestroActivityEngine::ActivityContent::SpeechRecListenRepeat::Item,
    MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item,
    MaestroActivityEngine::ActivityContent::Question::InlineOpenEndedContent::WriteOnLine,
    MaestroActivityEngine::ActivityContent::GroupChat::Item
  ].freeze

  private def instructor_gradable_type?(item)
    # Use `.is_a?` instead of to account for subclasses.
    INSTRUCTOR_GRADABLE_CLASSES.detect { |klass| item.is_a?(klass) }
  end
end
