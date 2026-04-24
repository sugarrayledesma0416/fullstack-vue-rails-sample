describe AI::GradingSuggestionGenerators::QuestionGenerator do
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.lessons.first }
  let(:activity) { create(:activity, activity_type: 'open_ended', lesson:) }
  let(:attempt) { create(:attempt_submitted, activity:) }
  let(:prompt) { create(:ai_grading_suggestion_prompt, model: 'gpt-4o-2024-08-06') } # We have to use a specific model that support json_schema
  let(:abtest_adapter) { instance_double(AI::AbtestAdapter) }
  let(:question_label) { 'question_01' }

  let(:grading_suggestion_input) do
    create(
      :ai_grading_suggestion_input,
      program:,
      attempt:,
      activity:,
      question_label:
    )
  end

  let(:student_submission) do
    'Some text the student submitted'
  end

  let(:job) do
    create(:ai_grading_suggestion_job, attempt:, question_label:)
  end

  let(:generator) do
    described_class.new(
      attempt:,
      grading_suggestion_input:,
      job_id: job.id,
      prompt:,
      question_label:,
      student_submission:
    )
  end

  describe '#generate' do
    let(:ai_suggestion) do
      {
        incorrect_text: 'student',
        error_explanation: 'something'
      }
    end

    let(:ai_response) do
      create_ai_response({ errors: [ai_suggestion] }.to_json)
    end

    def create_ai_response(content)
      Langchain::LLM::OpenAIResponse.new(
      {
        'choices' => [
            {
              'message' => {
                'content' => content
              }
            }
          ]
        }
      )
    end

    before do
      allow(AI::AbtestAdapter).to receive(:new).and_return(abtest_adapter)
      allow(abtest_adapter).to receive(:generate_grading_suggestions).and_return(ai_response.raw_response)

      # Mock AI Core prompts to return expected test values
      allow(VHL::AI::Prompts).to receive(:has_prompt?).with('grading_suggestion', program.language_code).and_return(false)
    end

    it 'makes a request to the AI service' do
      generator.generate

      system_message = {
        role: 'system',
        content: format(
          prompt.template_body,
          language_name: MaestroActivityEngine::Languages.language_name(program.language_code)
        )
      }
      user_message = {
        role: 'user',
        content: student_submission
      }
      expect(abtest_adapter).to have_received(:generate_grading_suggestions).with(
        prompt: prompt,
        messages: [system_message, user_message],
        experiment_name: 'gpt4o_version_upgrade',
        template_variables: {
          program_level: 'introductory',
          language_name: 'Spanish'
        },
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'ai_grading_suggestion',
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt.id
        }
      )
    end

    it 'passes the correct span attributes to the AI client' do
      generator.generate

      expect(abtest_adapter).to have_received(:generate_grading_suggestions).with(
        prompt: prompt,
        messages: [
          {
            role: 'system',
            content: prompt.template_body
          },
          {
            role: 'user',
            content: student_submission
          }
        ],
        experiment_name: 'gpt4o_version_upgrade',
        template_variables: {
          program_level: 'introductory',
          language_name: 'Spanish'
        },
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_NAME => 'ai_grading_suggestion',
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt.id
        }
      )
    end

    context 'when the AI response contains no suggestion' do
      let(:ai_response) do
        create_ai_response({}.to_json)
      end

      it 'does not create any grading suggestion record' do
        expect do
          generator.generate
        end.not_to change(AI::GradingSuggestion, :count)
      end

      it 'marks the job as completed' do
        generator.generate

        expect(job.reload.status).to eq('completed')
      end
    end

    context 'when the AI response contains suggestions,' do
      let(:ai_suggestion_1) do
        {
          incorrect_text: 'student',
          error_explanation: 'something'
        }
      end
      let(:ai_suggestion_2) do
        {
          incorrect_text: 'text',
          error_explanation: 'something'
        }
      end
      let(:ai_response) do
        create_ai_response({ errors: [ai_suggestion_1, ai_suggestion_2] }.to_json)
      end

      let(:common_attributes) do
        {
          activity:,
          ai_grading_suggestion_job_id: job.id,
          attempt:,
          grading_suggestion_input:,
          language_code: program.language_code,
          program:,
          prompt:,
          question_label:
        }
      end

      it 'creates a grading suggestion record for each suggestion' do
        expect do
          generator.generate
        end.to change(AI::GradingSuggestion, :count).by(2)
      end

      it 'saves the error explanation and incorrect text attributes' do
        generator.generate

        expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
          an_object_having_attributes(
            common_attributes.merge(
              error_explanation: ai_suggestion_1[:error_explanation],
              incorrect_text: ai_suggestion_1[:incorrect_text]
            )
          ),
          an_object_having_attributes(
            common_attributes.merge(
              error_explanation: ai_suggestion_2[:error_explanation],
              incorrect_text: ai_suggestion_2[:incorrect_text]
            )
          )
        )
      end

      it 'marks the job as completed' do
        generator.generate

        expect(job.reload.status).to eq('completed')
      end

      context 'when a grading suggestion is invalid,' do
        let(:ai_suggestion_2) do
          {
            incorrect_text: '',
            error_explanation: 'something'
          }
        end
        let(:ai_suggestion_3) do
          {
            incorrect_text: 'foo',
            error_explanation: 'something'
          }
        end
        let(:ai_response) do
          create_ai_response(
            { errors: [ai_suggestion_1, ai_suggestion_2, ai_suggestion_3] }.to_json
          )
        end

        it 'creates a grading suggestion record for each valid suggestion' do
          expect do
            generator.generate
          end.to change(AI::GradingSuggestion, :count).by(2)
        end

        it 'saves the error explanation and incorrect text attributes' do
          generator.generate

          expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
            an_object_having_attributes(
              common_attributes.merge(
                error_explanation: ai_suggestion_1[:error_explanation],
                incorrect_text: ai_suggestion_1[:incorrect_text]
              )
            ),
            an_object_having_attributes(
              common_attributes.merge(
                error_explanation: ai_suggestion_3[:error_explanation],
                incorrect_text: ai_suggestion_3[:incorrect_text]
              )
            )
          )
        end
      end

      context 'when the student submission is plaintext' do
        context 'when the incorrect text is present in the student response,' do
          it 'computes the offset of the incorrect text in the student response' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: 14,
                  incorrect_text_end_offset: 21
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: 5,
                  incorrect_text_end_offset: 9
                )
              )
            )
          end
        end

        context 'when the incorrect text is present in the student response but is ' \
                'not composed of whole words,' do
          let(:student_submission) do
            'Some context the student submitted that do not contain the whole TEXT word.'
          end

          it 'sets the offset of the incorrect text to not found' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: 17,
                  incorrect_text_end_offset: 24
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              )
            )
          end
        end

        context 'when the incorrect text is not present in the student response,' do
          let(:student_submission) do
            'okidoki'
          end

          it 'sets the offset of the incorrect text to not found' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              )
            )
          end
        end

        context 'when multiple suggestions have the same incorrect text,' do
          let(:ai_suggestion_2) do
            {
              incorrect_text: 'student',
              error_explanation: 'a different error'
            }
          end

          context 'when the student response contains multiple occurences of the ' \
                  'incorrect text than the number of suggestions with that incorrect text,' do
            let(:student_submission) do
              'Some text the student submitted that contains the word student multiple times.'
            end

            it 'sets the offset of the incorrect text of each suggestion to a distinct ' \
               'occurence of that text in the student response' do
              generator.generate

              expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_1[:error_explanation],
                    incorrect_text: ai_suggestion_1[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                ),
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_2[:error_explanation],
                    incorrect_text: ai_suggestion_2[:incorrect_text],
                    incorrect_text_begin_offset: 55,
                    incorrect_text_end_offset: 62
                  )
                )
              )
            end
          end

          context 'when the student response contains less occurences of the incorrect ' \
                  'text than the number of suggestions with that incorrect text' do
            let(:student_submission) do
              'Some text the student submitted that contains the incorrect work only once.'
            end

            it 'sets the offset of the incorrect text of the each suggestion to a ' \
               'distinct occurence of that text, and sets the offset of the remining ' \
               'suggestions to the last occurence of that text' do
              generator.generate

              expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_1[:error_explanation],
                    incorrect_text: ai_suggestion_1[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                ),
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_2[:error_explanation],
                    incorrect_text: ai_suggestion_2[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                )
              )
            end
          end
        end
      end

      context 'when the student submission is in HTML' do
        let(:student_submission) do
          '<p>Some text<ul> <li>the</li> <li>student<li></ul><b>submitted</b>using <i>HTML</i> formatting</p>'
        end

        context 'when the incorrect text is present in the student response,' do
          it 'computes the offset of the incorrect text in the student response' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: 14,
                  incorrect_text_end_offset: 21
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: 5,
                  incorrect_text_end_offset: 9
                )
              )
            )
          end
        end

        context 'when the incorrect text is present in the student response but is ' \
                'not composed of whole words,' do
          let(:student_submission) do
            '<p>Some <b>context</b> the student submitted that do not contain the whole TEXT word.</p>'
          end

          it 'sets the offset of the incorrect text to not found' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: 17,
                  incorrect_text_end_offset: 24
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              )
            )
          end
        end

        context 'when the incorrect text is not present in the student response,' do
          let(:student_submission) do
            '<p>Oki <b>Doki</b></p>'
          end

          it 'sets the offset of the incorrect text to not found' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: -1,
                  incorrect_text_end_offset: -1
                )
              )
            )
          end
        end

        context 'when multiple suggestions have the same incorrect text,' do
          let(:ai_suggestion_2) do
            {
              incorrect_text: 'student',
              error_explanation: 'a different error'
            }
          end

          context 'when the student response contains multiple occurences of the ' \
                  'incorrect text than the number of suggestions with that incorrect text,' do
            let(:student_submission) do
              '<p>Some text<ul> <li>the</li> <li>student<li></ul><b>submitted</b>' \
              'that contains the word student multiple times.</p>'
            end

            it 'sets the offset of the incorrect text of each suggestion to a distinct ' \
               'occurence of that text in the student response' do
              generator.generate

              expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_1[:error_explanation],
                    incorrect_text: ai_suggestion_1[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                ),
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_2[:error_explanation],
                    incorrect_text: ai_suggestion_2[:incorrect_text],
                    incorrect_text_begin_offset: 53,
                    incorrect_text_end_offset: 60
                  )
                )
              )
            end
          end

          context 'when the student response contains less occurences of the incorrect ' \
                  'text than the number of suggestions with that incorrect text' do
            let(:student_submission) do
              '<p>Some text<ul> <li>the</li> <li>student<li></ul><b>submitted</b>' \
              'that contains the incorrect work only once.</p>'
            end

            it 'sets the offset of the incorrect text of the each suggestion to a ' \
               'distinct occurence of that text, and sets the offset of the remining ' \
               'suggestions to the last occurence of that text' do
              generator.generate

              expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_1[:error_explanation],
                    incorrect_text: ai_suggestion_1[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                ),
                an_object_having_attributes(
                  common_attributes.merge(
                    error_explanation: ai_suggestion_2[:error_explanation],
                    incorrect_text: ai_suggestion_2[:incorrect_text],
                    incorrect_text_begin_offset: 14,
                    incorrect_text_end_offset: 21
                  )
                )
              )
            end
          end
        end

        context 'when the student response is invalid HTML' do
          let(:student_submission) do
            '<p>Some text<ul> <li>the</closing_li> <li>student<li></ul></p></p></p>'
          end

          it 'computes the offset of the incorrect text in the student response' do
            generator.generate

            expect(AI::GradingSuggestion.order(id: :desc).limit(2)).to contain_exactly(
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_1[:error_explanation],
                  incorrect_text: ai_suggestion_1[:incorrect_text],
                  incorrect_text_begin_offset: 14,
                  incorrect_text_end_offset: 21
                )
              ),
              an_object_having_attributes(
                common_attributes.merge(
                  error_explanation: ai_suggestion_2[:error_explanation],
                  incorrect_text: ai_suggestion_2[:incorrect_text],
                  incorrect_text_begin_offset: 5,
                  incorrect_text_end_offset: 9
                )
              )
            )
          end
        end
      end
    end
  end
end
