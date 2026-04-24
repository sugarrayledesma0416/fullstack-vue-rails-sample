import { shallowMount } from '@vue/test-utils';
/* eslint-disable-next-line max-len */
import ColumnTooltip from 'features/gradebook/standards/student_detail_report/components/ColumnTooltip';

function getWrapper(options) {
  const props = {
    points: [{
      series: { name: options['name'] },
      y: options['y'],
    }],
    lowGradeThreshold: 60,
  };

  if (options['midBook']) {
    props['hasMidBookAssessment'] = true;
  }

  if (options['endBook']) {
    props['hasEndBookAssessment'] = true;
  }

  return shallowMount(ColumnTooltip, { props });
}

describe(
  'ColumnTooltip',
  () => {
    it('rounds score to nearest integer', () => {
      [89.5, 90.0, 90.4].forEach((score) => {
        const wrapper = getWrapper({ name: 'Mid-Unit', y: score });
        expect(wrapper.find('.test-Mid-Unit-score').text()).toBe('90%');
      });
    });

    describe('Mid-Unit', () => {
      describe('when there is no submission', () => {
        it('shows div with score as "--"', () => {
          // There is a point for End-of-Unit, but not for Mid-Unit.
          const wrapper = getWrapper({ name: 'End-of-Unit', y: 50 });
          expect(wrapper.find('.test-Mid-Unit-score').text()).toBe('--');
        });
      });

      describe('when there is a submission', () => {
        describe('when score is below threshold', () => {
          it('shows score with below-threshold class', () => {
            const wrapper = getWrapper({ name: 'Mid-Unit', y: 50 });
            expect(wrapper.find('.test-Mid-Unit-score.below-threshold').text()).toBe('50%');
          });
        });

        describe('when score is at threshold', () => {
          let wrapper;

          beforeEach(() => {
            wrapper = getWrapper({ name: 'Mid-Unit', y: 60 });
          });

          it('shows score', () => {
            expect(wrapper.find('.test-Mid-Unit-score').text()).toBe('60%');
          });

          it('does not add below-threshold class', () => {
            expect(wrapper.find('.test-Mid-Unit-score.below-threshold').exists()).toBe(false);
          });
        });

        describe('when score is above threshold', () => {
          let wrapper;
          beforeEach(() => {
            wrapper = getWrapper({ name: 'Mid-Unit', y: 61 });
          });

          it('shows score', () => {
            expect(wrapper.find('.test-Mid-Unit-score').text()).toBe('61%');
          });

          it('does not add below-threshold class', () => {
            expect(wrapper.find('.test-Mid-Unit-score.below-threshold').exists()).toBe(false);
          });
        });
      });
    });

    describe('End-of-Unit', () => {
      describe('when there is no submission', () => {
        it('shows div with score as "--"', () => {
          // There is a point for Mid-Unit, but not for End-of-Unit.
          const wrapper = getWrapper({ name: 'Mid-Unit', y: 50 });
          expect(wrapper.find('.test-End-of-Unit-score').text()).toBe('--');
        });
      });

      describe('when there is a submission', () => {
        describe('when score is below threshold', () => {
          it('shows score with below-threshold class', () => {
            const wrapper = getWrapper({ name: 'End-of-Unit', y: 50 });
            expect(wrapper.find('.test-End-of-Unit-score.below-threshold').text()).toBe('50%');
          });
        });

        describe('when score is at threshold', () => {
          let wrapper;

          beforeEach(() => {
            wrapper = getWrapper({ name: 'End-of-Unit', y: 60 });
          });

          it('shows score', () => {
            expect(wrapper.find('.test-End-of-Unit-score').text()).toBe('60%');
          });

          it('does not add below-threshold class', () => {
            expect(wrapper.find('.test-End-of-Unit-score.below-threshold').exists()).toBe(false);
          });
        });

        describe('when score is above threshold', () => {
          let wrapper;

          beforeEach(() => {
            wrapper = getWrapper({ name: 'End-of-Unit', y: 61 });
          });

          it('shows score', () => {
            expect(wrapper.find('.test-End-of-Unit-score').text()).toBe('61%');
          });

          it('does not add below-threshold class', () => {
            expect(wrapper.find('.test-End-of-Unit-score.below-threshold').exists()).toBe(false);
          });
        });
      });
    });

    describe('Mid-Book', () => {
      describe('when unit has no Mid-Book assessment', () => {
        it('does not show Mid-Book div', () => {
          const wrapper = getWrapper({ name: 'Mid-Book', y: 50 });
          expect(wrapper.find('.test-Mid-Book-score').exists()).toBe(false);
        });
      });

      describe('when unit has Mid-Book assessment', () => {
        describe('when there is no submission', () => {
          it('shows div with score as --', () => {
            const wrapper = getWrapper({ name: 'Mid-Unit', y: 50, midBook: true });
            expect(wrapper.find('.test-Mid-Book-score').text()).toBe('--');
          });
        });

        describe('when there is a submission', () => {
          describe('when score is below threshold', () => {
            it('shows score with below-threshold class', () => {
              const wrapper = getWrapper({ name: 'Mid-Book', y: 50, midBook: true });
              expect(wrapper.find('.test-Mid-Book-score.below-threshold').text()).toBe('50%');
            });
          });

          describe('when score is at threshold', () => {
            let wrapper;

            beforeEach(() => {
              wrapper = getWrapper({ name: 'Mid-Book', y: 60, midBook: true });
            });

            it('shows score', () => {
              expect(wrapper.find('.test-Mid-Book-score').text()).toBe('60%');
            });

            it('does not add below-threshold class', () => {
              expect(wrapper.find('.test-Mid-Book-score.below-threshold').exists()).toBe(false);
            });
          });

          describe('when score is above threshold', () => {
            let wrapper;

            beforeEach(() => {
              wrapper = getWrapper({ name: 'Mid-Book', y: 61, midBook: true });
            });

            it('shows score', () => {
              expect(wrapper.find('.test-Mid-Book-score').text()).toBe('61%');
            });

            it('does not add below-threshold class', () => {
              expect(wrapper.find('.test-Mid-Book-score.below-threshold').exists()).toBe(false);
            });
          });
        });
      });
    });

    describe('End-of-Book', () => {
      describe('when unit has no End-of-Book assessment', () => {
        it('does not show End-of-Book div', () => {
          const wrapper = getWrapper({ name: 'End-of-Book', y: 50 });
          expect(wrapper.find('.test-End-of-Book-score').exists()).toBe(false);
        });
      });

      describe('when unit has End-of-Book assessment', () => {
        describe('when there is no submission', () => {
          it('shows div with score as --', () => {
            const wrapper = getWrapper({ name: 'End-of-Unit', y: 50, endBook: true });
            expect(wrapper.find('.test-End-of-Book-score').text()).toBe('--');
          });
        });

        describe('when there is a submission', () => {
          describe('when score is below threshold', () => {
            it('shows score with below-threshold class', () => {
              const wrapper = getWrapper({ name: 'End-of-Book', y: 50, endBook: true });
              expect(wrapper.find('.test-End-of-Book-score.below-threshold').text()).toBe('50%');
            });
          });

          describe('when score is at threshold', () => {
            let wrapper;

            beforeEach(() => {
              wrapper = getWrapper({ name: 'End-of-Book', y: 60, endBook: true });
            });

            it('shows score', () => {
              expect(wrapper.find('.test-End-of-Book-score').text()).toBe('60%');
            });

            it('does not add below-threshold class', () => {
              expect(wrapper.find('.test-End-of-Book-score.below-threshold').exists()).toBe(false);
            });
          });

          describe('when score is above threshold', () => {
            let wrapper;

            beforeEach(() => {
              wrapper = getWrapper({ name: 'End-of-Book', y: 61, endBook: true });
            });

            it('shows score', () => {
              expect(wrapper.find('.test-End-of-Book-score').text()).toBe('61%');
            });

            it('does not add below-threshold class', () => {
              expect(wrapper.find('.test-End-of-Book-score.below-threshold').exists()).toBe(false);
            });
          });
        });
      });
    });
  }
);
