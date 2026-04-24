describe QuestionResultsController do
  include SharedSubmissionClientStubs

  require 'requests/login_helper_methods'
  require 'requests/shared_require_user_examples'

  describe 'POST #create' do
    let(:student) { create(:student) }
    let(:program) { create(:program_with_toc_entries) }

    context 'with a preview activity,' do
      let(:content_key) { 'a52ddbebbe653e8193f884bf7c3202c9' }
      let(:lesson) { program.units.first.lessons.first }
      let(:strand) { lesson.strands.first }
      let(:activity_id) { rand(10_000) }

      let(:content) do
        File.read(File.join('spec', 'fixtures', 'xml', 'image_choice.xml'))
      end

      before do
        create(:concept, lesson: lesson, id: strand.location)
        content_cache = CacheManager.new('cms_preview_content')
        content_cache.cache_put(content_key, content, 10.seconds.to_i)
      end

      def target_url
        section_activity_question_results_path(activity_id:, section_id: 0)
      end

      def do_request
        post(
          target_url,
          params: {
            activity: {
              activity_type: 'image_choice',
              cms_revision_id: 1000,
              content_key:
            },
            program_id: program.id,
            inputs: [
              { label: 'question_01', response: 123 },
              { label: 'question_02', response: 456 }
            ]
          },
          as: :json
        )
      end

      include_examples 'require logged in user', :json

      context 'with a logged in user,' do
        before do
          log_in_user_with_access_to_programs(student, [program])
          stub_nil_submission_find
          stub_submission_create
        end

        it 'renders json with feedback for each input' do
          do_request

          expect(response).to be_ok

          expect(JSON.parse(response.body)).to eq(
            'question_01' => { 'correctness' => 'correct' },
            'question_02' => { 'correctness' => 'incorrect' }
          )

          expect(assigns[:activity]).to be_a PreviewActivity
          expect(assigns[:attempt]).to be_a PreviewAttempt
          expect(assigns[:current_section]).to eq Section.section_zero

          expect do
            assigns[:activity].save(validate: false)
          end.to raise_error ActiveRecord::ReadOnlyRecord
        end
      end
    end

    context 'with a non-preview activity,' do
      let(:activity) { create(:activity) }
      context 'with fill in the blanks activity' do
        let(:content_filepath) do
          File.join(
            'spec',
            'fixtures',
            'xml',
            'fill_in_the_blanks_enhanced_feedback.xml'
          )
        end

        def target_url(section_id)
          section_activity_question_results_path(
            activity_id: activity.id, section_id:
          )
        end

        def do_request(label: 'question_01_wol_1', response: 'nada', section_id: 0)
          post(
            target_url(section_id),
            params: {
              inputs: [
                { label:, response: },
                { label: 'question_01_wol_2', response: 'test' }
              ]
            },
            as: :json
          )
        end

        before do
          allow(Activity).to receive(:filepath_from_revision_id).with(
            activity.cms_revision_id,
            false,
            false
          ).and_return(content_filepath)
        end

        include_examples 'require logged in user', :json

        context 'with a logged in user,' do
          before do
            log_in_user_with_access_to_programs(student, [program])
            stub_nil_submission_find
            stub_submission_create
          end

          it 'does not render enhanced feedback for a fill-in-the-blanks ' \
             'activity if the activity is assigned in a gradebook ' \
             'category with enhanced feedback disabled' do
            course = create(:course)
            section = create(:section, course:)
            create(:enrollment, section:, user: student)

            category = create(:category, course:, enhanced_feedback_disabled: true)

            assignment = create(
              :assignment,
              assignable: activity,
              category:,
              section:,
            )

            do_request(section_id: section.id)

            expect(response).to be_ok

            results = response.parsed_body
            expect(results['question_01_wol_1']['correctness']).to eq('correct')
            expect(results['question_01_wol_1']['correct_answer']).to eq('Nada.')
            expect(results['question_01_wol_1']['enhanced_feedback_items']).to be_nil

            expect(results['question_01_wol_2']['correctness']).to eq('incorrect')
            expect(results['question_01_wol_2']['correct_answer']).to be_present
            expect(results['question_01_wol_2']['enhanced_feedback_items']).to be_nil
          end

          it 'renders json with enhanced feedback for a fill-in-the-blanks ' \
             'with a single word response' do
            do_request

            expect(response).to be_ok

            results = response.parsed_body
            expect(results['question_01_wol_1']['correctness']).to eq('correct')
            expect(results['question_01_wol_1']['correct_answer']).to eq('Nada.')

            enhanced_feedback_items = results['question_01_wol_1']['enhanced_feedback_items']
            expect(enhanced_feedback_items.size).to eq(1)
            tokens = enhanced_feedback_items.first['tokens']
            expect(tokens.size).to eq(3)

            expect(tokens[0]).to eq(
              {
                'a11y_label' => 'Incorrect accent or capitalization',
                'correct_text' => 'N',
                'edit_type' => 'incorrect',
                'student_text' => 'n',
                'token_type' => 'word'
              }
            )
            expect(tokens[1]).to eq(
              {
                'correct_text' => 'ada',
                'edit_type' => 'none',
                'student_text' => 'ada',
                'token_type' => 'word'
              }
            )
            expect(tokens[2]).to eq(
              {
                'a11y_label' => 'Missing punctuation',
                'correct_text' => '.',
                'edit_type' => 'missing',
                'student_text' => '',
                'token_type' => 'punctuation'
              }
            )

            expect(results['question_01_wol_2']['correctness']).to eq('incorrect')
            expect(results['question_01_wol_2']['correct_answer']).to be_present
            expect(results['question_01_wol_2']['enhanced_feedback_items']).to be_present
          end

          it 'renders json with enhanced feedback for a fill-in-the-blanks ' \
             'with a multi-word response', aggregate_failures: true do
            do_request(label: 'question_01_wol_1', response: 'Nada. a')

            expect(response).to be_ok

            results = response.parsed_body
            expect(results['question_01_wol_1']['correctness']).to eq('incorrect')
            expect(results['question_01_wol_1']['correct_answer']).to eq('Nada.')

            enhanced_feedback_items = results['question_01_wol_1']['enhanced_feedback_items']
            expect(enhanced_feedback_items.size).to eq(3)
            tokens = enhanced_feedback_items.first['tokens']
            expect(tokens.size).to eq(1)

            expect(tokens[0]).to eq(
              {
                'correct_text' => 'Nada',
                'edit_type' => 'none',
                'student_text' => 'Nada',
                'token_type' => 'word'
              }
            )

            tokens = enhanced_feedback_items.second['tokens']
            expect(tokens.size).to eq(1)

            expect(tokens[0]).to eq(
              {
                'correct_text' => '.',
                'edit_type' => 'none',
                'student_text' => '.',
                'token_type' => 'punctuation'
              }
            )

            tokens = enhanced_feedback_items.third['tokens']
            expect(tokens.size).to eq(1)

            expect(tokens[0]).to eq(
              {
                'a11y_label' => 'Incorrect or extra word',
                'correct_text' => '',
                'edit_type' => 'incorrect_or_extra',
                'student_text' => 'a',
                'token_type' => 'word'
              }
            )

            expect(results['question_01_wol_2']['correctness']).to eq('incorrect')
            expect(results['question_01_wol_2']['correct_answer']).to be_present
            expect(results['question_01_wol_2']['enhanced_feedback_items']).to be_present
          end
        end
      end

      context 'with fill in the blanks chinese activity' do
        let(:content_filepath) do
          File.join(
            'spec',
            'fixtures',
            'xml',
            'fill_in_the_blanks_with_chinese_input.xml'
          )
        end

        def target_url(section_id)
          section_activity_question_results_path(
            activity_id: activity.id, section_id:
          )
        end

        def do_request(label: 'question_01_wol_1', response: '我近忙', section_id: 0)
          post(
            target_url(section_id),
            params: { inputs: [ { label:, response: }, ] },
            as: :json
          )
        end

        before do
          allow(Activity).to receive(:filepath_from_revision_id).with(
            activity.cms_revision_id,
            false,
            false
          ).and_return(content_filepath)
        end

        include_examples 'require logged in user', :json

        context 'with a logged in user,' do
          before do
            log_in_user_with_access_to_programs(student, [program])
            stub_nil_submission_find
            stub_submission_create
          end

          it 'renders json with enhanced feedback for a fill-in-the-blanks chinese activity' \
             'with a single word response' do
            do_request

            expect(response).to be_ok

            results = response.parsed_body
            expect(results['question_01_wol_1']['correctness']).to eq('incorrect')
            expect(results['question_01_wol_1']['correct_answer']).to eq('我最近很忙')

            enhanced_feedback_items = results['question_01_wol_1']['enhanced_feedback_items']
            expect(enhanced_feedback_items.size).to eq(1)
            tokens = enhanced_feedback_items.first['tokens']
            expect(tokens.size).to eq(5)

            expect(tokens[0]).to eq(
              {
                'correct_text' => '我',
                'edit_type' => 'none',
                'student_text' => '我',
                'token_type' => 'word'
              }
            )
            expect(tokens[1]).to eq(
              {
                'a11y_label' => 'Missing Word',
                'correct_text' => '最',
                'edit_type' => 'missing',
                'student_text' => '',
                'token_type' => 'word'
              }
            )
            expect(tokens[2]).to eq(
              {
                'correct_text' => '近',
                'edit_type' => 'none',
                'student_text' => '近',
                'token_type' => 'word'
              }
            )
            expect(tokens[3]).to eq(
              {
                'a11y_label' => 'Missing Word',
                'correct_text' => '很',
                'edit_type' => 'missing',
                'student_text' => '',
                'token_type' => 'word'
              }
            )
            expect(tokens[4]).to eq(
              {
                'correct_text' => '忙',
                'edit_type' => 'none',
                'student_text' => '忙',
                'token_type' => 'word'
              }
            )
          end
        end
      end
    end
  end
end
