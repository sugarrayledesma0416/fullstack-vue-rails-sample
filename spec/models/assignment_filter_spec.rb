describe AssignmentFilter, :core => true do
  describe ".find_or_create" do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:lesson) { create(:lesson_with_toc_entries) }

    it "creates a new filter if a valid one doesn't exist" do
      expect(AssignmentFilter).to receive(:create!).with(user: instructor, course: course, lesson: lesson)
      AssignmentFilter.find_or_create(instructor, course, [lesson])
    end

    it "returns an existing filter even when a valid one exists for another course" do
      another_course = create(:course, :program => program)
      expected_filter = AssignmentFilter.create!(:user => instructor, :course => another_course, :lesson => lesson)
      expect(AssignmentFilter.find_or_create(instructor, another_course, [lesson])).to eql expected_filter
    end

    it "returns an existing filter even if it is from a closed course" do
      closed_course = create(:closed_course, :program => program)
      closed_course_filter = AssignmentFilter.create!(:user => instructor, :course => closed_course, :lesson => lesson)
      expect(AssignmentFilter.find_or_create(instructor, closed_course, [lesson])).to eql closed_course_filter
    end

    it "creates a new filter if one exists but is from an archived course" do
      archived_course = create(:archived_course, :program => program)
      AssignmentFilter.create!(:user => instructor, :course => archived_course, :lesson => lesson)
      expect(AssignmentFilter).to receive(:create!).with(:user => instructor, :course => course, :lesson => lesson)
      AssignmentFilter.find_or_create(instructor, course, [lesson])
    end
  end

  describe '#partner_chat_permissions_filter' do
    let(:instructor) { build_stubbed(:instructor) }
    let(:program) { build_stubbed(:program) }
    let(:lesson) { create(:lesson_with_toc_entries) }

    let(:activities) do
      [
        create(:activity, activity_type: 'partner_chat', lesson: lesson),
        create(:activity, activity_type: 'info_gap_partner_chat', lesson: lesson),
        create(:activity, activity_type: 'fill_in_the_blanks', lesson: lesson)
      ]
    end

    before do
      allow(program).to receive_message_chain(:activities, :by_component).and_return(activities)
    end

    context 'when course does not exist' do
      it 'does not error' do
        pchat_course_filter = described_class.create!(course: nil, user: instructor, lesson: lesson)
        expect{ pchat_course_filter.filter(activities) }.not_to raise_error
      end
    end

    context 'when the course does not have partner chat permissions' do
      it 'filters out the partner chat activities' do
        not_chat_course = create(:open_course, program: program, chat_level: 'disabled')
        not_chat_course_filter = described_class.create!(course: not_chat_course, user: instructor, lesson: lesson)

        result = not_chat_course_filter.filter(activities)
        expect(result.map(&:activity_type)).not_to include('partner_chat', 'info_gap_partner_chat')
      end
    end

    context 'when the course does have partner chat permissions' do
      it 'does not filter partner chat activities' do
        pchat_course = create(:open_course, program: program, chat_level: 'partner_chat')
        pchat_course_filter = described_class.create!(course: pchat_course, user: instructor, lesson: lesson)

        result = pchat_course_filter.filter(activities)
        expect(result.map(&:activity_type)).to include('partner_chat', 'info_gap_partner_chat')
      end
    end
  end

  describe '#filter' do
    let(:instructor) { build_stubbed(:instructor) }
    let(:program) { build_stubbed(:program) }
    let(:school) { create(:school) }
    let(:course) { create(:course, program:, school:) }

    context 'when no filter criteria are set' do
      let(:filter) { create(:assignment_filter, course:) }

      it 'returns all activities' do
        activities = create_list(:activity, 3)

        expect(filter.filter(activities)).to eql(activities)
      end

      context 'when no course exists,' do
        let(:filter) { create(:assignment_filter, course: nil) }

        it 'returns the partner chat activities' do
          activities = [create(:activity, activity_type: 'partner_chat')]

          expect(filter.filter(activities)).to eq(activities)
        end

        it 'returns the group chat activities' do
          activities = [create(:activity, activity_type: 'group_chat')]

          expect(filter.filter(activities)).to eq(activities)
        end
      end

      context 'when a course exists,' do
        context 'when the school has enabled chat support,' do
          before do
            create(:school_config, school:, chat_support_disabled: false)
          end

          it 'returns the partner chat activities' do
            activities = [create(:activity, activity_type: 'partner_chat')]

            expect(filter.filter(activities)).to eq(activities)
          end

          it 'returns the group chat activities' do
            activities = [create(:activity, activity_type: 'group_chat')]

            expect(filter.filter(activities)).to eq(activities)
          end
        end

        context 'when the school has disabled chat support,' do
          before do
            create(:school_config, school:, chat_support_disabled: true)
          end

          it 'does not return the partner chat activities' do
            activities = [create(:activity, activity_type: 'partner_chat')]

            expect(filter.filter(activities)).to be_empty
          end

          it 'does not return the group chat activities' do
            activities = [create(:activity, activity_type: 'group_chat')]

            expect(filter.filter(activities)).to be_empty
          end
        end
      end
    end

    context "when there are more than 100 activities " do
      before(:each) do
        @nr_of_activities = 105
        @activities = []
        @nr_of_activities.times do |i|
          @activities << create(:activity)
        end

        allow_any_instance_of(AssignmentFilter).to receive(:flattened_sorted_grouped_activities).and_return(@activities)
        @filter = create(:assignment_filter, :course => course)
        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
      end

      it "should return 100 activities" do
        expect(@filter.filter(@activities).count).to eql(100)
      end

      it "should return the request number of activities" do
        expect(@filter.filter(@activities, 50).count).to eql(50)
      end

      it "should return all activities if the request number of activities is greater" do
        expect(@filter.filter(@activities, 200).count).to eql(105)
      end

    end

    context "when filtering by lesson" do
      before(:each) do
        @lessons = [
          create(:lesson_with_toc_entries),
          create(:lesson_with_toc_entries),
          create(:lesson_with_toc_entries)]
        @this_lesson = @lessons.last
        @activities = [
          create(:activity, :lesson => @lessons[0]),
          create(:activity, :lesson => @lessons[1]),
          create(:activity, :lesson => @lessons[2])]
        @expected_activity = @activities.last
        @filter = create(:assignment_filter_by_lesson, :lesson_id => @this_lesson.id, :course => course)
        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
      end

      it "only returns activities for the specified lesson if they are in the course library" do
        expect(@filter.filter(@activities)).to eql [@expected_activity]
      end

      it 'returns activities for the specified lesson even if they are hidden in the course library' do
        @activities.each{ |activity| CourseLibraryActivity.hide_activity(activity.id, course.id) }

        expect(@filter.filter(@activities)).to eql [@expected_activity]
      end

      context "and filtering by strand" do
        before(:each) do
          @strand = @this_lesson.strands.first
          @filter.toc_entry_location = @strand.location
          @expected_activity = create(:activity,
            :lesson => @this_lesson,
            :toc_location => @strand.children.first.location)
          @activities << @expected_activity
        end

        it "only returns activities for the specified strand if they are in the course library", test_debt: true do
          # This fails intermittently, see assignment_intermittent_failure.txt
          # The seed does not replicate it.
          expect(@filter.filter(@activities)).to eql @strand.descendant_activities
        end

        it 'returns activities for the specified strand even if they are hidden in the course library' do
          @activities.each{ |activity| CourseLibraryActivity.hide_activity(activity.id, course.id) }

          expect(@filter.filter(@activities)).to eql @strand.descendant_activities
        end
      end
    end

    context "when filtering by section" do
      before(:each) do
        @activities = [
          create(:activity),
          create(:activity),
          create(:activity)
        ]
        @filter = create(:assignment_filter)
        @section = create(:section, :course => course)
        create(:assignment, :section => @section, :assignable => @activities.last)
        @filter.update!(:previous_section => @section, :course => course)
        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
      end

      it "should only return activities assigned in the specified section" do
        expect(@filter.filter(@activities)).to eql @section.activities
      end
    end

    context "when filtering by section and category" do
      before(:each) do
        @filter = create(:assignment_filter, course: course)
        @section = create(:section, course: course)
        first_category = create(:category, course: course)
        second_category = create(:category, course: course)
        third_category = create(:category, course: course)
        @first_activity = create(:activity)
        second_activity = create(:activity)
        third_activity = create(:activity)
        @activities = [@first_activity, second_activity, third_activity]
        create(
          :assignment,
          assignable: @first_activity,
          category: first_category,
          section: @section
        )
        create(
          :assignment,
          assignable: second_activity,
          category: second_category,
          section: @section
        )
        create(
          :assignment,
          assignable: third_activity,
          category: third_category,
          section: @section
        )
        @filter.update!(previous_section: @section, category: first_category)
        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
      end

      it 'only returns activities assigned in the specified section' do
        expect(@filter.filter(@activities)).to eql [@first_activity]
      end
    end

    context "when filtering by section and week" do
      before(:each) do
        allow(course).to receive(:program).and_return(program)
        @filter = create(:assignment_filter, :course => course)
        @section = create(:section, :course => course)
        first_category = create(:category, :course => course)
        second_category = create(:category, :course => course)
        third_category = create(:category, :course => course)
        first_activity = create(:activity)
        @second_activity = create(:activity)
        third_activity = create(:activity)
        @activities = [first_activity, @second_activity, third_activity]
        create(:assignment, :assignable => first_activity, :category => first_category, :section => @section)
        create(:assignment, :assignable => @second_activity, :category => second_category, :section => @section, :due_date => 15.days.ago.to_date)
        create(:assignment, :assignable => third_activity, :category => third_category, :section => @section, :due_date => 15.days.from_now.to_date)
        @filter.update!(:previous_section => @section, :week => Week.week_containing(15.days.ago.to_date).to_s, :course => course)
        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
      end

      it "should only return activities assigned in the specified section" do
        expect(@filter.filter(@activities)).to eql [@second_activity]
      end
    end

    context "when filtering by component" do
      before(:each) do
        @activities = [
          build_stubbed(:activity, :component_name => 'component_1'),
          build_stubbed(:activity, :component_name => 'component_2') ]
      end

      it "returns activities assigned in the specified component" do
        component = 'component_1'
        filter = create( :assignment_filter,
                                  :activity_type => '',
                                  :user => instructor,
                                  :course => course,
                                  :lesson_id => nil,
                                  :previous_section_id => nil,
                                  :component => component )

        expected_activities = [@activities.first]
        scope_activities = double
        allow(scope_activities).to receive(:where).with(:component_name => component).and_return(expected_activities)
        allow(course).to receive(:activities).and_return(scope_activities)
        expect(filter.filter(@activities)).to eql expected_activities
      end

      it "returns does not apply any filter when component is blank" do
        filter = create( :assignment_filter,
                                  :activity_type => '',
                                  :user => instructor,
                                  :course => course,
                                  :lesson_id => nil,
                                  :previous_section_id => nil,
                                  :component => '' )

        expected_activities = [@activities.first, @activities.last]
        expect(filter.filter(@activities)).to eql expected_activities
      end
    end

    context "when filtering by activity type" do
      before(:each) do
        @activities = [
          build_stubbed(:activity, :activity_type => 'open_ended'),
          build_stubbed(:activity, :activity_type => 'fill_in_the_blanks'),
          build_stubbed(:activity, :activity_type => 'open_ended') ]

        @expected_activities = [@activities.first,@activities.last]

        scope_activities = double
        allow(scope_activities).to receive(:where).with(:activity_type => ['open_ended']).and_return(@expected_activities)
        allow(scope_activities).to receive(:where).with(:component_name => '').and_return(@activities)
        allow(course).to receive(:activities).and_return(scope_activities)

        @filter = create( :assignment_filter,
                                  :activity_type => 'open_ended',
                                  :user => instructor,
                                  :course => course,
                                  :lesson_id => nil,
                                  :previous_section_id => nil,
                                  :component => "")
      end

      it "should only return activities assigned in the specified section" do
        expect(@filter.filter(@activities)).to eql(@expected_activities)
      end
    end

    context "when filtering by activity grading method" do
      before(:each) do
        @activities = [
          build_stubbed(:activity, :grading_method => 'mixed'),
          build_stubbed(:activity, :grading_method => 'instructor'),
          build_stubbed(:activity, :grading_method => 'auto'),
          build_stubbed(:activity, :grading_method => 'mixed')
        ]

        @expected_activities = [@activities.first,@activities.last]

        program = build_stubbed(:program)
        course = build_stubbed(:course, :owner => instructor, :program => program)
        scope_activities = double
        allow(scope_activities).to receive(:where).with(:grading_method => 'mixed').and_return(@expected_activities)
        allow(scope_activities).to receive(:where).with(:component_name => '').and_return(@activities)
        allow(course).to receive(:activities).and_return(scope_activities)

        @filter = create( :assignment_filter,
                                  :grading_method => 'mixed',
                                  :user => instructor,
                                  :course => course,
                                  :lesson_id => nil,
                                  :previous_section_id => nil,
                                  :component => "")
      end

      it "should only return activities assigned in the specified section" do
        expect(@filter.filter(@activities)).to eql(@expected_activities)
      end
    end

    context "when filtering by content type" do
      def setup_filter(params={})
        @activities = [
          build_stubbed(:activity),
          build_stubbed(:activity),
          build_stubbed(:activity),
          build_stubbed(:activity)
        ]

        allow(@activities[0]).to receive(:assessment?).and_return(false)
        allow(@activities[1]).to receive(:assessment?).and_return(true)
        allow(@activities[2]).to receive(:assessment?).and_return(true)
        allow(@activities[3]).to receive(:assessment?).and_return(false)

        allow(program).to receive_message_chain(:activities, :by_component).and_return(@activities)
        another_course = build_stubbed(:course, :program => program)
        params.merge!({ :user => instructor,
                        :course => another_course,
                        :lesson_id => nil,
                        :previous_section_id => nil,
                        :component => nil})

        @filter = create( :assignment_filter, params)
      end

      context "when content_type is blank" do
        it "returns only activities" do
          setup_filter({:content_type => ""})
          expected_activities = [@activities.first,@activities.last]
          expect(@filter.filter(@activities)).to eql(expected_activities)
        end
      end

      context "when content_type is nil" do
        it "returns only activities" do
          setup_filter({:content_type => nil})
          expected_activities = [@activities.first,@activities.last]
          expect(@filter.filter(@activities)).to eql(expected_activities)
        end
      end

      context "when content_type is Activities" do
        it "returns only activities" do
          setup_filter({:content_type => "Activities"})
          expected_activities = [@activities.first,@activities.last]
          expect(@filter.filter(@activities)).to eql(expected_activities)
        end
      end

      context "when content_type is Activities and Assessment" do
        it "returns activities and asssessment" do
          setup_filter({:content_type => "Activities and Assessment"})
          expected_activities = [@activities.first,@activities.last]
          expect(@filter.filter(@activities)).to eql(@activities)
        end
      end

      context "when content_type is Assessment" do
        it "returns only asssessments" do
          setup_filter({:content_type => "Assessment"})
          expected_activities = [@activities[1],@activities[2]]
          expect(@filter.filter(@activities)).to eql(expected_activities)
        end
      end
    end
  end
end
