describe CourseOptionsSerializer do
  let(:most_recent_school) { create(:school) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, program: program) }
  let(:course_options) { CourseOptions.new(instructor, course, program) }
  let(:serializer) { described_class.new(course_options) }

  before do
    allow(instructor).to receive(:most_recent_school_id).and_return(most_recent_school.id)
    allow(course_options).to receive(:available_course_packages).and_return([])
    allow(course_options).to receive(:course_packages_by_course).and_return({})
    allow(course_options).to receive(:levels).and_return([])
    allow(course_options).to receive(:components).and_return([])

    # Create a default program configuration. Create it in the past to allow
    # some tests to override it (the active one is always the most recent one).
    Timecop.travel(1.minute.ago) do
      create(:program_config, program: program)
    end
  end

  describe '#to_json' do
    it 'renders the correct attributes as json' do
      # We are only testing that all the keys are present. Each individual
      # attribute is tested separately.
      expect(serializer.as_json.keys).to contain_exactly(
        :ai_virtual_chat_level,
        :allow_copy,
        :assignments,
        :autorostering_linked,
        :available_course_packages,
        :components,
        :course,
        :has_one_roster_academic_session,
        :levels,
        :lti_roster_linked,
        :one_roster_linked,
        :previous_course_templates,
        :previous_courses,
        :program,
        :schools,
        :selected_school_id,
        :settings,
        :setup_descriptions,
        :supported_standard_sets,
        :template_settings,
        :units,
        :video_languages
      )
    end
  end

  describe 'the allow_copy attribute,' do
    it 'is false when the course is not an Lti course and the course has due dates reached' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(false)
      allow(course_options).to receive(:any_due_dates_reached?).and_return(true)

      expect(serializer.as_json[:allow_copy]).to eq(false)
    end

    it 'is false when the course is not an Lti course and the course has no due date reached' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(false)
      allow(course_options).to receive(:any_due_dates_reached?).and_return(false)

      expect(serializer.as_json[:allow_copy]).to eq(false)
    end

    it 'is false when the course is an Lti course and the course has due dates reached' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(true)
      allow(course_options).to receive(:any_due_dates_reached?).and_return(true)

      expect(serializer.as_json[:allow_copy]).to eq(false)
    end

    it 'is false when the course is an Lti course and the course has no due date reached' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(true)
      allow(course_options).to receive(:any_due_dates_reached?).and_return(false)

      expect(serializer.as_json[:allow_copy]).to eq(true)
    end
  end

  describe 'the assignments attribute,' do
    it 'is false when the course has no assignment' do
      allow(course_options).to receive(:assignments?).and_return(false)

      expect(serializer.as_json[:assignments]).to eq(false)
    end

    it 'is true when the course has assignments' do
      allow(course_options).to receive(:assignments?).and_return(true)

      expect(serializer.as_json[:assignments]).to eq(true)
    end
  end

  describe 'the autorostering_linked attribute,' do
    it 'is false when the course has no autorostering linked section' do
      allow(course_options).to receive(:autorostering_linked?).and_return(false)

      expect(serializer.as_json[:autorostering_linked]).to eq(false)
    end

    it 'is true when the course has autorostering linked sections' do
      allow(course_options).to receive(:autorostering_linked?).and_return(true)

      expect(serializer.as_json[:autorostering_linked]).to eq(true)
    end
  end

  describe 'available_course_packages attribute,' do
    let(:course_package) do
      instance_double(
        Maestro::CoursePackage,
        content_type: 'level',
        id: 123,
        program_id: program.id,
        name: 'Supersite',
        rank: 1,
        response: { 'id' => 123, 'name': 'Supersite' }
      )
    end

    it 'returns the available course packages' do
      allow(course_options).to receive(:available_course_packages).and_return(
        [course_package]
      )

      expect(serializer.as_json[:available_course_packages]).to eq(
        [course_package]
      )
    end
  end

  describe 'the components attribute,' do
    let(:component_1) do
      instance_double(
        Maestro::CoursePackage,
        content_type: 'component',
        id: 1,
        response: { 'id' => 1, 'name' => 'Component 1' }
      )
    end
    let(:component_2) do
      instance_double(
        Maestro::CoursePackage,
        content_type: 'component',
        id: 2,
        response: { 'id' => 2, 'name' => 'Component 2' }
      )
    end

    it 'return the serialized component course packages' do
      allow(course_options).to receive(:components).and_return([component_1, component_2])

      expect(serializer.as_json[:components]).to eq(
        [
          { 'id' => component_1.response['id'], 'name' => component_1.response['name'] },
          { 'id' => component_2.response['id'], 'name' => component_2.response['name'] }
        ]
      )
    end
  end

  describe 'the course attribute,' do
    it 'returns the course attributes' do
      course_attrs = { foo: 1 }

      course_attributes_serializer = instance_double(
        CourseOptionsSerializer::CourseAttributesSerializer,
        to_hash: course_attrs
      )
      # The CourseAttributesSerializer class is use multiple times.
      # We only stub the call for the main course.
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .and_call_original
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .with(course_options, course)
        .and_return(course_attributes_serializer)

      expect(serializer.as_json[:course]).to eq(course_attrs)
    end
  end

  describe 'the has_one_roster_academic_session attribute,' do
    it 'is false when the course has no RA academic session section' do
      allow(course_options).to receive(:has_one_roster_academic_session?).and_return(false)

      expect(serializer.as_json[:has_one_roster_academic_session]).to eq(false)
    end

    it 'is false when the course has RA academic session sections' do
      allow(course_options).to receive(:has_one_roster_academic_session?).and_return(true)

      expect(serializer.as_json[:has_one_roster_academic_session]).to eq(true)
    end
  end

  describe 'the levels attribute,' do
    let(:level_1) do
      instance_double(
        Maestro::CoursePackage,
        content_type: 'level',
        id: 1,
        response: { 'id' => 1, 'name' => 'Level 1' }
      )
    end
    let(:level_2) do
      instance_double(
        Maestro::CoursePackage,
        content_type: 'level',
        id: 2,
        response: { 'id' => 2, 'name' => 'Level 2' }
      )
    end

    it 'return the serialized level course packages' do
      allow(course_options).to receive(:levels).and_return([level_1, level_2])

      expect(serializer.as_json[:levels]).to eq(
        [
          { 'id' => level_1.response['id'], 'name' => level_1.response['name'] },
          { 'id' => level_2.response['id'], 'name' => level_2.response['name'] }
        ]
      )
    end
  end

  describe 'the lti_roster_linked attribute,' do
    it 'is false when the course has no Lti rostering linked section' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(false)

      expect(serializer.as_json[:lti_roster_linked]).to eq(false)
    end

    it 'is true when the course has Lti rostering linked sections' do
      allow(course_options).to receive(:lti_roster_linked?).and_return(true)

      expect(serializer.as_json[:lti_roster_linked]).to eq(true)
    end
  end

  describe 'the one_roster_linked attribute,' do
    it 'is false when the course has no RA linked section' do
      allow(course_options).to receive(:one_roster_linked?).and_return(false)

      expect(serializer.as_json[:one_roster_linked]).to eq(false)
    end

    it 'is true when the course has RA linked sections' do
      allow(course_options).to receive(:one_roster_linked?).and_return(true)

      expect(serializer.as_json[:one_roster_linked]).to eq(true)
    end
  end

  describe 'the previous_courses attribute,' do
    it 'returns an array of previous courses with assignments along with sections with assignments' do
      previous_course_with_assignments = [
        {
          id: 456,
          name: 'course 1',
          sections: [
            {
              id: 12,
              name: 'section 1'
            },
            {
              id: 34,
              name: 'section 2'
            }
          ]
        },
        {
          id: 457,
          name: 'course 2',
          sections: []
        }
      ]
      allow(course_options).to receive(
        :previous_course_and_section_data
      ).with(no_args).and_return(
        previous_course_with_assignments
      )
      allow(course_options).to receive(
        :previous_course_and_section_data
      ).with(:course_template).and_return(
        []
      )

      expect(serializer.as_json[:previous_courses]).to eq(
        previous_course_with_assignments
      )
    end
  end

  describe 'previous_course_templates attribute,' do
    it 'returns an array of previous course templates with assignments along with sections with assignments' do
      previous_course_templates_with_assignments = [
        {
          id: 123,
          name: 'course 1',
          enterprise: false,
          template: true,
          sections: [
            {
              id: 23,
              name: 'section 1'
            },
            {
              id: 24,
              name: 'section 2'
            }
          ]
        },
        {
          id: 124,
          name: 'course 2',
          sections: []
        }
      ]
      allow(course_options).to receive(
        :previous_course_and_section_data
      ).with(no_args).and_return(
        []
      )
      allow(course_options).to receive(
        :previous_course_templates_and_section_data
      ).with(no_args).and_return(
        previous_course_templates_with_assignments
      )

      expect(serializer.as_json[:previous_course_templates]).to eq(
        previous_course_templates_with_assignments
      )
    end
  end

  describe 'the program attribute,' do
    it 'return the program attributes' do
      expect(serializer.as_json[:program]).to eq(
        id: program.id,
        lesson_label: program.lesson_label,
        unit_label: program.unit_label
      )
    end
  end

  describe 'schools attribute,' do
    it 'returns the serialized instructor schools, excluding the districts' do
      school_1 = create(:school)
      school_2 = create(:school)
      district = create(:district)

      instructor.schools << [school_1, school_2, district]
      expect(serializer.as_json[:schools]).to contain_exactly(
        {
          id: school_1.id,
          name: school_1.name
        },
        {
          id: school_2.id,
          name: school_2.name
        }
      )
    end
  end

  describe 'selected_school_id attribute,' do
    context 'when no school is selected' do
      let(:course_options) { CourseOptions.new(instructor, course, program) }

      it 'return nil' do
        expect(serializer.as_json[:selected_school_id]).to be_nil
      end
    end

    context 'when a school is selected' do
      let(:selected_school) { create(:school) }
      let(:course_options) { CourseOptions.new(instructor, course, program, selected_school.id) }

      it 'returns the selected school id' do
        expect(serializer.as_json[:selected_school_id]).to eq(selected_school.id)
      end
    end
  end

  describe 'settings attribute,' do
    let(:default_course) { create(:course) }
    let(:previous_course) { create(:course) }
    let(:default_course_attrs) { { foo: 1 } }
    let(:previous_course_attrs) { { bar: 2 } }
    let(:default_course_attributes_serializer) do
      instance_double(
        CourseOptionsSerializer::CourseAttributesSerializer,
        to_hash: default_course_attrs
      )
    end
    let(:previous_course_attributes_serializer) do
      instance_double(
        CourseOptionsSerializer::CourseAttributesSerializer,
        to_hash: previous_course_attrs
      )
    end

    it 'returns the attributes of the default courses and the previous courses' do
      allow(course_options).to receive(:default_courses).and_return([default_course])
      allow(course_options).to receive(:previous_courses).and_return([previous_course])
      # The CourseAttributesSerializer class is use multiple times.
      # We only stub the calls we validate here.
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .and_call_original
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .with(course_options, default_course)
        .and_return(default_course_attributes_serializer)
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .with(course_options, previous_course)
        .and_return(previous_course_attributes_serializer)

      expect(serializer.as_json[:settings]).to eq(
        [default_course_attrs, previous_course_attrs]
      )
    end
  end

  describe 'the setup_descriptions attribute,' do
    it 'returns the setup descriptions of the course options' do
      course_setup_descriptions = {
        express_course: 'express course',
        advanced_course: 'advanced course',
        learning_tracks: {
          header: 'Learning tracks'
        }
      }
      allow(course_options).to receive(:setup_descriptions)
        .and_return(course_setup_descriptions)

      expect(serializer.as_json[:setup_descriptions]).to eq(
        course_setup_descriptions
      )
    end
  end

  describe 'supported_standard_sets attribute,' do
    let(:standard_set_1) { create(:standard_set, display_name: 'standard set display name 1') }
    let(:standard_set_2) { create(:standard_set, display_name: 'standard set display name 2') }
    let(:standard_set_3) { create(:standard_set, display_name: 'standard set display name 1') }
    let(:standard_set_4) { create(:standard_set, display_name: '') }
    let(:course) do
      # We must create a program config with the supported standard sets before
      # the course.
      create(
        :program_config_with_standard_sets,
        program: program,
        supported_standard_sets: [standard_set_1, standard_set_2, standard_set_3, standard_set_4]
      )
      create(
        :course,
        program: program,
        standard_sets: [standard_set_1, standard_set_2]
      )
    end

    it 'returns the standard sets supported by the associated program, grouped by name' do
      expect(serializer.as_json[:supported_standard_sets]).to contain_exactly(
        {
          # Using the display name because it is present
          name: standard_set_1.display_name,
          ids: [standard_set_1.id, standard_set_3.id]
        },
        {
          # Using the display name because it is present
          name: standard_set_2.display_name,
          ids: [standard_set_2.id]
        },
        {
          # Using the issuer and the name because the display name is balnk
          name: "#{standard_set_4.issuer} - #{standard_set_4.name}",
          ids: [standard_set_4.id]
        }
      )
    end
  end

  describe 'the template_settings attribute,' do
    it 'returns the attributes of all the previous course templates' do
      template_1 = create(:course_template)
      template_2 = create(:course_template)

      allow(course_options).to receive(
        :previous_course_templates
      ).and_return(
        [template_1, template_2]
      )

      template_1_attrs = { foo: 1 }
      template_2_attrs = { bar: 2 }
      template_1_serializer = instance_double(
        CourseOptionsSerializer::CourseAttributesSerializer,
        to_hash: template_1_attrs
      )
      template_2_serializer = instance_double(
        CourseOptionsSerializer::CourseAttributesSerializer,
        to_hash: template_2_attrs
      )
      # The CourseAttributesSerializer class is use multiple times.
      # We only stub the calls we validate here.
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .and_call_original
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .with(course_options, template_1)
        .and_return(template_1_serializer)
      allow(CourseOptionsSerializer::CourseAttributesSerializer).to receive(:new)
        .with(course_options, template_2)
        .and_return(template_2_serializer)

      expect(serializer.as_json[:template_settings]).to eq(
        [template_1_attrs, template_2_attrs]
      )
    end
  end

  describe 'units attribute,' do
    let(:unit_with_label) { create(:unit, label: 'Lesson 1') }
    let(:unit_without_label) { create(:unit, label: nil, name: 'Unit 2 name') }
    let(:program) { create(:program, units: [unit_with_label, unit_without_label]) }

    it 'returns the serialized course units' do
      expect(serializer.as_json[:units]).to eq(
        [
          { 'id' => unit_with_label.id, 'label' => unit_with_label.label },
          { 'id' => unit_without_label.id, 'label' => unit_without_label.name }
        ]
      )
    end
  end

  describe 'the video_languages attribute,' do
    it 'return the course possible video languages' do
      allow(course_options).to receive(:video_languages).and_return(
        'Spanish' => 'foreign',
        'Spanish and English' => 'foreign_and_english',
        'None' => 'none'
      )

      expect(serializer.as_json[:video_languages]).to eq(
        'Spanish' => 'foreign',
        'Spanish and English' => 'foreign_and_english',
        'None' => 'none'
      )
    end
  end

  describe CourseOptionsSerializer::CourseAttributesSerializer do
    include DateTimeHelper

    let(:program) { create(:program) }
    let(:user) { create(:user) }
    let(:user) { create(:user) }
    let(:main_course) { create(:course) }
    let(:course_options) { CourseOptions.new(user, main_course, program) }
    let(:course) { create(:course) }
    let(:serializer) { described_class.new(course_options, course) }

    before do
      allow(course_options).to receive(:course_packages_by_course).and_return([])
    end

    describe '#to_hash' do
      it 'returns a hash with all the course attributes' do
        # We are only testing that all the keys are present. Each individual
        # attribute is tested separately.
        expect(serializer.to_hash.keys).to contain_exactly(
          :ai_virtual_chat_level,
          :allow_audio_transcripts,
          :allow_individual_assign,
          :allow_video_popup_translation,
          :allows_help_requests,
          :allows_review_requests,
          :can_share_to_portfolio,
          :categories,
          :chat_level,
          :class_days,
          :components,
          :display_on_dashboard,
          :enable_vocab_tutorial_translations,
          :end_date,
          :first_unit_id,
          :id,
          :is_template,
          :last_unit_id,
          :level,
          :name,
          :portfolio_activity_types,
          :school_id,
          :sections,
          :share_to_google_classroom,
          :share_to_portfolio,
          :show_estimated_times,
          :standard_set_ids,
          :start_date,
          :video_subtitle_languages,
          :video_transcript_languages
        )
      end

      describe 'the allow_audio_transcripts attribute,' do
        it 'returns true when the course allows audio transcripts' do
          allow(course).to receive(:allow_audio_transcripts).and_return(true)

          expect(serializer.to_hash[:allow_audio_transcripts]).to eq(true)
        end

        it 'returns false when the course does not allow audio transcripts' do
          allow(course).to receive(:allow_audio_transcripts).and_return(false)

          expect(serializer.to_hash[:allow_audio_transcripts]).to eq(false)
        end
      end

      describe 'the allow_individual_assign attribute,' do
        it 'returns true when the course allows individual assign' do
          allow(course).to receive(:allow_individual_assign).and_return(true)

          expect(serializer.to_hash[:allow_individual_assign]).to eq(true)
        end

        it 'returns false when the course does not allow individual assign' do
          allow(course).to receive(:allow_individual_assign).and_return(false)

          expect(serializer.to_hash[:allow_individual_assign]).to eq(false)
        end
      end

      describe 'the allow_video_popup_translation attribute,' do
        it 'returns true when the course allows video popup translation' do
          allow(course).to receive(:allow_video_popup_translation).and_return(true)

          expect(serializer.to_hash[:allow_video_popup_translation]).to eq(true)
        end

        it 'returns false when the course does not allow video popup translation' do
          allow(course).to receive(:allow_video_popup_translation).and_return(false)

          expect(serializer.to_hash[:allow_video_popup_translation]).to eq(false)
        end
      end

      describe 'the allows_help_requests attribute,' do
        it 'returns true when the course allows help requests' do
          allow(course).to receive(:allows_help_requests).and_return(true)

          expect(serializer.to_hash[:allows_help_requests]).to eq(true)
        end

        it 'returns false when the course does not allow help requests' do
          allow(course).to receive(:allows_help_requests).and_return(false)

          expect(serializer.to_hash[:allows_help_requests]).to eq(false)
        end
      end

      describe 'the allows_review_requests attribute,' do
        it 'returns true when the course allows review requests' do
          allow(course).to receive(:allows_review_requests).and_return(true)

          expect(serializer.to_hash[:allows_review_requests]).to eq(true)
        end

        it 'returns false when the course does not allow review requests' do
          allow(course).to receive(:allows_review_requests).and_return(false)

          expect(serializer.to_hash[:allows_review_requests]).to eq(false)
        end
      end

      describe 'the categories attribute,' do
        it 'returns the categories attributes' do
          category_1 = create(:category, course: course)
          category_2 = create(:category, course: course)

          scoring_ruleset_1 = create(:scoring_ruleset, category: category_1)
          scoring_ruleset_2 = create(:scoring_ruleset, category: category_2)

          allow(course_options).to receive(:scoring_ruleset_by_id)
            .with(category_1.current_scoring_ruleset_id)
            .and_return(scoring_ruleset_1)
          allow(course_options).to receive(:scoring_ruleset_by_id)
            .with(category_2.current_scoring_ruleset_id)
            .and_return(scoring_ruleset_2)
          # The course options returns an array of categories, including the
          # assessment count
          allow(course_options).to receive(:categories_with_assessment_count_for_course)
            .with(course)
            .and_return(
              [
                OpenStruct.new(id: category_1.id, assessment_count: 3),
                OpenStruct.new(id: category_2.id, assessment_count: 0)
              ]
            )

          expect(serializer.to_hash[:categories]).to eq(
            [
              {
                id: category_1.id,
                name: category_1.name,
                weighting_percent: category_1.weighting_percent,
                has_assessment_assignments: true,
                has_assignments: category_1.has_assignments?,
                credit_only: category_1.credit_only,
                max_attempts: category_1.max_attempts,
                enhanced_feedback_disabled: category_1.enhanced_feedback_disabled,
                accept_late_work: category_1.accept_late_work,
                late_work_penalty: category_1.late_work_penalty,
                penalty_percent: category_1.penalty_percent,
                rank: category_1.rank,
                drop_low_scores: category_1.drop_low_scores,
                current_scoring_ruleset: {
                  id: scoring_ruleset_1.id,
                  ignore_accents: scoring_ruleset_1.ignore_accents,
                  ignore_capitalization: scoring_ruleset_1.ignore_capitalization,
                  ignore_punctuation: scoring_ruleset_1.ignore_punctuation
                }
              },
              {
                id: category_2.id,
                name: category_2.name,
                weighting_percent: category_2.weighting_percent,
                has_assessment_assignments: false,
                has_assignments: category_2.has_assignments?,
                credit_only: category_2.credit_only,
                max_attempts: category_2.max_attempts,
                enhanced_feedback_disabled: category_2.enhanced_feedback_disabled,
                accept_late_work: category_2.accept_late_work,
                late_work_penalty: category_2.late_work_penalty,
                penalty_percent: category_2.penalty_percent,
                rank: category_2.rank,
                drop_low_scores: category_2.drop_low_scores,
                current_scoring_ruleset: {
                  id: scoring_ruleset_2.id,
                  ignore_accents: scoring_ruleset_2.ignore_accents,
                  ignore_capitalization: scoring_ruleset_2.ignore_capitalization,
                  ignore_punctuation: scoring_ruleset_2.ignore_punctuation
                }
              }
            ]
          )
        end
      end
    end

    describe 'the chat_level attribute,' do
      it 'returns the course chat level' do
        expect(serializer.to_hash[:chat_level]).to eq(safe_date_string(course.chat_level))
      end
    end

    describe 'the components attribute,' do
      let(:component_1) do
        instance_double(
          Maestro::CoursePackage,
          content_type: 'component',
          id: 111,
          response: { 'id' => 111, 'name' => 'Component 1' }
        )
      end
      let(:component_2) do
        instance_double(
          Maestro::CoursePackage,
          content_type: 'component',
          id: 222,
          response: { 'id' => 222, 'name' => 'Component 2' }
        )
      end

      it 'returns the id of all the course component packages' do
        allow(course_options).to receive(:course_packages_by_course).and_return(
          course.id => {
            'component' => [component_1, component_2]
          }
        )

        expect(serializer.to_hash[:components]).to contain_exactly(
          component_1.id, component_2.id
        )
      end
    end

    describe 'the enable_vocab_tutorial_translations attribute,' do
      it 'returns true when the course enables vocab tutorial translations' do
        allow(course).to receive(:enable_vocab_tutorial_translations).and_return(true)

        expect(serializer.to_hash[:enable_vocab_tutorial_translations]).to eq(true)
      end

      it 'returns false when the course does not enable vocab tutorial translations' do
        allow(course).to receive(:enable_vocab_tutorial_translations).and_return(false)

        expect(serializer.to_hash[:enable_vocab_tutorial_translations]).to eq(false)
      end
    end

    describe 'the end_date attribute,' do
      it 'returns the course end date' do
        expect(serializer.to_hash[:end_date]).to eq(safe_date_string(course.end_date))
      end
    end

    describe 'the first_unit_id attribute,' do
      it 'returns the first unit id of the course' do
        expect(serializer.to_hash[:first_unit_id]).to eq(course.first_unit_id)
      end
    end

    describe 'the id attribute,' do
      it 'returns the course id' do
        expect(serializer.to_hash[:id]).to eq(course.id)
      end
    end

    describe 'the is_template attribute,' do
      it 'returns true when the course is a course template' do
        allow(course).to receive(:is_template).and_return(true)

        expect(serializer.to_hash[:is_template]).to eq(true)
      end

      it 'returns false when the course is not a course template' do
        allow(course).to receive(:is_template).and_return(false)

        expect(serializer.to_hash[:is_template]).to eq(false)
      end
    end

    describe 'the last_unit_id attribute,' do
      it 'returns the last unit id of the course' do
        expect(serializer.to_hash[:last_unit_id]).to eq(course.last_unit_id)
      end
    end

    describe 'the level attribute,' do
      let(:component) do
        instance_double(
          Maestro::CoursePackage,
          content_type: 'component',
          id: 111,
          response: { 'id' => 111, 'name' => 'Component 1' }
        )
      end
      let(:level_1) do
        instance_double(
          Maestro::CoursePackage,
          content_type: 'level',
          id: 222,
          response: { 'id' => 222, 'name' => 'Level 1' }
        )
      end
      let(:level_2) do
        instance_double(
          Maestro::CoursePackage,
          content_type: 'level',
          id: 333,
          response: { 'id' => 333, 'name' => 'Level 2' }
        )
      end

      it 'returns nil when the course has no level packages' do
        allow(course_options).to receive(:course_packages_by_course).and_return(
          course.id => {
            'component' => [component]
          }
        )

        expect(serializer.to_hash[:level]).to be_nil
      end

      it 'returns the id of the first course level package' do
        allow(course_options).to receive(:course_packages_by_course).and_return(
          course.id => {
            'component' => [component],
            'level' => [level_1, level_2]
          }
        )

        expect(serializer.to_hash[:level]).to eq(level_1.id)
      end
    end

    describe 'the name attribute,' do
      it 'returns the course name' do
        expect(serializer.to_hash[:name]).to eq(course.name)
      end
    end

    describe 'the school_id attribute,' do
      it 'returns the course school id' do
        expect(serializer.to_hash[:school_id]).to eq(course.school_id)
      end
    end

    describe 'the sections attribute,' do
      it 'returns false when the course has no section' do
        expect(serializer.to_hash[:sections]).to eq(false)
      end

      it 'returns the attributes of all the course sections' do
        co_instructor_1 = create(:instructor)
        co_instructor_2 = create(:instructor)
        section_1 = create(
          :section,
          course: course,
          instructor: instructor,
          instructors: [co_instructor_1, co_instructor_2]
        )
        section_2 = create(:section, course: course)

        # Reload the sections to be sure to have all the section instructors.
        section_1.reload
        section_2.reload

        expect(serializer.to_hash[:sections]).to contain_exactly(
          {
            id: section_1.id,
            name: section_1.name,
            section_instructors: section_1.section_instructors.map do |section_instructor|
              {
                full_name: section_instructor.instructor.full_name,
                role: section_instructor.role,
                first_name: section_instructor.instructor.first_name,
                last_name: section_instructor.instructor.last_name
              }
            end,
            additional_info: section_1.additional_info,
            hide_owner_name: section_1.hide_owner_name
          },
          {
            id: section_2.id,
            name: section_2.name,
            section_instructors: section_2.section_instructors.map do |section_instructor|
              {
                full_name: section_instructor.instructor.full_name,
                role: section_instructor.role,
                first_name: section_instructor.instructor.first_name,
                last_name: section_instructor.instructor.last_name
              }
            end,
            additional_info: section_2.additional_info,
            hide_owner_name: section_2.hide_owner_name
          }
        )
      end
    end

    describe 'the share_to_google_classroom attribute,' do
      it 'returns true when the course is configured to share to google classroom' do
        allow(course).to receive(:share_to_google_classroom).and_return(true)

        expect(serializer.to_hash[:share_to_google_classroom]).to eq(true)
      end

      it 'returns false when the course is not configured to share to google classroom' do
        allow(course).to receive(:share_to_google_classroom).and_return(false)

        expect(serializer.to_hash[:share_to_google_classroom]).to eq(false)
      end
    end

    describe 'the show_estimated_times attribute,' do
      it 'returns true when the course shows estimated times' do
        allow(course).to receive(:show_estimated_times).and_return(true)

        expect(serializer.to_hash[:show_estimated_times]).to eq(true)
      end

      it 'returns false when the course does not show estimated times' do
        allow(course).to receive(:show_estimated_times).and_return(false)

        expect(serializer.to_hash[:show_estimated_times]).to eq(false)
      end
    end

    describe 'standard_set_ids attribute,' do
      let(:standard_set_1) { create(:standard_set) }
      let(:standard_set_2) { create(:standard_set) }
      let(:standard_set_3) { create(:standard_set) }
      let(:course) do
        # We must create a program config with the supported standard sets before
        # the course.
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set_1, standard_set_2, standard_set_3]
        )
        create(
          :course,
          program: program,
          standard_sets: [standard_set_1, standard_set_2]
        )
      end

      it 'returns the standard sets associated with the course' do
        expect(serializer.to_hash[:standard_set_ids]).to contain_exactly(
          standard_set_1.id, standard_set_2.id
        )
      end
    end

    describe 'the start_date attribute,' do
      it 'returns the course start date' do
        expect(serializer.to_hash[:start_date]).to eq(safe_date_string(course.start_date))
      end
    end

    describe 'the video_subtitle_languages attribute,' do
      it 'returns the course video subtitle languages' do
        expect(serializer.to_hash[:video_subtitle_languages]).to(
          eq(course.video_subtitle_languages)
        )
      end
    end

    describe 'the video_transcript_languages attribute,' do
      it 'returns the course video transcript languages' do
        expect(serializer.to_hash[:video_transcript_languages]).to(
          eq(course.video_transcript_languages)
        )
      end
    end
  end
end
