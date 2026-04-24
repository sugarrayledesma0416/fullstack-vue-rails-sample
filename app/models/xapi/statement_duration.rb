module Xapi
  class StatementDuration
    def initialize(statements)
      @statements = statements
    end

    def duration
      # In a typical use, when the activity is loaded we receive the verb 'initialized'
      # and when the student leaves the page, we receive the verb 'terminated'.
      # Let's call a session the time between an 'initialized' verb and a 'terminated' verb.
      # We then sum up the time of all the different sessions.
      #
      # But we don't always receive the 'terminated' verb neither we always receive
      # the 'initialized' verb.
      # Some examples:
      # 1. initialized, verb_1, verb_2, terminated, initialized, verb_3, terminated
      #    we have 2 sessions:
      #      [initialized, verb_1, verb_2, terminated]
      #      [initialized, verb_3, terminated]
      # 2. initialized, verb_1, verb_2, terminated, verb_3, terminated
      #    we miss an 'initialized' verb, but we can identify 2 sessions:
      #      [initialized, verb_1, verb_2, terminated]
      #      [verb_3, terminated]
      # 3. initialized, verb_1, verb_2, initialized, verb_3, terminated
      #    we miss an 'terminated' verb, but we can identify 2 sessions:
      #      [initialized, verb_1, verb_2]
      #      [initialized, verb_3, terminated]
      #
      # So we detect the start of a session when we detect an 'initialized' verb.
      # And we detect the end of a session when we detect a 'terminated' verb.
      #
      # We take the statements list and slice it into sessions (arrays of verbs).
      sessions = @statements.slice_when do |left_statement, right_statement|
        left_statement.verb == VERB_TERMINATED || right_statement.verb == VERB_INITIALIZED
      end.to_a
      sessions.sum { |session| session_time(session) }
    end

    private def session_time(statements)
      statements[-1].timestamp - statements[0].timestamp
    end
  end
end
