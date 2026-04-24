def create_fill_in_the_blanks_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'fill_in_the_blanks.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Fill in the blanks activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) do
    create(:course,
           owner: instructor,
           program: program,
           allows_help_requests: true,
           allows_review_requests: true)
  end
  let(:section) { create(:section, course: course, instructor: instructor) }

  # ID is needed here because is specified in fixture file.
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_fill_in_the_blanks_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::FillInTheBlanks.new(activity, media_items) }
  let(:student_path_to_activity) { section_activity_path(section.id, activity) }
  let(:instructor_path_to_activity) { section_activity_path('0', activity) }
  let(:fake_submissions) { {} }
  let(:answers_saved_no_submitted_msg) do
    'Your answers will be SAVED. They will NOT be submitted for a grade.'
  end
  let(:one_question_not_answered_msg) { '1 question is unanswered.' }
  let(:two_questions_not_answered_msg) { '2 questions are unanswered.' }
  let(:no_changes_to_save_msg) { 'No changes to save!' }

  context 'as a student' do
    it_behaves_like 'a student doing the fill in the blanks activity' do
      scenario 'I can request help and reviews', nondeterministic: true do
        ignoring_angular do
          direction_line_help_request_comment = 'a request help on the direction line'
          question_help_request_comment = 'some request help comment'

          visit section_activity_path(section.id, activity)
          for_preview_page(activity_data) do
            # Add an help request on the direction line and on a question
            { from_direction_line => direction_line_help_request_comment,
              from_fib_question(1) => question_help_request_comment }.each do |item, item_comment|
              # insert 2 comments. The first one is a temporary one, it will be deleted
              comments = ['some temporary comment', item_comment]
              comments.each do |comment|
                validate_adding_instructor_help_request(
                  item: item,
                  comment: comment,
                  helpable: [
                    from_direction_line,
                    # whole questions are helpable
                    from_fib_question(1),
                    from_fib_question(2),
                    from_fib_question(3),
                    from_fib_question(4)
                  ],
                  non_helpable: [
                    # wol are not helpable
                    from_fib_question(1).wol(1),
                    from_fib_question(1).wol(2),
                    from_fib_question(2).wol(1),
                    from_fib_question(3).wol(1),
                    from_fib_question(4).wol(1)
                  ]
                )
              end
              expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
              expect_help_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
              remove_help_request(item: item, request_number: 1)
              expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
            end

            # correct answer but with wrong punctuation
            from_fib_question(1).wol(1).choose_answer('answer, text 1.')
            # wrong answer
            from_fib_question(1).wol(2).choose_answer('wrong answer')
            # correct answer
            from_fib_question(2).wol(1).choose_answer('answer text 3')

            accept_alert do
              @page_object.button(:submit).click
            end
          end

          for_submit_page(activity_data) do
            # help requests are displayed
            { from_direction_line => direction_line_help_request_comment,
              from_fib_question(1) => question_help_request_comment }.each do |item, comment|
              expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
            end

            accept_alert do
              @page_object.button(:accept).click
            end
          end

          for_accept_page(activity_data) do
            # help requests are displayed
            { from_direction_line => direction_line_help_request_comment,
              from_fib_question(1) => question_help_request_comment }.each do |item, comment|
              expect_help_request_to_be_displayed(item: item, request_number: 1, comment: comment)
            end

            # Request review
            with_element(from_fib_question(1).wol(2)) do |item|
              comments = ['some request review comment', 'another request review comment']
              comments.each do |comment|
                validate_adding_instructor_review_request(
                  item: item,
                  comment: comment,
                  helpable: [
                    # incorrect questions are helpable
                    from_fib_question(1).wol(2)
                  ],
                  non_helpable: [
                    from_direction_line,
                    # whole questions are not helpable
                    from_fib_question(1),
                    from_fib_question(2),
                    from_fib_question(3),
                    from_fib_question(4),
                    # correct and blank answers are not helpable
                    from_fib_question(1).wol(1),
                    from_fib_question(2).wol(1),
                    from_fib_question(3).wol(1),
                    from_fib_question(4).wol(1)
                  ]
                )
              end
              expect_review_request_to_be_displayed(item: item, request_number: 1, comment: comments[0])
              expect_review_request_to_be_displayed(item: item, request_number: 2, comment: comments[1])
              remove_review_request(item: item, request_number: 1)
              expect_review_request_to_be_displayed(item: item, request_number: 1, comment: comments[1])
            end
          end

          # Because the last request in this test is asynchronous, the test can
          # start tearing down the data (truncating activities table) before
          # the request completes, causing a validation error:
          # Validation failed: Activity must exist
          # Adding this bogus "visit" call prevents the teardown from starting
          # until after the help request is saved.
          visit section_activity_path(section.id, activity)
        end
      end

      scenario 'I can see vtext_reference' do
        visit section_activity_path(section.id, activity)
        expect(page).to have_css('.test-vtext_reference', count: 2)
      end

      scenario 'I do not see vtext_reference when activity has no pages' do
        activity.update(page: nil)
        visit section_activity_path(section.id, activity)
        expect(page).to have_no_css('.test-vtext_reference')
      end

      scenario 'I see a link to vText when I have vtext privileges' do
        access_guardian = AccessGuardian.new(student, program)
        allow(access_guardian).to receive(:has_vtext?).and_return(true)
        allow(AccessGuardian).to receive(:new).and_return(access_guardian)
        expected_link = 'blah.html'
        vtext_linker = double('vtext_linker', 'activity_linkable?': true, link: expected_link)
        allow(VtextLinker).to receive(:new).and_return(vtext_linker)

        visit section_activity_path(section.id, activity)
        expect(page).to have_selector(".vtext_pages[data-helpable-type=vtext_reference][id=vtext_reference] > a[href='#{expected_link}']")
      end
    end
  end

  context 'as an instructor' do
    it_behaves_like 'an instructor seeing a fill in the blanks activity'
  end
end
