Rails.application.routes.draw do
  resources :phantom_activity_fixer, only: %i[index create]

  root to: 'home#front'
  mount MaestroActivityEngine::Engine => "/maestro_activity_engine"
  mount GradebookEngine::Engine => "/gradebook"
  mount Hicks::Engine => "/vhl_audio"
  mount Diller::Engine => "/diller"
  mount Music::Engine => "/music"

  get '/' => 'home#front'

  mount Dangerfield::Engine => '/dangerfield'

  # Errors
  get '/404' => 'server_errors#show'
  get '/403' => 'server_errors#show'
  get '/401' => 'server_errors#show'
  get '/500' => 'server_errors#show'
  get '/422' => 'server_errors#show'

  post '/500' => 'server_errors#show'

  # Load balancer health test.
  get '/health' => 'health_check#health_check'
  get '/elb_health' => 'health_check#elb_health_check'

  get '/ua_home' => 'home#ua_home', as: :ua_home
  post '/remote_logout' => 'user_sessions#remote_destroy', as: :remote_logout
  get 'terms_of_use' => 'home#terms_of_use', as: :terms_of_use

  get 'toggle-program-nav' => 'features#toggle_program_nav'
  get 'feature-flags' => 'feature_flags#index', as: :feature_flags

  namespace :ai do
    namespace :speech_to_text do
      get 'client_token/new' => 'client_token#new', as: :new_client_token
    end
  end

  namespace :support do
    resources :courses, only: %i[index edit update]
    resources :course_owners, param: :instructor_guid, only: %i[show update]
  end

  # assessment question bank management
  resources :question_bank_topics, only: %i[index show edit update new create] do
    member do
      get :topic_mappings
    end
    collection do
      get :concept_download
      get :topic_download
      get :topics_csv, defaults: { format: :csv }
      get :concepts_csv, defaults: { format: :csv }
      get :upload
      post :import
    end
    resources :question_banks, only: %i[new create update edit] do
      resources :question_bank_revisions, only: %i[index]
    end
  end

  resources :question_bank_topics_concepts, only: [] do
    collection do
      get :upload
      post :import
    end
  end

  resources :question_bank_revisions, only: [] do
    member do
      get :download
      post :approve
      post :reject
      post :archive
    end
  end

  # Resources
  scope 'programs/:program_id/section/:section_id' do
    resources :resources, only: :index do
      member do
        get :download_section
      end
    end
  end

  namespace :lti do
    scope ':program_id/sections/:section_guid' do
      get(
        'deep_link_sessions' => 'deep_link_sessions#init',
        as: :deep_link_session_init
      )
      get(
        'sync_settings' => 'gradebook_sections#sync_settings',
        as: :gradebook_section_sync_settings
      )
      get(
        'instructor_dashboard' => 'instructor_dashboard#index',
        as: :instructor_dashboard
      )
      get(
        'student_dashboard' => 'student_dashboard#index',
        as: :student_dashboard
      )
    end
    scope ':program_id' do
      get(
        'deep_link_sessions' => 'deep_link_sessions#terminate',
        as: :terminate_deep_link_session
      )
    end
    resource :deep_link_jwt, only: :create
    resource :resource_link, only: :show
  end

  get '/resources/ajax/programs/:program_id' => 'resources#ajax_resources', as: :ajax_resources
  get '/resources/programs/:program_id' => 'resources#index', as: :instructor_program_resources
  get '/resources/programs/:program_id/download/:id' => 'resources#download', as: :download_resource
  get '/resources/programs/:program_id/download_multiple' => 'resources#download_multiple', as: :download_multiple_resources

  get '/instructor/mycontent/:program_id' => 'instructor/created_activities#index', as: :instructor_mycontent
  get '/instructor/shared_content/:program_id' => 'instructor/created_activities#shared_content_index', as: :instructor_shared_content

  # Cartridge
  namespace :cartridge do
    resources :launches, only: %i[show], param: :resource_link_id
    resources :sections, only: [] do
      resources :activities, only: [:show], as: :activity, path: nil do
        member do
          post :save
          get :practice
          get :answer_keys
          post :re_try
          post :finalize
          post :diagnostic_feedback
        end
      end
      post '/activities/:id' => 'activities#submit', constraints: { id: /\d+/ }
    end
    namespace :instructor do
      resources :sections, only: [] do
        resources :grading, only: [:show]
        resource :course_settings, only: %i[update]
      end
    end
    namespace :support do
      resources :programs, only: %i[index] do
        match '/exporter' => 'exporter#index', as: :exporter, via: :get
        match '/exporter/export' => 'exporter#export', as: :exporter_export, via: :get
      end
    end
    match '/activity/:id/access_denied' => 'activities#access_denied', as: :access_denied, via: :get, constraints: { id: /\d+/ }
    match '/closed_course' => 'launches#closed_course', as: :closed_course, via: :get
  end


  # Creates a signed url for announcement attachements.
  get '/announcements/sections/:section_id/download/:id' => 'announcements#download', as: :download_announcement_attachment

  # Create instructor dashboard announcements
  resources :dashboard_announcements, except: [:show]

  # Composition attachment
  resources :composition_attachments, only: [:create, :destroy]
  get '/allowed_file_types' => 'composition_attachments#file_types', as: :file_types

  # Mobile app
  get '/mobile_app/:program_id' => 'mobile_app#show', as: :mobile_app

  # Help requests
  resources :help_requests, only: [:create, :destroy]
  # when students get their help request index, they need to be within a section
  get '/section/:section_id/help_requests' => 'help_requests#index', as: :help_requests_index
  get 'reported_problems/:program_id' => 'reported_problems#index', as: :reported_problems

  # WTF
  get '/resources/programs/:program_id/new' => 'resources#new', as: :new_resource
  post '/resources/programs/:program_id/create' => 'resources#create', as: :create_resource
  get '/resources/programs/:program_id/edit/:id/' => 'resources#edit', as: :edit_resource
  put '/resources/programs/:program_id/update/:id' => 'resources#update', as: :update_resource
  delete '/resources/programs/:program_id/delete/:id' => 'resources#destroy', as: :delete_resource

  ## Routes with no section
  get '/sections/:section_id/dashboard/:program_id' => 'sections#no_section_dashboard_show', as: :no_section_student_dashboard
  get '/sections/:section_id/calendar/:program_id' => 'sections#no_section_calendar_show', as: :no_section_calendar
  get '/sections/0/assessments/:program_id' => 'sections#no_section_assessments_show', as: :no_section_assessments

  # Media items
  resources :media_items, only: [:show] do
    member do
      get :svg_content
    end
  end
  get '/media_items/:rails_env/:media_type/:id_part1/:id_part2/vocab_tutorial_iframe.html' => 'activities#vocab_tutorial_iframe'

  namespace :media do
    post '/media_item_uploads/create_image' => 'media_item_uploads#create_image'
    post '/media_item_uploads/create_assessment_recording' => 'media_item_uploads#create_assessment_recording'
    post '/student_uploads/create_svr_video' => 'student_uploads#create_svr_video'
    post '/student_uploads/delete_svr_video' => 'student_uploads#delete_svr_video'
    post '/instructor_uploads/create_file' => 'instructor_uploads#create_file'
    post '/instructor_uploads/delete_file' => 'instructor_uploads#delete_uploaded_file'
    get '/instructor_uploads/file_signed_url' => 'instructor_uploads#file_signed_url'
  end

  # Program content
  resources :lessons, only: [:show] do
    resources :strands, only: [:index]
  end

  get '/courses/:course_id/sections/:section_id/study_schedule' => 'sections#study_schedule', as: :study_schedule
  get '/courses/:course_id/sections/:section_id/study_schedule/event_calendar/:year_month' => 'sections#show_calendar', as: :calendar
  get '/course_list_for/:current_school' => 'courses#ajax_course_list', as: :ajax_course_list
  put '/users/:id/update_gender' => 'users#update_gender', as: :update_user_gender
  get '/students/:id/update_avatar/' => 'students#update_student_avatar', as: :update_student_avatar

  namespace :jr do
    resources :courses, only: [] do
      get '/sections/:section_id' => 'sections#show', as: :section
    end

    scope '/:program_id' do
      scope '/sections/:section_id' do
        resources :ebooks, only: :index
      end
      # Version without section_id provides backwards compatiblity for
      # bookmarks, external links.
      resources :ebooks, only: :index
    end

    resources :sections, only: [] do
      resources :announcements, only: :show
      resources :assessments, only: :index
      resource :grownups, only: :show
      resources :programs, only: [] do
        resource :content, only: :show, controller: :content
        resources :lessons, only: %i[index show]
        resources :strands, only: :show
      end
      get 'study_schedule' => 'sections#study_schedule', as: :study_schedule
      get 'study_schedule/event_calendar/:year_month' => 'sections#show_calendar', as: :calendar
    end
    scope 'programs/:program_id/section/:section_id' do
      resources :resources, only: :index
    end
  end

  namespace :spr do
    resources :sections, only: [] do
      resources :activities, only: [:show], as: :activity, path: nil do
        member do
          post :save
          get :practice
          get :answer_keys
          post :re_try
          post :finalize
          post :diagnostic_feedback
        end
      end
      post '/activities/:id' => 'activities#submit', constraints: { id: /\d+/ }
    end
  end

  resources :courses, only: [] do
    get '/sections/:section_id' => 'sections#show', as: :section
    get '/sections/:section_id/new_dashboard/assignments' => 'new_student_dashboard#assignments', as: :new_student_dashboard_assignments
    get '/sections/:section_id/new_dashboard/assignments/group/:included_activity_id' => 'new_student_dashboard#unit_assignments', as: :new_student_dashboard_unit_assignments
    get '/sections/:section_id/new_dashboard/student_progress' => 'new_student_dashboard#progress', as: :student_progress
    get '/sections/:section_id/new_dashboard/notifications' => 'new_student_dashboard#notifications', as: :new_student_dashboard_notifications
    get '/sections/:section_id/assignments_by_due_date' => 'new_student_dashboard#assignments_by_due_date', as: :assignments_by_due_date
    get '/sections/:section_id/past_assignment_summaries' => 'new_student_dashboard#past_assignment_summaries', as: :past_assignment_summaries
  end

  resources :distance_edits, only: :create

  # Resources that requires a section
  resources :sections, only: [] do
    get "/activities/:swf" => 'activities#swf', constraints: { swf: /\w+.swf/ }
    get "/activities/:id/:swf" => 'activities#swf', constraints: { swf: /\w+.swf/ }
    get "/activities/:image" => 'activities#image', constraints: { image: /\w+.(gif|jpg|png)/ }
    get "/activities/:id/:image" => 'activities#image', constraints: { image: /\w+.(gif|jpg|png)/ }

    resources :activities, only: [:show], as: :activity, path: nil do
      member do
        get :popup
        post :save
        post :re_try
        post :finalize
        post :popup_submit
        get :practice
        get :popup_practice
        get :next_activity
        post :diagnostic_feedback
        post :update_time_spent
        get :smartbook_resume_time_tracking
        get :recording
        get :answer_keys
        get :rubric
        get :scored_rubric
        post :export_portfolio
      end
      get '/help_requests' => 'help_requests#activity_index', as: :help_requests
      resources :help_requests, only: [:create, :destroy, :update]
      resources :question_results, only: %i[create]
    end

    post '/activities/:id' => 'activities#submit', constraints: { id: /\d+/ }
    get '/activities/:id/study_plan_concept' => 'study_plan_concepts#show', as: :study_plan_concepts

    post '/activities/:id/nongradable' => 'activities#submit_nongradable', constraints: { id: /\d+/ }
    get '/activity/:id/deck/:flashcards_deck_id/:flashcards_deck_type' => 'flashcards#show', as: :show_flashcards_deck

    # Student TOC
    get '/programs/:program_id' => 'toc#show', as: :toc

    # Workset-related
    get '/assignments/:assignment_day/concept/:concept_id' => 'worksets#show', as: :assignment_bank
    get '/assignments/:assignment_day/category/:category_id' => 'worksets#show', as: :category_workset
    get '/assignments/:assignment_day' => 'worksets#show', as: :assignment_day
    get '/assignments/group/:included_activity_id/concept/:concept_id' => 'worksets#show', constraints: { included_activity_id: /\d+/, concept_id: /\d+/ }, as: :create_group_workset

    # Assignment filters
    get '/weeks_covered' => 'sections#weeks_covered'

    # Categories
    resources :categories, only: [:index]

    # Notifications
    resources :notifications, only: %i[index update show] do
      collection { get :json_index }
    end

    # Announcements
    resources :announcements, only: [:index, :show]

    # Composition Attachments
    resources :composition_attachments, only: [:show]
  end

  # activity preview
  get '/preview_form/' => 'activity_preview#index'
  post '/process_preview/' => 'activity_preview#process_preview', as: :process_preview
  get '/preview_activity/' => 'activity_preview#show', as: :preview_activity
  get '/preview_activity/answer_key' => 'activity_preview#preview_answer_key', as: :preview_answer_key
  get '/preview_activity/rubric' => 'activity_preview#preview_rubric', as: :preview_rubric

  # cms end-points for publish verification and phantom identification
  get '/strand_activities_list/:strand_id' => 'activities_list#show'
  get '/program_activities_list/:program_id' => 'activities_list#index'
  post '/current_assignment_count/:program_id' => 'activities_list#current_assignment_count', as: 'current_assignment_count'

  get '/programs/:program_id/section/:section_id/assessment' => 'assessments#index', as: :student_assessments
  put '/activity_assignments/:program_id/update' => 'activity_assignments#update', as: :update_activity_assignments

  namespace :ua do
    resources :programs, only: [:show, :create, :update]
    resources :schools, only: [:update, :destroy]
    resources :roles_users, only: [:create]
    resources :demo_courses, only: [:create]
    resources :sections, only: :update, param: :guid do
      member do
        post :add_section_instructor
        post :remove_section_instructor
      end
    end
    post '/schools/merge.json' => 'schools#merge'
    post '/sections/unarchive.json' => 'sections#unarchive'
    post '/student_work_transfers/work_transfer.json' => 'student_work_transfers#work_transfer'
    post '/student_work_transfers/completed_activities_per_section.json' => 'student_work_transfers#completed_activities_per_section'
    get '/user_data_sync_report/:user_guid' => 'user_data_sync_report#index'
    post '/delete_user_data/:user_guid' => 'user_data_deleter#delete_user_data'
    post '/delete_school_data/:school_guid' => 'school_data_deleter#delete_school_data'
    namespace :lti do
      resources :launches, only: [:destroy], param: :program_id do
        member do
          post :context
        end
      end
    end
  end

  put '/attempt/:id/sync_time' => 'student/attempt_timer#time_sync', as: :assessment_time_sync

  post '/assessment_access/unlock' => 'student/assessment_access#unlock_assessment', as: :unlock_assessment

  namespace :institution_admin do
    scope '/:program_id/school/:school_id/' do
      resources :courses, only: %i[new edit create update] do
        member do
          get :content_step
        end
        resources :sections, only: [] do
          collection do
            get 'new', to: 'dashboard#new_section', as: :new
          end

          member do
            get 'edit', to: 'dashboard#edit_section', as: :edit
          end
        end
      end
    end

    # dashboard routes
    get '/dashboard' => 'dashboard#index', as: :dashboard
    get '/courses/:program_id' => 'dashboard#courses', as: :courses_current
    get '/courses_past/:program_id/:year' => 'dashboard#courses', as: :courses_past
    get '/sections/:course_id' => 'dashboard#sections', as: :sections
    get '/section_data/:course_id' => 'dashboard#section_data', as: :section_data
    get '/section_metrics/:program_id' => 'dashboard#section_metrics', as: :section_metrics
    get '/section_metrics_past/:program_id/:year' => 'dashboard#section_metrics', as: :section_metrics_past
    get '/configure_view/:program_id' => 'dashboard#configure_view', as: :configure_view
    post '/configure_view/:program_id/toggle_admin_show' => 'dashboard#toggle_admin_show', as: :toggle_admin_show
    get '/section_metrics_data/:program_id/:section_id' => 'dashboard#section_metrics_data', as: :section_metrics_data
    get '/roster/:section_id/:roster_origin' => 'dashboard#roster_dashboard', as: :roster_dashboard
    post '/hide_course_from_instructor_dash/:course_id' => 'dashboard#hide_course_from_instructor_dash', as: :hide_course_from_instructor_dash
    post '/show_course_on_instructor_dash/:course_id' => 'dashboard#show_course_on_instructor_dash', as: :show_course_on_instructor_dash

    # course and section routes
    post '/create_course' => 'dashboard#create_course'
    post '/update_course' => 'dashboard#update_course'
    post '/delete_course' => 'dashboard#delete_course'
    post '/create_section' => 'dashboard#create_sections'
    post '/update_section' => 'dashboard#update_section'
    post '/delete_section' => 'dashboard#delete_section'
    post '/open_enrollment_section' => 'dashboard#open_enrollment_section'
    post '/close_enrollment_section' => 'dashboard#close_enrollment_section'
    get '/section_options/:course_id' => 'dashboard#section_options'

    # course template routes
    get '/:program_id/school/:school_id/course_templates/new' => 'course_templates#new', as: :new_course_template
    post '/:program_id/school/:school_id/course_templates/express_create.json' => 'course_templates#express_create', as: :express_create_course_template
    get '/:program_id/school/:school_id/course_templates/:id/edit' => 'course_templates#edit', as: :edit_course_template
    post '/:program_id/school/:school_id/course_templates.json' => 'course_templates#create', as: :create_course_template
    put '/:program_id/school/:school_id/course_templates/:id.json' => 'course_templates#update', as: :update_course_template
    delete '/:program_id/school/:school_id/course_templates/:id/destroy' => 'course_templates#destroy', as: :destroy_course_template
    get '/:program_id/school/:school_id/course_templates/:id/content_step' => 'course_templates#content_step'
    get '/:program_id/school/:school_id/course_template_data/:template_id' => 'dashboard#course_template_data'

    # section template routes
    get '/:program_id/courses/:course_id/section_templates/new' => 'section_templates#new', as: :new_section_template
    get '/:program_id/courses/:course_id/section_templates/:id/edit' => 'section_templates#edit', as: :edit_section_template
    delete '/:program_id/school/:school_id/section_templates/:id/destroy' => 'section_templates#destroy', as: :destroy_section_template
    get '/:program_id/school/:school_id/section_template_data/:template_id' => 'dashboard#section_template_data'

    # template assigning routes
    get '/:program_id/courses/:course_id/sections/:section_id/toc_templates/show' => 'toc_templates#show', as: :show_toc_template
    get '/:program_id/courses/:course_id/sections/:section_id/assessment_templates' => 'assessment_templates#index', as: :assessment_template
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_templates' => 'assignment_templates#index', as: :assignment_template
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_templates/new' => 'assignment_templates#new', as: :new_assignment_template
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_templates/new/event_calendar/:year_month' => 'assignment_templates#show_calendar', as: :calendar_new
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_templates/edit/event_calendar/:year_month' => 'assignment_templates#show_calendar', as: :calendar_edit
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_templates/event_calendar/:year_month' => 'assignment_templates#show_calendar', as: :calendar
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_wizard_templates' => 'assignment_wizard_templates#index', as: :assignment_wizard_template
    post '/:program_id/courses/:course_id/assignment_wizard_templates.json' => 'assignment_wizard_templates#create', as: :create_assignment_wizard_template
    get '/:program_id/course/:course_id/assignment_wizard_templates/course_info.json' => 'assignment_wizard_templates#course_info', as: :assignment_wizard_template_course_info
    get '/:program_id/courses/:course_id/sections/:section_id/assignment_wizard_templates/check_sections' => 'assignment_wizard_templates#check_sections', as: :assignment_wizard_template_check_sections
    get '/:program_id/courses/:course_id/sections/:section_id/external_item_templates' => 'external_item_templates#index', as: :external_item_template
    post '/:program_id/courses/:course_id/sections/:section_id/external_item_templates.json' => 'external_item_templates#create'
    put '/:program_id/courses/:course_id/sections/:section_id/external_item_templates.json' => 'external_item_templates#update'
    delete '/:program_id/courses/:course_id/sections/:section_id/external_item_templates/:id' => 'external_item_templates#delete'
  end

  namespace :instructor do
    get '/dashboard/:program_id' => 'dashboard#index', as: :dashboard
    get '/dashboard/:program_id/section_average/:section_id' => 'dashboard#section_average'
    get '/dashboard/:program_id/section_and_category_averages/:section_id' => 'dashboard#section_and_category_averages'
    post '/mycontent/:program_id/generated_content_copy/run' => 'generated_content_copy#run'

    # Focus
    put '/focus/:program_id' => 'focus#update', as: :focus
    post '/focus/:program_id' => 'focus#update'
    get '/focus_redirect/:program_id' => 'focus#redirect', as: :focus_redirect
    get '/focus/:program_id/selector' => 'focus#selector', as: :focus_selector
    scope '/:program_id' do
      get '/standards_assigning', to: 'standards_assigning#index'
      post '/standards_assigning/data_for_assigned_item/:id', to: 'standards_assigning#data_for_assigned_item', as: :data_for_assigned_item
      put '/standards_assigning/search_assets', to: 'standards_assigning#search_assets', as: :search_standard_assets
      put '/standards_assigning/search_standards', to: 'standards_assigning#search_standards', as: :search_standards
      get '/standards_assigning/search_standards_by_asset/:asset_id', to: 'standards_assigning#search_standards_by_asset', as: :search_standards_by_asset
      get '/standards_assigning/browse_standards', to: 'standards_assigning#browse_standards', as: :browse_standards

      resources :old_course_years, only: [:index, :show]

      # This is will help swf objects from activities to find content like images
      # when activity is being rendered from instructor's help request section.
      get "/activities/:swf" => 'activities#swf', constraints: { swf: /\w+.swf/ }
      get "/activities/:id/:swf" => 'activities#swf', constraints: { swf: /\w+.swf/ }
      get "/activities/:image" => 'activities#image', constraints: { image: /\w+.(gif|jpg|png)/ }
      get "/activities/:id/:image" => 'activities#image', constraints: { image: /\w+.(gif|jpg|png)/ }
    end
    put '/update_closed_course' => 'focus#update_closed_course', as: :update_closed_course
    put '/update_ai_grading_suggestions_setting' => 'ai_grading_suggestions_setting#update',
      as: :update_ai_grading_suggestions_setting

    resources :media_items, only: %i[create update]

    # Resources
    resources :instructor_resource_settings, only: [:create, :update] do
      collection do
        post :update_many
      end
    end

    scope ':program_id' do
      resources :individual_assignments, only: %i[index update] do
        collection { get :export }
        collection { put :update_all }
      end
      resources :help_requests, only: :index
      resources :reported_problems, only: :index
      resources :activities, only: :show, as: :activity

      resources :mix_and_match_lessons, only: :index

      scope 'lessons/:lesson_id' do
        resources :mix_and_match_assessments, only: :index
        resources :mix_and_match_created_activities, only: :index
      end
      resources :mix_and_match_assessments, only: :show

      scope 'lessons/:lesson_id' do
        resources :question_bank_assessments, only: :index
      end

      # created activities
      scope 'lessons/:lesson_id/toc_entries/:toc_entry_id' do
        resources :created_activities, only: [:new, :create, :edit, :update]
        get '/activities/:id/create_from_activity' => 'created_activities#create_from_activity', as: :created_activities_create_from_activity
        get '/activities/:id/create_from_assessment' => 'created_activities#create_from_assessment', as: :created_activities_create_from_assessment
        get '/assessments/new' => 'assessments#new', as: :new_assessment
        post '/assessments/new' => 'assessments#create', as: :create_assessment
      end
      put 'lessons/:lesson_id/toc_entries/:toc_entry_id/created_activities/convert_to_shared/:id' => 'created_activities#convert_to_shared', as: :created_activities_convert_to_shared
      delete 'lessons/:lesson_id/toc_entries/:toc_entry_id/created_activities/remove_as_shared/:id' => 'created_activities#remove_as_shared', as: :created_activities_remove_as_shared
      put 'lessons/:lesson_id/toc_entries/:toc_entry_id/created_activities/copy_to_mycontent/:id' => 'created_activities#copy_to_mycontent', as: :created_activities_copy_to_mycontent
      post '/my_content/:id/share' => 'created_activities#share_activity', as: :share_activity

      post '/my_content/:id/set_private' => 'created_activities#set_activity_private', as: :set_private
      get '/media_items/:rails_env/:media_type/:id_part1/:id_part2/vocab_tutorial_iframe.html' => 'activities#vocab_tutorial_iframe'

      resources :my_content, only: [:destroy], controller: 'created_activities' do
        collection do
          get :confirm_copy_previous_edition_igcs
          post :copy_previous_edition_igcs
        end

        member do
          get :confirm_destroy
        end
      end

      # Assignments
      resource :assignment_filter, only: [:create, :update]
      scope '/activity/:activity_id' do
        resources :activity_notes, only: [:index, :create, :update, :destroy]
        resources :activity_help_requests, only: [:index, :update]
      end

      # course library of activities
      post '/activities/hide' => 'course_library#hide', as: :course_library_activity_hide
      post '/activities/unhide' => 'course_library#unhide', as: :course_library_activity_unhide

      resources :assignment_sets, only: %i[index create update destroy] do
        collection { get :export }
      end
    end

    # Grading tasks
    scope '/:program_id' do
      resources :grading_sets, only: [:create, :edit, :update]
    end

    resources :grading_tasks, only: [] do
      collection do
        post 'find_or_create_grading_set_id'
        post 'start_ai_feedback'
        get 'grading_status'
      end
    end
    get '/to_do/:program_id/assignments' => 'grading_tasks#assignments_index', as: :grading_tasks_assignments
    get '/to_do/:program_id/assignments/activities_index' => 'grading_tasks#activities_index', as: :grading_task_activities
    get '/to_do/:program_id/grading_set/:id/edit_confirm' => 'grading_sets#edit_confirm', as: :grading_set_edit_confirm
    get '/to_do/:program_id/activity/:activity_id/grade' => 'grading_tasks#grade_activity', as: :grading_tasks_grade_activity
    get '/to_do/:program_id/activity/:activity_id' => 'spotcheck#students_index', as: :spotcheck_activity_index
    post '/to_do/:program_id/grading_set/:grading_set_id' => 'spotcheck#update', as: :spotcheck_activity
    put '/to_do/:program_id/activity/:activity_id/spotcheck_update_style' => 'spotcheck#update_style', as: :spotcheck_update_style
    put '/to_do/:program_id/activity/:activity_id/spotcheck_update_selected_students_count' => 'spotcheck#update_selected_students_count', as: :spotcheck_update_selected_students_count
    put '/:program_id/grading_styles/update' => 'grading_styles#update', as: :grading_style
    get '/:program_id/grading_styles/:activity_id/' => 'grading_styles#index', as: :grading_styles

    # Review requests
    get '/:program_id/review_requests' => 'review_requests#index', as: :review_requests
    put '/:program_id/review_requests/:id' => 'review_requests#update', as: :review_request
    get '/:program_id/activity/:activity_id/show_activity' => 'review_requests#show_activity', as: :show_activity

    #Section Wizard
    get '/sections/section_information_step' => 'sections#section_information_step'

    get '/:program_id/school/:school_id/courses/new' => 'courses#new', as: :new_course
    post '/:program_id/courses/show_summary_pdf' => 'courses#show_summary_pdf', as: :course_summary_pdf

    # External Items  for Assignment Wizard
    get 'learning_tracks/external_items/:section_id' => 'learning_tracks#external_items'

    scope ':program_id' do
      post '/courses/express_create' => 'courses#express_create'

      get '/learning_tracks' => 'learning_tracks#learning_tracks'
      get '/section_learning_track/:section_id' => 'learning_tracks#section_learning_track'

      resources :courses, only: [:show, :create, :edit, :update, :destroy] do
        resources :sections, except: [:index]
        member do
          get :content_step
        end
      end
    end

    scope '/:program_id' do
      resources :enrollments, only: [:new, :create]
    end
    get '/enrollments/instructor/:program_id/student' => 'student#search', as: :search_students
    get '/enrollments/instructor/:program_id/search_by' => 'student#search_by', as: :search_student_by
    get '/enrollments/instructor/:program_id' => 'enrollments#confirm', as: :confirm_enrollments

    # Assignment Wizard
    scope '/:program_id/course/:course_id' do
      resources :assignment_wizard, only: [:index, :create]
      get '/assignment_wizard/course_info' => 'assignment_wizard#course_info', as: :assignment_wizard_course_info
      get '/assignment_wizard/check_sections' => 'assignment_wizard#check_sections', as: :assignment_wizard_check_sections
    end

    # Assignment calendar / bulk assigning
    get '/assignments/:program_id' => 'assignments#index', as: :assignments
    get '/assignments/:program_id/new' => 'assignments#new', as: :new_assignments
    get '/assignments/:program_id/show_more' => 'assignments#show_more', as: :show_more
    post '/:program_id/assignables' => 'assignables#index', as: :assignables

    # Events within assignment calendar
    get '/assignments/:program_id/new/event_calendar/:year_month' => 'assignments#show_calendar', as: :calendar_new
    get '/assignments/:program_id/event_calendar/:year_month' => 'assignments#show_calendar', as: :calendar

    # Instructor assessments
    get '/assessments/:program_id' => 'assessments#index', as: :assessments
    get '/programs/:program_id/update_assessments/' => 'assessments#update_assessment', as: :update_assessment

    # assessment custom time limits
    get '/:program_id/assessments/:section_id/time_limits/:activity_id' => 'assessment_time_limits#index',
          as: :assessment_time_limits
    post '/:program_id/assessments/:section_id/time_limits/:activity_id/update' => 'assessment_time_limits#update_time_limits', as: :assessment_update_time_limits

    # Review work
    scope '/review_work/:program_id' do
      get '/score/:score_id' => 'review_work#edit',
            as: :review_work
      put '/score/:score_id' => 'review_work#update',
            as: :review_work_update
      get '/sections/:section_id/students/:user_id/' \
            'activities/:activity_id' => 'review_work#edit',
            as: :review_work_grade
      put '/sections/:section_id/students/:user_id/' \
            'activities/:activity_id' => 'review_work#update',
            as: :review_work_grade_update
    end

    # Instructor TOC
    get '/contents/:program_id' => 'toc#show', as: :toc

    scope '/:program_id' do
      resources :announcements
    end

    # Pronto
    get '/pronto/:program_id' => 'pronto#show', as: :pronto

    # Grace Periods (convert to resource)
    get ':program_id/courses/:course_id/grace_periods' => 'student_grace_periods#index', as: :student_grace_period
    post ':program_id/courses/:course_id/grace_periods' => 'student_grace_periods#create', as: :grant_student_grace_period

    # Institution admin
    get ':program_id/institution_admin/section_shared_options/:course_shared_id' => 'institution_admin#section_shared_options'
  end

  namespace :one_roster do
    namespace :api do
      resources :schools, param: :salesforce_id, only: %i[update]
    end

    scope '/:program_id' do
      namespace :instructor do
        resources :courses, only: %i[index create destroy] do
          collection do
            get :add
          end
        end
      end
    end
  end

  # an mp3 is not an image, but is better than rewriting all the image routes and the controller action.
  get '/media/games/:image' => 'activities#image', constraints: { image: /.+\.(gif|jpg|png|mp3)/ }

  scope '/:program_id' do
    resources :courses do
      get '/roster' => 'roster#show', as: :roster
    end

    resources :sections do
      get '/roster' => 'roster#show', as: :roster
      get '/student-settings' => 'student_settings#show', as: :student_settings_show
      post '/student-settings/update-students' => 'student_settings#update_students', as: :student_settings_update_students
      post '/student-settings/update-section-defaults' => 'student_settings#update_section_defaults', as: :student_settings_update_section_defaults
    end
  end

  namespace :inactivity_timeouts do
    get :log_out
    put :update_session
  end

  namespace :gradebook do
    scope '/:program_id' do
      get '/drop_students/edit' => 'enrollments#edit_collection', as: :drop_students_edit
      post '/drop_students/' => 'enrollments#update_collection', as: :drop_students_update
      post '/drop_students/undrop' => 'enrollments#undrop_collection', as: :undrop_students
      get '/email_students/' => 'email#list', as: :email_students

      scope '/courses/:course_id' do
        scope '/sections/:section_id' do
          scope :analytics do
            scope :practice_test do
              get '/', to: 'analytics/practice_test#show', as: :practice_test
              get '/individual_student', to: 'analytics/practice_test#individual_student', as: :individual_student
            end
          end
          scope :standards, as: 'standards' do
            get '/', to: 'standards/section_report#index', as: :section_report_index
            post '/assessments', to: 'standards/section_report#assessments', as: :assessments_per_unit
            post '/categories', to: 'standards/section_report#categories', as: :categories_per_unit
            post '/section_report', to: 'standards/landing_page#report', as: :section_report
            match '/landing_page', to: 'standards/landing_page#index', as: :landing_page, via: [:post, :get]
            get '/roster', to: 'standards/landing_page#roster', as: :roster
            post '/student_report_data', to: 'standards/section_student_report#student_report_data', as: :student_report_data
            post '/students', to: 'standards/section_student_report#index', as: :section_student_report
            get '/students_csv', to: 'standards/section_student_report#export_student_csv', as: :students_csv
            get '/standard_export_csv', to: 'standards/section_student_report#export_csv_standards', as: :export_csv
            get '/:standard_set_id/student_detail_report/:student_id', to: 'standards/student_detail_report#index', as: :student_detail_report
            get '/:standard_set_id/student_detail_report/:student_id/grade_categories/:unit_id', to: 'standards/student_detail_report#grade_categories', as: :grade_categories
            get '/:standard_set_id/student_detail_report/:student_id/grade_categories/:unit_id/lower/:lower/upper/:upper/sort/:sort/column/:sort_column', to: 'standards/student_detail_report#standard_list_by_range', as: :standard_list_by_range
            get '/:standard_set_id/landing_page/:student_id/review', to: 'standards/landing_page#show', as: :student_detail_report_review
          end
        end
      end
    end
  end

  scope '/:program_id' do
    scope '/sections/:section_id' do
      get '/vocab_words/popup' => 'vocab_words#index_popup', as: :vocab_words_popup
      resources :study_plan_concepts, only: :index
      resources :user_readings, only: :update
      resources :vocab_words, only: %i[index create update destroy] do
        collection { post :print_pdf }
      end
      namespace :vocab_tools do
        resources :units, only: :index
        resources :words, only: :index
        resources :user_defined_words, only: %i[create update destroy]
      end
      resources :forums do
        resources :forum_posts, only: %i[create update destroy]
      end
    end

    # Versions without section_id provide backwards compatiblity for
    # bookmarks, external links.
    get '/vocab_words/popup' => 'vocab_words#index_popup'
    resources :study_plan_concepts, only: :index
    resources :user_readings, only: :update
    resources :vocab_words, only: %i[index create update destroy] do
      collection { post :print_pdf }
    end
    namespace :vocab_tools do
      resources :units, only: :index
      resources :words, only: :index
      resources :user_defined_words, only: %i[create update destroy]
    end
    resources :forums do
      resources :forum_posts, only: %i[create update destroy]
    end
    # End of backwards compatiblity block.

    get '/standards_mapping_activities_template' => 'standards#standards_mapping_activities_template'
    get '/standards_mapping_assessments_template' => 'standards#standards_mapping_assessments_template'
    get '/standards_mapping_toc_csv' => 'standards#standards_mapping_toc_csv'
    get '/standards_mapping_ingested_te_items' => 'standards#standards_mapping_ingested_te_items'
    get '/standard_assets_template' => 'standards#standard_assets_template'
  end

  get '/standards_mapping_ereader_template' => 'standards#standards_mapping_ereader_template'

  resources :standards, only: [:show]
  put '/standards/update_all' , as: :update_all

  namespace :standards do
    resources :assets, only: [:create]
    put 'assets/:vendor_guid', to: 'assets#update'
  end

  resources :standard_sets, only: [:index] do
    collection do
      post :standards_by_sets
    end
  end

  namespace :standard_sets do
    get :grouped_by_display_name
  end

  resources :standard_alignments
  put '/standard_alignments/update/:program_id' => 'standard_alignments#update', as: :update

  # Dictionary Entries Routes
  resources :dictionary_entries, only: [] do
    collection do
      get :generate_report
      get :download_csv
    end
  end

  # Publishing
  post '/publish/concepts/:id' => 'publish_api#concept', as: :publish_concept
  post '/publish/media_items/:id' => 'publish_api#media_item', as: :publish_media_item
  post '/publish/programs/:program_id/units/:toc_location' => 'publish_api#unit', as: :publish_unit
  post '/publish/qa_activity' => 'publish_api#qa_activity', as: :publish_qa_activity
  post '/publish/units/:unit_toc_location/lessons/:rank' => 'publish_api#lesson', as: :publish_lesson
  post '/publish/cms_activities/:cms_activity_id/activities/:toc_location' => 'publish_api#activity', as: :publish_activity
  post '/publish/cms_activities/:cms_activity_id' => 'publish_api#unlisted_activity', as: :publish_unlisted_activity
  post '/publish/programs/:program_id/after_publish_actions' => 'publish_api#after_publish_actions', as: :after_publish_actions

  get '/activities/:id/popup' => 'activities#permalink', as: :activity_permalink
  get '/lessons/:lesson_id/toc_location/:toc_location_id' => 'toc#strand_permalink', as: :student_strand_permalink

  post '/gradebook/:program_id/confirm_actions' => 'gradebook#confirm_actions', as: :gradebook_confirm_actions
  get '/plugin_public/:path' => 'plugin_public#serve_public'
  post '/setting/sort_courses' => 'setting#sort_courses'
  get '/student/:student_id/school/:school_id' => 'students#enrollment_info', as: :student_enrollment_info
  get '/student/:program_id/section/:section_id/student_info/:id' => 'students#student_info', as: :student_info

  resources :workers, only: [:show]

  put '/chat_click_logs/log' => 'chat_click_logs#log', as: :log_chat_link
  get '/activities/:id/preview/:flashcards_deck_id/data' => 'flashcards_activities#flashcards_data', as: :show_flashcards_datasource
  get '/errors/activity_privileges/:program_id' => 'errors#activity_privileges', as: :activity_privileges_error

  resources :help_entries, except: [:show]

  # Chat-related
  get '/users/:id/client_token/new' => 'client_token#new', as: :new_client_token

  # Ebook
  scope '/:program_id' do
    scope '/sections/:section_id' do
      resources :ebooks, only: :index do
        member { get :go_to_vitalsource }
      end
    end
    # Version without section_id provides backwards compatiblity for
    # bookmarks, external links.
    resources :ebooks, only: :index
  end

  resources :programs, only: [] do
    resource :config, only: [:edit, :show, :update], controller: :program_configs
    resources :config_versions, only: [:index], controller: :program_config_versions
    get 'update_vocab_tools' => 'program_configs#update_vocab_tools', as: :update_vocab_tools
    get 'mapping_source_program' => 'program_configs#mapping_source_program', as: :mapping_source_program
    get 'mapping_dest_lesson_strands' => 'program_configs#mapping_dest_lesson_strands', as: :mapping_dest_lesson_strands
    get 'remove_existing_mappings' => 'program_configs#remove_existing_mappings', as: :remove_existing_mappings
    get 'current_dest_for_src' => 'program_configs#current_dest_for_src', as: :current_dest_for_src
    get 'map_automatically' => 'program_configs#map_automatically', as: :map_automatically
  end

  # resource components
  scope 'programs/:program_id' do
    resources :resource_components, except: [:show]
  end

  resources :server_error_reports, only: [:update]
  resources :vtext_data_files, only: %i[index create]

  # Instructor Resource Export Tools
  resource :instructor_resources_export, only: [] do
    get '/export' => 'instructor_resources_export#export', as: :export
    get '/' => 'instructor_resources_export#index', as: :index
    get '/generate_link' => 'instructor_resources_export#generate_new_link', as: :generate_link
    get '/export_csv' => 'instructor_resources_export#export_csv', as: :export_csv
  end

  resource :bulk_resources_uploader do
    get '/' => 'bulk_resources#index'
    get '/select_program' => 'bulk_resources#select_program', as: 'select_program'
    get '/upload/:program_id' => 'bulk_resources#bulk_upload', as: 'upload'
    get '/upload/:program_id/files_s3_status' => 'bulk_resources#files_s3_status'
    get '/upload/:program_id/download_errors_report' => 'bulk_resources#download_errors_report'
    get '/upload/:program_id/creation_in_progress_status' => 'bulk_resources#creation_in_progress_status'
    post '/upload/:program_id/validate' => 'bulk_resources#validate'
    post '/upload/:program_id/bulk_delete' => 'bulk_resources#bulk_delete'
    post '/upload/:program_id/start_creation' => 'bulk_resources#start_creation'
    post '/upload/:program_id/upload_csv', to: 'bulk_resources#upload_csv', as: 'upload_csv'
  end

  # A11y Reporting Tools
  resource :a11y_report_generator, only: [] do
    get '/report' => 'a11y_report_generator#report', as: :report
    get '/' => 'a11y_report_generator#index', as: :index
    get '/generate_reports' => 'a11y_report_generator#generate_new_report', as: :generate_report
  end

  get '/assignment_rank_lists/edit/:section_id/' => 'assignment_rank_lists#edit'
  put '/assignment_rank_lists/update' => 'assignment_rank_lists#update'

  post '/chat' => 'chat#create_session'

  # Video chat stuff
  post '/video_chat/sessions' => 'video_chat#create_session', as: :video_chat_sessions
  post '/video_chat/sessions/:session_id/tokens' => 'video_chat#create_token', as: :video_chat_tokens
  post '/video_chat/sessions/:session_id/recordings' => 'video_chat#start_recording', as: :video_chat_recording
  post '/video_chat/sessions/:session_id/recordings/:recording_id/stop' => 'video_chat#stop_recording', as: :video_chat_stop_recording
  get '/video_chat/sessions/:session_id/recordings/:recording_id/status' => 'video_chat#status_recording', as: :video_chat_status_recording

  # Grab cookie endpoint for user
  post '/video_chat/video_permission', to: 'video_chat#video_permission', as: :video_chat_permission

  # Authorize group chat channel route
  post '/group_chat_channel/authorize', to: 'chat#group_chat_channel_authorize', as: :group_chat_channel_authorize

  namespace :xapi do
    get 'activities/state', to: 'state#show', as: :state_show
    put 'activities/state', to: 'state#update', as: :state_update
    put 'statements', to: 'statements#update', as: :statements_update
  end

  if Rails.env.development? || Rails.env.test?
    get '/dev/examples/javascript', to: 'dev_examples#javascript'
    get '/dev/examples/styles', to: 'dev_examples#styles'
    get '/dev/examples/enhanced_feedback', to: 'dev_examples#enhanced_feedback'
    get '/dev/examples/intranavigable_activities', to: 'dev_examples#intranavigable_activities'

    get '/sidekiq_monitor', to: 'sidekiq_monitor#sidekiq_redirect', as: :sidekiq_monitor
    mount Sidekiq::Web, at: '/sidekiq', constraints: DeveloperConstraint.new
  end

  if Rails.env.qa?
    get '/dev/examples/enhanced_feedback', to: 'dev_examples#enhanced_feedback'
    get '/dev/examples/intranavigable_activities', to: 'dev_examples#intranavigable_activities'

    get '/sidekiq_monitor', to: 'sidekiq_monitor#sidekiq_redirect', as: :sidekiq_monitor
    mount Sidekiq::Web, at: '/sidekiq', constraints: DeveloperConstraint.new
  end

  namespace :ai do
    resources :grading_prompts, only: %i[index new create edit update] do
      get :generate_internal_grading_suggestions
      get :generate_internal_overall_comments
    end

    resources :programs do
      namespace :live_data do
        resources :grading_inputs, only: %i[index create]
        resources :grading_input_ratings, only: %i[index]
        get(
          'grading_input_ratings/:activity_id/:question_rank' => 'grading_input_ratings#rate_question',
          as: :grading_input_rating_question
        )
        resources :grading_input_rating_reports, only: %i[index]
        get(
          'grading_input_rating_reports/:activity_id/:question_rank' => 'grading_input_rating_reports#show',
          as: :grading_input_rating_reports_question
        )
        resources :grading_suggestion_prompts, only: %i[index]
        resources :overall_comment_prompts, only: %i[index]
      end

      namespace :instructor_grading do
        resources :suggestion_rating_reports, only: %i[index]
        get(
          'suggestion_rating_reports/:activity_id/:instructor_id' => 'suggestion_rating_reports#show',
          as: :suggestion_rating_reports_question
        )
      end
    end

    resources :grading_suggestions do
      member do
        put :rate
      end
    end
    resources :overall_comments do
      member do
        put :rate
      end
    end
    resources :conversations, only: [] do
      member do
        get :saved_messages
        post :session_response
        patch :update_messages
        patch :restart_session
      end
    end
  end
end
