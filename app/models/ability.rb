class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    roles = user.roles.map(&:name)
    if roles.include?(Role::SUPPORT_REP) || roles.include?(Role::CUSTOMER_SERVICE) ||
        roles.include?(Role::SUPPORT_VENDOR)
      can :manage, HelpEntry
    end

    if roles.include?(Role::SUPPORT_REP)
      can :manage, Course
      can %i[show update], Support::CourseOwnersController
    end

    if roles.include?(Role::QUESTION_BANK_EDITOR)
      can :manage, QuestionBank
      can :manage, QuestionBankTopic
      can :manage, QuestionBankRevision
    end

    if roles.include?(Role::RESOURCE_EDITOR)
      can :manage, ResourceComponent
      can :report, A11yReportGeneratorController
      can :export, InstructorResourcesExportController
      can :bulk_upload, BulkResourcesController
    end

    if roles.include?(Role::VTEXT_CREATOR)
      can :vtext_generate, VtextDataFilesController
    end

    if roles.include?(Role::PROGRAM_CONFIG_MANAGER)
      can :manage, ProgramConfig
      can :view, ProgramConfigVersionsController
    end

    if roles.include?(Role::PHANTOM_ACTIVITY_DELETER)
      can %i[index create], PhantomActivityFixerController
    end

    if roles.include?(Role::AI_DEVELOPER)
      can %i[index create], AI::LiveData::GradingInputsController
      can %i[index rate_question], AI::LiveData::GradingInputRatingsController
      can %i[rate], AI::GradingSuggestionsController
      can %i[rate], AI::OverallCommentsController
      can %i[
        index
        create
        update
        generate_internal_grading_suggestions
        generate_internal_overall_comments
      ], AI::GradingPromptsController
      can %i[index show], AI::LiveData::GradingInputRatingReportsController
      can %i[index], AI::LiveData::GradingSuggestionPromptsController
      can %i[index], AI::LiveData::OverallCommentPromptsController
      can %i[index show], AI::InstructorGrading::SuggestionRatingReportsController
    end

    if roles.include?(Role::AI_GRADING_EDITOR)
      can %i[index create], AI::LiveData::GradingInputsController
      can %i[index rate_question], AI::LiveData::GradingInputRatingsController
      can %i[rate], AI::GradingSuggestionsController
      can %i[rate], AI::OverallCommentsController
    end

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
