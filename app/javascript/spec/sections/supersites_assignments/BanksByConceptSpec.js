import { mount } from '@vue/test-utils';
import BanksByConcept from 'sections/supersites_assignments/BanksByConcept';

function getWrapper(propsData) {
  return mount(BanksByConcept, {
    propsData: propsData
  });
}

describe('BanksByConcept', () => {
  it('creates a div for each assignment group', () => {
    const assignmentDay = {
      assignment_groups: [
        { assignment_banks: [{}] },
        { assignment_banks: [{}] }
      ]
    };
    const wrapper = getWrapper({ assignmentDay });

    expect(wrapper.findAll('.test-assignment-group').length).toBe(2);
  });

  describe('expanded state', () => {
    describe('when the day is expanded', () => {
      it('is shown', () => {
        const assignmentDay = {
          assignment_groups: [
            { assignment_banks: [{}] }
          ],
          expanded: true
        };
        const wrapper = getWrapper({ assignmentDay });

        expect(wrapper.find('.test-assignment-group').isVisible()).toBe(true);
      });
    });

    describe('when the day is not expanded', () => {
      it('is hidden', () => {
        const assignmentDay = {
          assignment_groups: [
            { assignment_banks: [{}] }
          ],
          expanded: false
        };
        const wrapper = getWrapper({ assignmentDay });

        expect(wrapper.find('.test-assignment-group').isVisible()).toBe(false);
      });
    });
  });

  describe('assignment banks', () => {
    it('creates a list item for each assignment bank in an assignment group', () => {
      const assignmentDay = {
        assignment_groups: [
          { assignment_banks: [{}, {}] }
        ],
        expanded: true
      };
      const wrapper = getWrapper({ assignmentDay });

      expect(wrapper.findAll('.test-assignment-bank').length).toBe(2);
    });

    describe('lesson-link elm', () => {
      describe('when the bank has a background color', () => {
        it('applies expected style', () => {
          const assignmentDay = {
            assignment_groups: [
              {
                assignment_banks: [
                  { background_color: '#dddddd' }
                ]
              }
            ],
            expanded: false
          };
          const wrapper = getWrapper({ assignmentDay });
          const lessonLinkElm = wrapper.find('.test-lesson-link').element;

          expect(lessonLinkElm.style.getPropertyValue('border-left')).toBe(
            '0.25rem solid #dddddd'
          );
        });
      });

      describe('when the bank has no background color', () => {
        it('applies no style', () => {
          const assignmentDay = {
            assignment_groups: [
              { assignment_banks: [{}] }
            ],
            expanded: false
          };
          const wrapper = getWrapper({ assignmentDay });
          const lessonLinkElm = wrapper.find('.test-lesson-link').element;

          expect(lessonLinkElm.style.getPropertyValue('border-left')).toBe('');
        });
      });

      describe('lesson/concept text', () => {
        it('shows expected text, parsed as HTML', () => {
          const assignmentDay = {
            assignment_groups: [
              {
                assignment_banks: [
                  { lesson_label: 'foo', concept_name: '<em>bar</em>' }
                ]
              }
            ],
            expanded: false
          };
          const wrapper = getWrapper({ assignmentDay });
          const lessonLinkSpan = wrapper.find('.test-lesson-link');

          expect(lessonLinkSpan.text()).toBe('foo | bar');
        });
      });
    });

    describe('assessment availability message', () => {
      describe('when the bank has no assessment_id', () => {
        it('is hidden', () => {
          const assignmentDay = {
            assignment_groups: [
              { assignment_banks: [{}] }
            ],
            expanded: true
          };
          const wrapper = getWrapper({ assignmentDay });
          const availabilityMsgDiv = wrapper.find('.test-availability-message');

          expect(availabilityMsgDiv.isVisible()).toBe(false);
        });
      });

      describe('when the bank has an assessment_id', () => {
        describe('when the assignment group can be started', () => {
          it('is hidden', () => {
            const assignmentDay = {
              assignment_groups: [
                {
                  assignment_banks: [
                    { assessment_id: 1 }
                  ],
                  can_be_started: true
                }
              ],
              expanded: true
            };
            const wrapper = getWrapper({ assignmentDay });
            const availabilityMsgDiv = wrapper.find('.test-availability-message');

            expect(availabilityMsgDiv.isVisible()).toBe(false);
          });
        });

        describe('when the assignment group cannot be started', () => {
          it('is visible', () => {
            const assignmentDay = {
              assignment_groups: [
                {
                  assignment_banks: [
                    { assessment_id: 1, availability_message: 'This is not available yet' }
                  ],
                  can_be_started: false
                }
              ],
              expanded: true
            };
            const wrapper = getWrapper({ assignmentDay });
            const availabilityMsgDiv = wrapper.find('.test-availability-message');

            expect(availabilityMsgDiv.isVisible()).toBe(true);
            expect(availabilityMsgDiv.text()).toBe('This is not available yet');
          });
        });
      });
    });

    describe('activity count', () => {
      describe('when activity_count_text is present', () => {
        it('is visible, with expected text', () => {
          const assignmentDay = {
            assignment_groups: [
              {
                assignment_banks: [
                  { activity_count_text: 'foo' }
                ]
              }
            ],
            expanded: true
          };
          const wrapper = getWrapper({ assignmentDay });
          const activityCountSpan = wrapper.find('.test-activity-count');

          expect(activityCountSpan.isVisible()).toBe(true);
          expect(activityCountSpan.text()).toBe('foo');
        });
      });

      describe('when activity_count_text is absent', () => {
        it('is hidden', () => {
          const assignmentDay = {
            assignment_groups: [
              { assignment_banks: [{}] }
            ],
            expanded: true
          };
          const wrapper = getWrapper({ assignmentDay });
          const activityCountSpan = wrapper.find('.test-activity-count');

          expect(activityCountSpan.isVisible()).toBe(false);
        });
      });
    });
  });

  describe('activity start', () => {
    describe('estimated time', () => {
      describe('when day is not set to show estimated times', () => {
        it('is hidden', () => {
          const assignmentDay = {
            assignment_groups: [
              { assignment_banks: [{}] }
            ],
            course_show_estimated_times: false,
            expanded: true
          };
          const wrapper = getWrapper({ assignmentDay });
          const estimatedTimeDiv = wrapper.find('.test-estimated-time');

          expect(estimatedTimeDiv.isVisible()).toBe(false);
        });
      });

      describe('when day is set to show estimated times', () => {
        it('is visible', () => {
          const assignmentDay = {
            assignment_groups: [
              { assignment_banks: [{}] }
            ],
            course_show_estimated_times: true,
            expanded: true
          };
          const wrapper = getWrapper({ assignmentDay });
          const estimatedTimeDiv = wrapper.find('.test-estimated-time');

          expect(estimatedTimeDiv.isVisible()).toBe(true);
        });

        describe('not-released text', () => {
          describe('when assignment group can be started', () => {
            it('is hidden', () => {
              const assignmentDay = {
                assignment_groups: [
                  {
                    assignment_banks: [{}],
                    can_be_started: true
                  }
                ],
                course_show_estimated_times: true,
                expanded: false
              };
              const wrapper = getWrapper({ assignmentDay });
              const notReleasedSpan = wrapper.find('.test-not-released');

              expect(notReleasedSpan.isVisible()).toBe(false);
            });
          });

          describe('when assignment group cannot be started', () => {
            it('is visible', () => {
              const assignmentDay = {
                assignment_groups: [
                  {
                    assignment_banks: [{}],
                    can_be_started: false
                  }
                ],
                course_show_estimated_times: true,
                expanded: false
              };
              const wrapper = getWrapper({ assignmentDay });
              const notReleasedSpan = wrapper.find('.test-not-released');

              expect(notReleasedSpan.text()).toBe('Not Released');
            });
          });
        });

        describe('due time', () => {
          it('is present', () => {
            const assignmentDay = {
              assignment_groups: [
                {
                  assignment_banks: [{}],
                  due_time: 'Due 11:59 PM'
                }
              ],
              course_show_estimated_times: true,
              expanded: false
            };
            const wrapper = getWrapper({ assignmentDay });
            const dueTimeDiv = wrapper.find('.test-due-time');

            expect(dueTimeDiv.text()).toBe('Due 11:59 PM');
          });
        });
      });

      describe('start button', () => {
        describe('when assignment group cannot be started', () => {
          it('is hidden', () => {
            const assignmentDay = {
              assignment_groups: [
                {
                  assignment_banks: [{}],
                  can_be_started: false
                }
              ],
              expanded: true
            };
            const wrapper = getWrapper({ assignmentDay });
            const startButton = wrapper.find('.test-start-button');

            expect(startButton.isVisible()).toBe(false);
          });
        });

        describe('when assignment group can be started', () => {
          const assignmentDay = {
            assignment_groups: [
              {
                assignment_banks: [{}],
                can_be_started: true,
                url: 'http://example.com/url_for_activities'
              }
            ],
            expanded: true
          };

          const wrapper = getWrapper({ assignmentDay });
          const startButton = wrapper.find('.test-start-button');

          it('is visible with expected text', () => {
            expect(startButton.isVisible()).toBe(true);
            expect(startButton.text()).toBe('start');
          });

          describe('when clicked', () => {
            it('navigates to the expected URL', () => {
              /**
               * Mock location.assign.
               *
               * Jest depends on jsdom, which does not support navigation.
               * As a result, we have to resort to kludges to test navigation.
               * This is the simplest kludge I could find.
               */
              delete window.location;
              window.location = new URL('http://example.com');
              window.location.assign = jest.fn();

              startButton.trigger('click');
              expect(window.location.assign).toHaveBeenCalledWith(
                'http://example.com/url_for_activities'
              );
            });
          });
        });
      });
    });
  });
});
