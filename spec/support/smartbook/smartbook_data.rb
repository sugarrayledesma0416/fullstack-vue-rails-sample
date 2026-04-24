module SmartbookTest
  class SmartbookData
    class Question
      attr_accessor :activity_type, :definition, :result

      def initialize(activity_type:, definition:, result:)
        @activity_type = activity_type
        @definition = definition
        @result = result
      end

      def points_possible
        points_possible_for_question_type(activity_type)
      end

      def id
        @id ||= "#{learning_module_id}/interaction/interaction_#{question_number}"
      end

      def label
        @label ||= "question_#{question_number}"
      end

      def learning_module_id
        'https://netexlearning.com/487203'
      end

      def correct_responses_pattern
        definition[:correctResponsesPattern]
      end

      def initialized_submission_data(**attrs)
        {
          id: SecureRandom.uuid,
          timestamp: Time.now.utc,
          verb: { id: Xapi::VERB_INITIALIZED },
          object: object
        }.merge(attrs)
      end

      def answered_submission_data(response:, score: nil, timestamp: nil)
        submission_result = result
        if %w[open_ended multiple_choice].include?(activity_type)
          submission_result[:extensions][
            Smartbook::ResponseParser::SCORM_EXTENSIONS_KEY][:response] = response
        elsif activity_type == 'drawing'
          submission_result[:extensions][
            Smartbook::DrawingResponseParser::SCORM_EXTENSIONS_TCDRAW_KEY
          ] = { image: response }
        else
          submission_result[:response] = response
        end
        submission_result[:score] = score if score

        {
          id: SecureRandom.uuid,
          timestamp: timestamp || Time.now.utc,
          verb: { id: Xapi::VERB_ANSWERED },
          object: object,
          result: submission_result,
          context: {
            contextActivities: {
              parent: [
                id: learning_module_id,
                objectType: 'Activity'
              ]
            }
          }
        }
      end

      private def object
        {
          objectType: Xapi::Statement::OBJECT_TYPE_ACTIVITY,
          id: id,
          definition: definition
        }
      end

      private def points_possible_for_question_type(type)
        MaestroActivityEngine::ActivityContent::SmartBookContent
          .points_possible_for_question_type(type)
      end

      private def question_number
        @question_number ||= analytics[:Activity].sub(/^[0]+/, '')
      end

      private def analytics
        scorm_extensions[:analytics]
      end

      private def scorm_extensions
        result[:extensions][Smartbook::ResponseParser::SCORM_EXTENSIONS_KEY]
      end
    end

    def question_1_open_ended
      @question_1_open_ended ||= Question.new(
        activity_type: 'open_ended',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '1. Write something about yourself.' },
          interactionType: 'long-fill-in',
          correctResponsesPattern: ['']
        },
        result: {
          success: false,
          response: 'Me llamo Angela y soy profesor de Computadora. Soy de Mexico. Yo soy solomenta nina.',
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': '1.2,To identify yourself and others',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '001',
                'Section': 'D1G',
                'Modes of Communication': 'Interpretive Reading',
                'Learning Objectives': 'To identify yourself and others',
                'Standards': '1.2'
              }
            }
          }
        }
      )
    end

    def question_2_open_ended
      @question_2_open_ended ||= Question.new(
        activity_type: 'open_ended',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '2. Write something.' },
          interactionType: 'long-fill-in',
          correctResponsesPattern: ['']
        },
        result: {
          success: false,
          # TODO: Change this response
          response: 'Me llamo Angela y soy profesor de Computadora. Soy de Mexico. Yo soy solomenta nina.',
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': '1.2,To identify yourself and others',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '002',
                'Section': 'D1G',
                'Modes of Communication': 'Interpretive Reading',
                'Learning Objectives': 'To identify yourself and others',
                'Standards': '1.2'
              }
            }
          }
        }
      )
    end

    def question_3_open_ended
      @question_3_open_ended ||= Question.new(
        activity_type: 'open_ended',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '3. Write your name.' },
          interactionType: 'long-fill-in',
          correctResponsesPattern: ['']
        },
        result: {
          success: false,
          response: '',
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': '1.2,To identify yourself and others',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '003',
                'Section': 'D1G',
                'Modes of Communication': 'Interpretive Reading',
                'Learning Objectives': 'To identify yourself and others',
                'Standards': '1.2'
              }
            }
          }
        }
      )
    end

    def question_4_audio_recording
      @question_4_audio_recording ||= Question.new(
        activity_type: 'voice_recording',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '4. Describe what you did yesterday.' },
          interactionType: 'other',
          correctResponsesPattern: ['']
        },
        result: {
          success: false,
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': 'Interpersonal Speaking, Spell and pronounce Spanish words',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'UP',
                'Activity': '004',
                'Section': 'CCP1',
                'Modes of Communication': 'Interpersonal Speaking',
                'Learning Objectives': 'Spell and pronounce Spanish words',
                'Standards': '1.1, 1.2, 4.1'
              }
            }
          }
        }
      )
    end

    def question_5_multiple_choice
      @question_5_multiple_choice ||= Question.new(
        activity_type: 'multiple_choice',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '5a. ¿Tú o usted?. Decide.&nbsp;Would you use&nbsp;tú&nbsp;or&nbsp;usted&nbsp;to speak to the following people?.' },
          interactionType: 'choice',
          correctResponsesPattern: ['5ba89c0edf88fa426bd1a660230620d7[,]ac9dc7926d8933019824f1d1d5d09220[,]9d53d67d82f9456c6d1f2710214ef16b[,]a814e4eb62ffee42fe308f65c7ffd996[,]a983f9b57868564e47b307eee8ed4b33'],
          choices: [
            { id: '6ce65e8897b6117933f0e7a301a9d719', description: { en: 'tú' } },
            { id: '5ba89c0edf88fa426bd1a660230620d7', description: { en: 'usted' } },
            { id: '03f93d06ab1ed3b9f3c22256184e5c12', description: { en: 'tú.' } },
            { id: 'ac9dc7926d8933019824f1d1d5d09220', description: { en: 'usted.' } },
            { id: '9d53d67d82f9456c6d1f2710214ef16b', description: { en: 'tú.' } },
            { id: '435635745141be564b38ab9e2f85c057', description: { en: 'usted.' } },
            { id: 'a814e4eb62ffee42fe308f65c7ffd996', description: { en: 'tú.' } },
            { id: 'abfe6331c22f6f11b2be261606c61bb1', description: { en: 'usted.' } },
            { id: 'eddc810a2ff2dd446876702e92d8c9d3', description: { en: 'tú.' } },
            { id: 'a983f9b57868564e47b307eee8ed4b33', description: { en: 'usted.' } }
          ]
        },
        result: {
          success: false,
          response: '5ba89c0edf88fa426bd1a660230620d7[,]ac9dc7926d8933019824f1d1d5d09220[,]a814e4eb62ffee42fe308f65c7ffd996[,]a983f9b57868564e47b307eee8ed4b33',
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': '1.2,To identify yourself and others',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '005a',
                'Section': 'D1G',
                'Modes of Communication': 'Interpretive Reading',
                'Learning Objectives': 'To identify yourself and others',
                'Standards': '1.2'
              },
              correctResponsesPattern: '1.[.]usted[,]2.[.]usted[,]3.[.]tú[,]4.[.]tú[,]5.[.]usted',
            }
          }
        }
      )
    end

    def question_6_matching
      @question_6_matching ||= Question.new(
        activity_type: 'matching',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { en: '5b. How do the characters feel?.' },
          interactionType: 'matching',
          correctResponsesPattern: [
            '434fb08c79b8841256147dfb875711f4[.]693ed5a8c914fd1cb357ba4e6568f9d4[,]c7d9ab4913fc9f9f58259597635a4d97[.]3f929288f70619a728601fc845a77b33[,]233358951499b356c868f6801d05353d[.]dd67bd6cc58dcbc9049d3a36fbe01b6d[,]85619ca9a39859dc0643b3401ec305e1[.]401010eb1f9ca9fff10ef01904c2afd6[,]77828b701afe8e4fe27be43b80344f71[.]6c96bddc066687401f9d5f73d7640e68'
          ],
          source: [
            {
              id: '434fb08c79b8841256147dfb875711f4',
              description: { en: 'Who welcomes the pairs?.' }
            },
            {
              id: 'c7d9ab4913fc9f9f58259597635a4d97',
              description: { en: 'Who is Marisa?.' }
            },
            {
              id: '233358951499b356c868f6801d05353d',
              description: { en: 'How do the characters feel?.' }
            },
            {
              id: '85619ca9a39859dc0643b3401ec305e1',
              description: { en: 'How many siblings does Marisa have?.' }
            },
            {
              id: '77828b701afe8e4fe27be43b80344f71',
              description: { en: 'What is Mack like?.' }
            }
          ],
          target: [
            {
              id: 'dd67bd6cc58dcbc9049d3a36fbe01b6d',
              description: { en: 'Contentos.' }
            },
            {
              id: '6c96bddc066687401f9d5f73d7640e68',
              description: { en: 'Muy gracioso.' }
            },
            {
              id: '3f929288f70619a728601fc845a77b33',
              description: { en: 'La hija de Carmen y Luis.' }
            },
            {
              id: '693ed5a8c914fd1cb357ba4e6568f9d4',
              description: { en: 'La familia P&eacute;rez.' }
            },
            {
              id: '401010eb1f9ca9fff10ef01904c2afd6',
              description: { en: 'Dos.' }
            }
          ]
        },
        result: {
          success: false,
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': '1.2,To identify yourself and others',
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '005b',
                'Section': 'D1G',
                'Modes of Communication': 'Interpretive Reading',
                'Learning Objectives': 'To identify yourself and others',
                'Standards': '1.2'
              },
              correctResponsesPattern: '[1.[.]d.[,]2.[.]c.[,]3.[.]a.[,]4.[.]e.[,]5.[.]b.]'
            }
          }
        }
      )
    end

    def question_6_response_1_incorrect_1_missing
      @question_6_response_1_incorrect_1_missing ||=
        '434fb08c79b8841256147dfb875711f4[.]693ed5a8c914fd1cb357ba4e6568f9d4[,]' \
        'c7d9ab4913fc9f9f58259597635a4d97[.]3f929288f70619a728601fc845a77b33[,]' \
        '233358951499b356c868f6801d05353d[.]6c96bddc066687401f9d5f73d7640e68[,]' \
        '85619ca9a39859dc0643b3401ec305e1[.]401010eb1f9ca9fff10ef01904c2afd6'
    end

    def question_6_response_correct
      question_6_matching.correct_responses_pattern[0]
    end

    def question_7_dropdown_choice
      @question_7_dropdown_choice ||= Question.new(
          activity_type: 'matching',
          definition: {
              type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
              description: { en: 'Escoge la palabra correcta para completar cada oración.' },
              interactionType: 'matching',
              correctResponsesPattern: [
                '20ef707f913e4bcdbd50ae1ef095efe7[.]b5f4a825d030469887cf4c8d2b118450[,]c5669099f2754f2fa176c0b6f171899d[.]37b824dfa16d4eeda73eecfb7268ebf1[,]c675779d80904c07b12afd01d5105885[.]f647d5a3f4244124a0dbb0e598155d45[,]474c2dd192254c2cbc5c874063d59b66[.]512ec13d15604f1bb746056ed4c3f4f5'
              ],
              source: [
                {
                  id: '20ef707f913e4bcdbd50ae1ef095efe7',
                  description: { es: '1. México tiene    ciento    siento    veinte millones de habitantes.' }
                },
                {
                  id: 'c5669099f2754f2fa176c0b6f171899d',
                  description: { es: '2. En Washington, D.C. hay edificios muy    vellos    bellos    .' }
                },
                {
                  id: 'c675779d80904c07b12afd01d5105885',
                  description: { es: '3. En las zonas desérticas la temperatura puede subir a más de    sien    cien    grados.' }
                },
                {
                  id: '474c2dd192254c2cbc5c874063d59b66',
                  description: { es: '4. En México hay varias    sierras    cierras    que atraviesan el país de norte a sur.' }
                }
              ],
              target: [
                {
                  id: 'b5f4a825d030469887cf4c8d2b118450',
                  description: { es: 'ciento' }
                },
                {
                  id: 'e2947f8da872413ea74390566f07ff31',
                  description: { es: 'siento' }
                },
                {
                  id: 'e9621aad779646d999a3fd352463aa43',
                  description: { es: 'vellos' }
                },
                {
                  id: '37b824dfa16d4eeda73eecfb7268ebf1',
                  description: { es: 'bellos' }
                },
                {
                  id: '44eac36635ba4f538fd5cc6a9977e5e6',
                  description: { es: 'sien' }
                },
                {
                  id: 'f647d5a3f4244124a0dbb0e598155d45',
                  description: { es: 'cien' }
                },
                {
                  id: '512ec13d15604f1bb746056ed4c3f4f5',
                  description: { es: 'sierras' }
                },
                {
                  id: 'c0dfd71ce1404542b1114b3b29fbfd2d',
                  description: { es: 'cierras' }
                }
              ]
          },
          result: {
            success: false,
            response: '20ef707f913e4bcdbd50ae1ef095efe7[.]b5f4a825d030469887cf4c8d2b118450[,]c5669099f2754f2fa176c0b6f171899d[.]37b824dfa16d4eeda73eecfb7268ebf1[,]c675779d80904c07b12afd01d5105885[.]f647d5a3f4244124a0dbb0e598155d45[,]474c2dd192254c2cbc5c874063d59b66[.]512ec13d15604f1bb746056ed4c3f4f5',
            extensions: {
              'http://scorm.com/extensions/usa-data': {
                  iconCollectionQuiz: 'usa',
                  'competenceUsa': '1.2,To identify yourself and others',
                  'analytics': {
                    'Product': 'SB',
                    'Level': 'HS1',
                    'Unit': 'U1',
                    'Activity': '007',
                    'Section': 'D1G',
                    'Modes of Communication': 'Interpretive Reading',
                    'Learning Objectives': 'To identify yourself and others',
                    'Standards': '1.2'
                  },
                  correctResponsesPattern: '[1.[.]ciento[,]2.[.]bellos[,]3.[.]cien[,]4.[.]sierras]',
                }
            }
          }
      )
    end
    def question_7_response_incorrect
      @question_7_response_1_incorrect ||=
          '20ef707f913e4bcdbd50ae1ef095efe7[.]e2947f8da872413ea74390566f07ff31[,]'\
          'c5669099f2754f2fa176c0b6f171899d[.]37b824dfa16d4eeda73eecfb7268ebf1[,]'\
          'c675779d80904c07b12afd01d5105885[.]f647d5a3f4244124a0dbb0e598155d45[,]' \
          '474c2dd192254c2cbc5c874063d59b66[.]c0dfd71ce1404542b1114b3b29fbfd2d'
    end

    def question_8_binary_choice
      @question_8_binary_choice ||= Question.new(
          activity_type: 'matching',
          definition: {
              type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
              description: { en: 'Contesta cierto o falso.' },
              interactionType: 'matching',
              correctResponsesPattern: [
                '85f901d89e064a0aafb945664b0f641c[.]false[,]e58df37e97bb49aa87f6e9ea4e94196c[.]true[,]30ec455eeeab4b25a6aea4a7e36322f2[.]false[,]804b8a9ee37544a59165ce73084d6035[.]true[,]3656dffb3d084be1b585d685b4f063b5[.]false'
              ],
              source: [
                {
                  id: '85f901d89e064a0aafb945664b0f641c',
                  description: { es: '1. Los pinos son comunes en las praderas.' }
                },
                {
                  id: 'e58df37e97bb49aa87f6e9ea4e94196c',
                  description: { es: '2. Los montes y las llanuras forman parte de la geografía de un país.' }
                },
                {
                  id: '30ec455eeeab4b25a6aea4a7e36322f2',
                  description: { es: '3. La zona metropolitana no es un área muy poblada.' }
                },
                {
                  id: '804b8a9ee37544a59165ce73084d6035',
                  description: { es: '4. En las regiones semiáridas no hay mucho pasto.' }
                },
                {
                  id: '3656dffb3d084be1b585d685b4f063b5',
                  description: { es: '5. Un subcontinente es mayor que un continente.' }
                }
              ],
              target: [
                {
                  id: 'true',
                  description: { es: 'true' }
                },
                {
                  id: 'false',
                  description: { es: 'false' }
                }
              ]
          },
          result: {
              success: false,
              extensions: {
                'http://scorm.com/extensions/usa-data': {
                  iconCollectionQuiz: 'usa',
                  'competenceUsa': '1.2,To identify yourself and others',
                  'analytics': {
                      'Product': 'SB',
                      'Level': 'HS1',
                      'Unit': 'U1',
                      'Activity': '008',
                      'Section': 'D1G',
                      'Modes of Communication': 'Interpretive Reading',
                      'Learning Objectives': 'To identify yourself and others',
                      'Standards': '1.2'
                  },
                  correctResponsesPattern: '[1.[.]true[,]2.[.]true[,]3.[.]false[,]4.[.]true][,]5.[.]true]',
                }
              }
          }
      )
    end

    def question_8_response_incorrect
      @question_8_response_incorrect ||=
        '85f901d89e064a0aafb945664b0f641c[.]true[,]' \
        'e58df37e97bb49aa87f6e9ea4e94196c[.]true[,]' \
        '30ec455eeeab4b25a6aea4a7e36322f2[.]false[,]' \
        '804b8a9ee37544a59165ce73084d6035[.]false[,]' \
        '3656dffb3d084be1b585d685b4f063b5[.]true'
    end

    def question_9_drag_drop
      @question_9_drag_drop ||= Question.new(
        activity_type: 'matching',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: {"es":"A2. Ordena los sucesos del 1 al 5."},
          interactionType: 'matching',
          correctResponsesPattern: [
            '19012642d95140889905850e0b79d549[.]257977d6879645b4845d4b714d129709[,]9706ae4f78624519acbb4b6e95e7366c[.]5dfb77311b46471aba6a0f0c64ea74fd[,]d040f32c47ca4cbab15a90711d28de3f[.]267f4b27a4214124bcadd2c2cd6d136e[,]884a3a2b459e44e7b38cbd62fac38bee[.]5dfb77311b46471aba6a0f0c64ea74fd[,]05d75108ee14485ca11ca63fc54b0534[.]8088ed6185fc4e8fa4c74061e737ac74'
          ],
          source: [
            {
              id: '19012642d95140889905850e0b79d549',
              description: { es: 'a. Tiene lugar la Revolución Mexicana.' }
            },
            {
              id: '9706ae4f78624519acbb4b6e95e7366c',
              description: { es: 'b. Hernán Cortés y los españoles toman Tenochtitlán.' }
            },
            {
              id: 'd040f32c47ca4cbab15a90711d28de3f',
              description: { es: 'c. México se independiza de España.' }
            },
            {
              id: '884a3a2b459e44e7b38cbd62fac38bee',
              description: { es: 'd. Llegaron trabajadores migratorios mexicanos a Estados Unidos.' }
            },
            {
              id: '05d75108ee14485ca11ca63fc54b0534',
              description: { es: 'e. El cura Hidalgo convoca al pueblo con “El grito de Dolores”.' }
              }
          ],
        target: [
            {
              id: '5dfb77311b46471aba6a0f0c64ea74fd',
              description: { es: 'Respuesta      1                Respuesta correcta      b. Hernán Cortés y los españoles toman Tenochtitlán.' }
            },
          {
              id: '8088ed6185fc4e8fa4c74061e737ac74',
              description: { es: 'Respuesta      2                Respuesta incorrecta      a. Tiene lugar la Revolución Mexicana.' }
            },
            {
              id: '267f4b27a4214124bcadd2c2cd6d136e',
              description: { es: 'Respuesta      3                Respuesta correcta      c. México se independiza de España.' }
            },
            {
              id: '257977d6879645b4845d4b714d129709',
              description: { es: 'Respuesta      4                Respuesta incorrecta      e. El cura Hidalgo convoca al pueblo con “El grito de Dolores' }
            },
            {
              id: 'd3a14c81d132488e9b34f97cd70bcfda',
              description: { es: 'Respuesta      5                Respuesta incorrecta      d. Llegaron trabajadores migratorios mexicanos a Estados Unidos.' }
            }
          ]
        },
        result: {
            success: false,
            extensions: {
                'http://scorm.com/extensions/usa-data': {
                    iconCollectionQuiz: 'usa',
                    'competenceUsa': '1.2,To identify yourself and others',
                    'analytics': {
                        'Product': 'SB',
                        'Level': 'HS1',
                        'Unit': 'U1',
                        'Activity': '009',
                        'Section': 'D1G',
                        'Modes of Communication': 'Interpretive Reading',
                        'Learning Objectives': 'To identify yourself and others',
                        'Standards': '1.2'
                    },
                    correctResponsesPattern: 'a[.]4[,]b[.]1[,]c[.]3[,]d[.]5[,]e[.]2',
                }
            }
        }
      )
    end

    def question_9_response_incorrect
      @question_9_response_incorrect ||=
        '19012642d95140889905850e0b79d549[.]8088ed6185fc4e8fa4c74061e737ac74[,]' \
        '9706ae4f78624519acbb4b6e95e7366c[.]5dfb77311b46471aba6a0f0c64ea74fd[,]' \
        'd040f32c47ca4cbab15a90711d28de3f[.]267f4b27a4214124bcadd2c2cd6d136e[,]' \
        '884a3a2b459e44e7b38cbd62fac38bee[.]d3a14c81d132488e9b34f97cd70bcfda[,]'\
        '05d75108ee14485ca11ca63fc54b0534[.]257977d6879645b4845d4b714d129709'
    end

    def question_10_drawing
      @question_10_drawing ||= Question.new(
        activity_type: 'drawing',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: { 'es' => 'Dibújate.' },
          interactionType: 'other',
          correctResponsesPattern: []
        },
        result: {
          completion: 'true',
          extensions: {
            Smartbook::ResponseParser::SCORM_EXTENSIONS_KEY => {
              'analytics': {
                'Product': 'SB',
                'Level': 'HS1',
                'Unit': 'U1',
                'Activity': '010',
                'Section': 'D1G',
                'Standards': '1.2'
              }
            }
          }
        }
      )
    end

    def drawing_response_from_file(filename)
      data = File.read(filename)
      "data:image/png;base64,#{Base64.strict_encode64(data)}"
    end

    def question_11_word_search
      @question_11_word_search ||= Question.new(
        activity_type: 'matching',
        definition: {
          type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
          description: {"es":"DEPWEU1S1D2A. Busca y selecciona las palabras o frases.&nbsp;."},
          interactionType: 'matching',
          correctResponsesPattern: [
            'GRACIAS[,]SEÑORA[,]HASTAPRONTO[,]MERCADO[,]TEPRESENTO[,]MUCHOGUSTO[,]BUENOSDÍAS[,]ADIÓS'
          ],
        },
        result: {
          success: false,
          extensions: {
            'http://scorm.com/extensions/usa-data': {
              iconCollectionQuiz: 'usa',
              'competenceUsa': 'a',
              'analytics': {
                'Product': 'DEPW',
                'Level': 'E',
                'Unit': 'U1',
                'Week': 'S1',
                'Day': 'D2A',
                'Activity': '1',
                'World Languages Standards': 'Communication',
                'Skills': 'Interpretive',
                'Standards': '1.2'
              },
              correctResponsesPattern: 'GRACIAS[,]SEÑORA[,]HASTAPRONTO[,]MERCADO[,]TEPRESENTO[,]MUCHOGUSTO[,]BUENOSDÍAS[,]ADIÓS'
            }
          }
        }
      )
    end

    def question_11_response_incorrect
      @question_11_response_incorrect ||=
        'GRACIAS[,][,]HASTAPRONTO[,]MERCADO[,][,][,][,]'
    end
  end

  def submit_interaction(attempt:, interaction:, response:, score: nil, timestamp: nil)
    user_token = XapiUserToken.new(
      attempt_id: attempt.id, user_id: attempt.user_id, state_modifiable: true
    )
    initialized_statement_params = interaction.initialized_submission_data(
      timestamp: 1.minute.ago
    ).merge(actor: { mbox: user_token.mbox })

    answered_statement_params = interaction.answered_submission_data(
      response: response, score: score, timestamp: timestamp
    ).merge(actor: { mbox: user_token.mbox })
    # We submit a statement with the verb 'initialized' one minute ago to force
    # the attempt time_spent to be positive.
    Xapi::StatementWriter.new(
      JSON.parse(initialized_statement_params.to_json, symbolize_names: true)
    ).write
    Xapi::StatementWriter.new(
      JSON.parse(answered_statement_params.to_json, symbolize_names: true)
    ).write
  end

  def submit_instructor_graded_interaction(attempt:, interaction:, response:)
    submit_interaction(
      attempt: attempt,
      interaction: interaction,
      response: response
    )
  end

  def submit_auto_graded_interaction(attempt:, interaction:, response:, score:, timestamp: nil)
    submit_interaction(
      attempt: attempt,
      interaction: interaction,
      response: response,
      score: score,
      timestamp: timestamp
    )
  end
end
