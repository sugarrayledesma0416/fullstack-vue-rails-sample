VHL.CustomAssessments.SpecData = {};

VHL.CustomAssessments.SpecData.newContentObject = function(){
  return {
    language: "sindarin",
    activities: [
      {
        MultipleChoiceContent: {
          activity_type: "multiple_choice",
          items: [
            {
              Exam: {
                foo: "bar",
                question_number: 0,
                rank: 0
              }
            },
            {
              Text: {
                rank: 0,
                sidebar_ref: null,
                header: {
                  node_text: 'Test header'
                },
                body: {
                  node_text: 'Test body'
                }
              }
            },
            {
              Wordbank: {
                rank: 1,
                sidebar_ref: null,
                sorted: 'no',
                body: {
                  node_text: 'word, other word, some other word'
                }
              }
            },
            {
              Item: {
                prompt: "foo",
                question_number: 1,
                points_possible: 11,
                rank: 1,
                choices: [
                  {
                    Choice: {
                      text: {
                        node_text: "choice 1"
                      }
                    }
                  },{
                    Choice: {
                      text: {
                        node_text: "choice 2"
                      }
                    }
                  }
                ]
              },
              question_number: 1,
              rank: 1
            },
            {
              Item: {
                prompt: "bar",
                question_number: 2,
                rank: 2,
                points_possible: 11,
                choices: [
                  {
                    Choice: {
                      text: {
                        node_text: "choice 1"
                      }
                    }
                  },{
                    Choice: {
                      text: {
                        node_text: "choice 2"
                      }
                    }
                  }
                ]
              },
              question_number: 2,
              rank: 2
            }
          ]
        }
      },
      {
        MultipleChoiceSameContent: {
          activity_type: "multiple_choice_same",
          items: [
            {
              Exam: {
                header: {node_text: "DL Header"},
                body: {node_text: "DL Body"},
                man: "asd",
                rank: 0
              }
            },
            {
              Item: {
                prompt: "xyz",
                question_number: 1,
                rank: 3,
                points_possible: 8,
                choices: [
                  {
                    Choice: {
                      text: {
                        node_text: "true"
                      }
                    }
                  },{
                    Choice: {
                      text: {
                        node_text: "false"
                      }
                    }
                  }
                ]
              }
            },
            {
              Item: {
                prompt: "lep",
                question_number: 2,
                rank: 4,
                points_possible: 8,
                choices: [
                  {
                    Choice: {
                      text: {
                        node_text: "true"
                      }
                    }
                  },{
                    Choice: {
                      text: {
                        node_text: "false"
                      }
                    }
                  }
                ]
              }
            }
          ]
        }
      },
      {
        OpenEndedContent: {
          activity_type: "open_ended",
          items: [
            {
              Exam: {foo: "bar", question_number: 0, rank: 0}
            },
            {
              Item: {bar: "baz", question_number: 1, rank: 5}
            },
            {
              Item: {baz: "lur", question_number: 2, rank: 6}
            }
          ]
        }
      },
      {
        FillInTheBlanksContent: {
          activity_type: "fill_in_the_blanks",
          items: [
            {
              Exam: {foo: "bar", question_number: 0, rank: 0}
            },
            {
              Item: {
                prompt: {
                  Prompt: {
                    node: "baz",
                    wols: [
                      {
                        WriteOnLine: {
                          answers: [
                            "This is an answer prompt",
                            "This is another answer prompt"
                          ],
                          rank: 7,
                          points_possible: 42
                        }
                      },
                      {
                        WriteOnLine: {
                          answers: [
                            "This is another answer prompt",
                            "This is yet another answer prompt"
                          ],
                          rank: 7,
                          points_possible: 42
                        }
                      }
                    ]
                  }
                },
                question_number: 1,
                rank: 7
              }
            },
            {
              Item: {
                prompt: {
                  Prompt: {
                    node: "lur",
                    wols: [
                      {
                        WriteOnLine: {
                          answers: [
                            "This is an answer prompt",
                            "This is another answer prompt"
                          ],
                          rank: 8,
                          points_possible: 42
                        }
                      },
                      {
                        WriteOnLine: {
                          answers: [
                            "This is another answer prompt",
                            "This is yet another answer prompt"
                          ],
                          rank: 7,
                          points_possible: 42
                        }
                      }
                    ]
                  }
                },
                question_number: 2,
                rank: 8
              }
            }
          ]
        }
      }
    ]
  };
};

VHL.CustomAssessments.SpecData.newFixtureTemplate = function(mockContentJsonString){
  return  '<div> <div assessment-new-section-menu></div>' +
          '<div editable-assessment content-json=\'' + mockContentJsonString + '\'>' +
            '<div assessment-section class="assessment-section-directive" partial-name="multiple_choice" index="0">' +
              '<h1>Test Content 1</h1>' +
              '<div assessment-question section-index="0" index="1">' +
                '<p>Test Qustion 1</p>' +
              '</div>'+
              '<div assessment-question section-index="0" index="2">' +
                '<p>Test Qustion 2</p>' +
              '</div>'+
            '</div>'+
            '<div assessment-section class="assessment-section-directive" partial-name="multiple_choice_same" index="1">'+
              '<ol class="answers" data-question-type="multiple_choice">'+
                '<div assessment-question section-index="1" index="1">' +
                  '<ul class="answer_choices">' +
                    '<li class="answer-blank">Answer</li>' +
                  '</ul>' +
                '</div>'+
                '<div assessment-question section-index="1" index="2">' +
                  '<ul class="answer_choices">' +
                    '<li class="answer-blank">Answer</li>' +
                  '</ul>' +
                '</div>'+
              '</ol>'+
            '</div>' +
            '<div assessment-section class="assessment-section-directive" partial-name="open_ended" index="2">' +
              '<h1>Test Content 1</h1>' +
              '<div assessment-question section-index="2" index="1">' +
                '<p>Test Qustion 1</p>' +
              '</div>'+
              '<div assessment-question section-index="2" index="2">' +
                '<p>Test Qustion 2</p>' +
              '</div>'+
            '</div>'+
            '<div assessment-section class="assessment-section-directive" partial-name="fill_in_the_blanks" index="3">' +
              '<h1>Test Content 1</h1>' +
              '<div assessment-question section-index="3" index="1">' +
                '<p>Test Qustion 1</p>' +
              '</div>'+
              '<div assessment-question section-index="3" index="2">' +
                '<p>Test Qustion 2</p>' +
              '</div>'+
            '</div>'+
          '</div> </div>';
};

VHL.CustomAssessments.SpecData.setTemplateCache = function($templateCache, readFixturesFn){
  var assessmentTemplate = readFixturesFn('../../../assets/custom_assessments/templates/editable_assessment_template.html');
  var sectionTemplate = readFixturesFn('../../../assets/custom_assessments/templates/assessment_section_template.html');
  var questionTemplate = readFixturesFn('../../../assets/custom_assessments/templates/assessment_section_template.html');
  var controlBarTemplate = readFixturesFn('../../../assets/custom_assessments/templates/control_bar_template.html');
  var controlButtonTemplate = readFixturesFn('../../../assets/custom_assessments/templates/control_button_template.html');
  var editableAttrTemplate = readFixturesFn('../../../assets/custom_assessments/templates/editable_attribute_template.html');
  var newSectionMenuTemplate = readFixturesFn('../../../assets/custom_assessments/templates/assessment_new_section_template.html');
  var sectionReferencesTemplate = readFixturesFn('../../../assets/custom_assessments/templates/section_references_template.html');
  var referenceEditorTemplate = readFixturesFn('../../../assets/custom_assessments/templates/reference_editor_template.html');
  var wordbankEditorTemplate = readFixturesFn('../../../assets/custom_assessments/templates/wordbank_editor_template.html');
  $templateCache.put('/assets/custom_assessments/templates/editable_assessment_template.html', assessmentTemplate);
  $templateCache.put('/assets/custom_assessments/templates/assessment_section_template.html', sectionTemplate);
  $templateCache.put('/assets/custom_assessments/templates/assessment_question_template.html', questionTemplate);
  $templateCache.put('/assets/custom_assessments/templates/control_bar_template.html', controlBarTemplate);
  $templateCache.put('/assets/custom_assessments/templates/control_button_template.html', controlButtonTemplate);
  $templateCache.put('/assets/custom_assessments/templates/editable_attribute_template.html', editableAttrTemplate);
  $templateCache.put('/assets/custom_assessments/templates/assessment_new_section_template.html', newSectionMenuTemplate);
  $templateCache.put('/assets/custom_assessments/templates/section_references_template.html', sectionReferencesTemplate);
  $templateCache.put('/assets/custom_assessments/templates/reference_editor_template.html', referenceEditorTemplate);
  $templateCache.put('/assets/custom_assessments/templates/wordbank_editor_template.html', wordbankEditorTemplate);
};
