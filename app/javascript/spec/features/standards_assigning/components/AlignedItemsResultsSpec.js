import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import AlignedItemsResults from 'features/standards_assigning/components/AlignedItemsResults';
import {
  matchingContentCount,
  handleFilterChange,
  updateMatchingContentCount,
} from 'features/standards_assigning/models/filters_helper';
import {
  alignedItemsJson,
  standardsInfoJson,
  tocJson,
} from './../standards_assigning_fixture.js';

jest.mock('features/standards_assigning/models/filters_helper', () => ({
  matchingContentCount: (15),
  updateMatchingContentCount: jest.fn(),
  handleFilterChange: jest.fn(),
}));

VHL = {
  ContentLibrary: {},
  Common: {},
  Assessments: {},
};

VHL.Assessments = {
  update_assessment: () => {},
};

VHL.ContentLibrary = {
  assignment_wizard: () => {},
};

VHL.Common = {
  unassignable_dialog: () => {},
};

const props = {
  programTocType: 'Unit',
  contentLibrary: VHL.ContentLibrary,
  dueDateLinkBaseUrl: 'due-date-link-base-url/',
  instructorSearchStandardsByAssetPath: 'path/for/search',
  instructorStandardsAssigningPath: 'path/to/assign',
  vhlCommon: VHL.Common,
};

function getWrapper() {
  return shallowMount(
    AlignedItemsResults,
    {
      global: {
        plugins: [
          createTestingPinia(
            {
              stubActions: false,
              initialState: {
                store: {
                  tocItems: [],
                  tocUnitNames: {},
                  tocConceptNames: {},
                  alignedItems: [],
                  selectedTocItems: [],
                  standardsInfo: JSON.parse(standardsInfoJson),
                },
              },
            }
          ),
        ],
        provide: {
          displayEmptyResults: { value: false },
          individualAssigningUrl: { value: 'individually/assigning/path' },
          isSearchLoading: { value: false },
          vhlAssessments: VHL.Assessments,
        },
        stubs: {
          ButtonSecondary: {
            template: '<button class="button-secondary"><slot /></button>',
          },
          ButtonDefault: {
            template: '<button class="button-default"><slot /></button>',
          },
        },
      },
      props,
    }
  );
}

const alignedItems = JSON.parse(alignedItemsJson);

describe(
  'AlignedItemsResults',
  () => {
    let wrapper;
    beforeEach(
      async () => {
        wrapper = getWrapper();
        wrapper.vm.store.updateAlignedItems(alignedItemsJson);
        wrapper.vm.store.initToc(tocJson);
        wrapper.vm.store.setDefaultSelectedTocItems();
        await wrapper.vm.$nextTick();
      }
    );

    describe('when the unit filter is changed', ()=> {
      wrapper = getWrapper();
      const assignedItems = wrapper.findAll('.c-assigned-item');
      const unassignedItems = wrapper.findAll('.c-unassigned-item');
      const activityItems = wrapper.findAll('.c-activity-item');
      const assessmentItems = wrapper.findAll('.c-assessment-item');
      const ereaderItems = wrapper.findAll('.c-ereader-item');
      const firstUnitId = Object.keys(alignedItems)[0];
      const secondUnitId = Object.keys(alignedItems)[1];
      wrapper.vm.store.setSelectedContentType('Activity');
      wrapper.vm.store.setSelectedStatus('Assigned');

      it('only shows specific items according to the selected filter', async () => {
        wrapper.vm.store.selectedTocItems = firstUnitId; // Select the first unit.
        await wrapper.vm.$nextTick();

        expect(assignedItems).toBeVisible;
        expect(activityItems).toBeVisible;
        expect(unassignedItems).toBeHidden;
        expect(assessmentItems).toBeHidden;
        expect(ereaderItems).toBeHidden;
        expect(wrapper.find(`.test-unit-${firstUnitId}`).isVisible()).toBe(true);
        expect(wrapper.find(`.test-unit-${secondUnitId}`).exists()).toBe(false);
      });

      it('keeps the content type filter and status filter after change the unit', async () => {
        wrapper.vm.store.selectedTocItems = secondUnitId; // Select the second unit.
        await wrapper.vm.$nextTick();

        expect(assignedItems).toBeVisible;
        expect(activityItems).toBeVisible;
        expect(unassignedItems).toBeHidden;
        expect(assessmentItems).toBeHidden;
        expect(ereaderItems).toBeHidden;
        expect(wrapper.find(`.test-unit-${secondUnitId}`).isVisible()).toBe(true);
        expect(wrapper.find(`.test-unit-${firstUnitId}`).exists()).toBe(false);
      });
    });

    it('calls the handleFilterChange and updateMatchingContentCount functions on update', () => {
      expect(updateMatchingContentCount).toHaveBeenCalledWith(matchingContentCount);
      expect(handleFilterChange).toHaveBeenCalledWith(
        wrapper.vm.store.selectedStatus, wrapper.vm.store.selectedContentType
      );
    });

    it('Displays a count of aligned standards per aligned item', () => {
      const count = wrapper.find('.test-standard-count-716882').text();
      expect(count).toBe('3 standards');
    });
    it('Displays a count of matching content items when there are aligned items', () => {
      const matchingCount = wrapper.find('.test-matching-content-count').text();
      expect(matchingCount).toBe(`Matching Content (${matchingContentCount})`);
    });
    it('Does not display a count of matching content items when isSearchLoading is true',
      async () => {
        wrapper.vm.isSearchLoading.value = true;
        wrapper.vm.store.updateAlignedItems(alignedItemsJson);
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-matching-content-count').element).not.toBeVisible();
      }
    );
    it('Does not display a count of matching content items when there are no aligned items',
      async () => {
        wrapper.vm.store.updateAlignedItems('[]');
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-matching-content-count').element).not.toBeVisible();
      }
    );

    /* eslint-enable guard-for-in */
    it('Displays an assign button when the activity is assignable and is not TE', () => {
      /* eslint-disable guard-for-in */
      Object.keys(alignedItems).forEach((unit) => {
        for (const lesson in alignedItems[unit]) {
          for (const concept in alignedItems[unit][lesson]) {
            for (const activity in alignedItems[unit][lesson][concept]) {
              const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
              const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];
              const assignable = alignedItems[unit][lesson][concept][activity]['isAssignable'];

              if (assignable) {
                expect(
                  wrapper.find(`.test-assign-content-${activityId}`).wrapperElement
                ).not.toBeDisabled();
              } else {
                if (activityType === 'EReaderItem') {
                  expect(
                    wrapper.find(`.test-assign-content-${activityId}`).exists()
                  ).toBeFalsy();
                } else {
                  expect(
                    wrapper.find(`.test-assign-content-${activityId}`).wrapperElement
                  ).toBeDisabled();
                }
              }
            }
          }
        }
      });
      /* eslint-enable guard-for-in */
    });
    it(
      'shows a not assignable link on hover only when content is not assignable and is not TE',
      () => {
        /* eslint-disable guard-for-in */
        for (const unit of Object.keys(alignedItems)) {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                const assignable = alignedItems[unit][lesson][concept][activity]['isAssignable'];
                const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];
                let assignButton = null;
                if (activityType !== 'EReaderItem') {
                  assignButton = wrapper.find(`.test-assign-content-${activityId}`);

                  assignButton.element.dispatchEvent(new Event('mouseover'));
                  if (!assignable) {
                    expect(
                      wrapper.find(`.test-not-assignable-link-${activityId}`).exists()
                    ).toBeTruthy();
                    expect(
                      wrapper.find(`.test-not-assignable-link-${activityId}`).exists()
                    ).toBeTruthy();
                  } else {
                    expect(
                      wrapper.find(`.test-not-assignable-link-${activityId}`).exists()
                    ).toBeFalsy();
                  }
                } else {
                  expect(
                    wrapper.find(`.test-not-assignable-link-${activityId}`).exists()
                  ).toBeFalsy();
                }
              }
            }
          }
        }
        /* eslint-enable guard-for-in */
      }
    );
    it(
      'shows a Non-assignable button for TE items', () => {
        /* eslint-disable guard-for-in */
        for (const unit of Object.keys(alignedItems)) {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];

                expect(
                  wrapper.find(`.test-te-not-assignable-link-${activityId}`).exists()
                ).toBe(activityType === 'EReaderItem');
              }
            }
          }
        }
        /* eslint-enable guard-for-in */
      }
    );
    it(
      'shows the TE link for TE items', () => {
        /* eslint-disable guard-for-in */
        for (const unit of Object.keys(alignedItems)) {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];

                expect(
                  wrapper.find(`.test-te-url-${activityId}`).exists()
                ).toBe(activityType === 'EReaderItem');
              }
            }
          }
        }
        /* eslint-enable guard-for-in */
      }
    );
    it(
      'shows the TE descriptor for TE items', () => {
        /* eslint-disable guard-for-in */
        for (const unit of Object.keys(alignedItems)) {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];

                expect(
                  wrapper.find(`.test-te-descriptor-${activityId}`).exists()
                ).toBe(activityType === 'EReaderItem');
              }
            }
          }
        }
        /* eslint-enable guard-for-in */
      }
    );
    describe('When the Non-Assignable button/link is clicked', ()=> {
      let spy;
      beforeEach(
        async () => {
          spy = jest.spyOn(VHL.Common, 'unassignable_dialog');
          wrapper = getWrapper();
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          wrapper.vm.store.initToc(tocJson);
          wrapper.vm.store.setDefaultSelectedTocItems();
          await wrapper.vm.$nextTick();
        }
      );
      it('shows a non assignable dialog', async () => {
        /* eslint-disable guard-for-in */
        for (const unit of Object.keys(alignedItems)) {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                const activityType = alignedItems[unit][lesson][concept][activity]['referenceType'];
                const assignable = alignedItems[unit][lesson][concept][activity]['isAssignable'];

                if (activityType === 'EReaderItem') {
                  await wrapper.find(`.test-te-not-assignable-link-${activityId}`).element.click();
                  await wrapper.vm.$nextTick();
                  expect(spy).toHaveBeenCalledTimes(1);
                } else {
                  if (!assignable) {
                    await wrapper.find(`.test-not-assignable-link-${activityId}`).element.click();
                    await wrapper.vm.$nextTick();
                    expect(spy).toHaveBeenCalledTimes(1);
                  }
                }
              }
            }
          }
        }
        /* eslint-enable guard-for-in */
      });
    });
    describe('When the assign button is clicked', () =>{
      let spy;
      beforeEach(
        () => {
          spy = jest.spyOn(VHL.ContentLibrary, 'assignment_wizard');
          wrapper = getWrapper();
          wrapper.vm.store.initToc(tocJson);
          wrapper.vm.store.setDefaultSelectedTocItems();
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
        }
      );
      it('displays the assign wizard', async () => {
        wrapper.findAll('[class*="test-assign-content-"]')[0].element.click();
        await wrapper.vm.$nextTick();
        expect(spy).toHaveBeenCalledTimes(1);
      });
    });
    it('displays the due date when an assignment exists', () => {
      /* eslint-disable guard-for-in */
      Object.keys(alignedItems).forEach((unit) => {
        for (const lesson in alignedItems[unit]) {
          for (const concept in alignedItems[unit][lesson]) {
            for (const activity in alignedItems[unit][lesson][concept]) {
              const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
              /* eslint-disable-next-line max-len*/
              const hasAssignments = alignedItems[unit][lesson][concept][activity]['assignmentsDueDate'];

              if (hasAssignments) {
                expect(
                  wrapper.find(`.test-assign-due-date-${activityId}`).exists()
                ).toBeTruthy();
              } else {
                expect(
                  wrapper.find(`.test-assign-due-date-${activityId}`).exists()
                ).toBeFalsy();
              }
            }
          }
        }
      });
      /* eslint-enable guard-for-in */
    });
    it('displays the availability if an assessment has been assigned', () => {
      /* eslint-disable guard-for-in */
      Object.keys(alignedItems).forEach((unit) => {
        for (const lesson in alignedItems[unit]) {
          for (const concept in alignedItems[unit][lesson]) {
            for (const activity in alignedItems[unit][lesson][concept]) {
              const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
              /* eslint-disable-next-line max-len*/
              const referenceType = alignedItems[unit][lesson][concept][activity]['referenceType'];
              /* eslint-disable-next-line max-len*/
              const assignmentsDueDate = alignedItems[unit][lesson][concept][activity]['assignmentsDueDate'];

              if (referenceType == 'AssessmentItem' && assignmentsDueDate) {
                expect(
                  wrapper.find(`.test-availability-${activityId}`).exists()
                ).toBeTruthy();
              } else {
                expect(
                  wrapper.find(`.test-availability-${activityId}`).exists()
                ).toBeFalsy();
              }
            }
          }
        }
      });
      /* eslint-enable guard-for-in */
    });
    it(
      'changes the availability status for an assigned assessment when Release is clicked',
      async () => {
        // Assessment id from fixture is 716486
        const spy = jest.spyOn(VHL.Assessments, 'update_assessment');
        const activityId = 716486;
        wrapper.find(`.test-expand-content-${activityId}`).element.click();
        await wrapper.vm.$nextTick();
        wrapper.find(`#release_hide_link_${activityId}`).element.click();
        expect(spy).toHaveBeenCalledTimes(1);
      }
    );
    it(
      'displays the individual assigning link when an assignment has been individually assigned',
      () => {
        /* eslint-disable guard-for-in */
        Object.keys(alignedItems).forEach((unit) => {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              for (const activity in alignedItems[unit][lesson][concept]) {
                const activityId = alignedItems[unit][lesson][concept][activity]['activityId'];
                /* eslint-disable-next-line max-len*/
                const isIndividuallyAssigned = alignedItems[unit][lesson][concept][activity]['isIndividuallyAssigned'];

                if (isIndividuallyAssigned) {
                  expect(
                    wrapper.find(`.test-individually-assigned-${activityId}`).exists()
                  ).toBeTruthy();
                } else {
                  expect(
                    wrapper.find(`.test-individually-assigned-${activityId}`).exists()
                  ).toBeFalsy();
                }
              }
            }
          }
        });
        /* eslint-enable guard-for-in */
      });

    describe('With a unit based program', () => {
      beforeEach(
        async () => {
          wrapper = getWrapper();
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          wrapper.vm.store.initToc(tocJson);
          wrapper.vm.store.setDefaultSelectedTocItems();
          await wrapper.vm.$nextTick();
        }
      );
      it('explains an empty result to the user when isSearchLoading is false' +
         'and displayEmptyResults is true',
      async () => {
        wrapper.vm.store.updateAlignedItems('[]');
        wrapper.vm.displayEmptyResults.value = true;
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-empty-aligned-items').element).toBeVisible();
        expect(
          wrapper.find('.test-empty-aligned-items').text()
        ).toEqual('Your search did not produce results. Please try again.');
      });
      it('Does not explain an empty result to the user when isSearchLoading is true',
        async () => {
          wrapper.vm.store.updateAlignedItems('[]');
          wrapper.vm.displayEmptyResults.value = true;
          wrapper.vm.isSearchLoading.value = true;
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-empty-aligned-items').element).not.toBeVisible();
        }
      );
      it('Does not explain an empty result to the user when displayEmptyResults is false',
        async () => {
          wrapper.vm.store.updateAlignedItems('[]');
          wrapper.vm.displayEmptyResults.value = false;
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-empty-aligned-items').element).not.toBeVisible();
        }
      );
      it('displays Unit groups', () => {
        /* eslint-disable guard-for-in */
        Object.keys(alignedItems).forEach((unit) => {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              const unitText = wrapper.vm.store.tocUnitNames[unit];
              const conceptText = wrapper.vm.store.tocConceptNames[concept];
              expect(
                wrapper.find(`.test-results-section-label-${lesson}-${concept}`).text()
              ).toEqual(`${unitText}: ${conceptText}`);
            }
          }
        });
        /* eslint-enable guard-for-in */
      });
    });
    describe('With a lesson based program', () => {
      beforeEach(
        async () => {
          props.programTocType = 'Lesson';
          wrapper = getWrapper();
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          wrapper.vm.store.initToc(tocJson);
          wrapper.vm.store.setDefaultSelectedTocItems();
          await wrapper.vm.$nextTick();
        }
      );

      it('displays Lesson groups', () => {
        /* eslint-disable guard-for-in */
        Object.keys(alignedItems).forEach((unit) => {
          for (const lesson in alignedItems[unit]) {
            for (const concept in alignedItems[unit][lesson]) {
              const conceptText = wrapper.vm.store.tocConceptNames[concept];
              expect(
                wrapper.find(`.test-results-section-label-${lesson}-${concept}`).text()
              ).toEqual(`${lesson}: ${conceptText}`);
            }
          }
        });
        /* eslint-enable guard-for-in */
      });
    });
    describe('Unit visibility', () => {
      const firstUnitId = Object.keys(alignedItems)[0];
      const secondUnitId = Object.keys(alignedItems)[1];

      beforeEach(
        () => {
          wrapper = getWrapper();
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          // Select the first unit only.
          wrapper.vm.store.selectedTocItems = Object.keys(alignedItems)[0];
        }
      );
      it('Displays selected units', () => {
        expect(wrapper.find(`.test-unit-${firstUnitId}`).isVisible()).toBe(true);
      });
      it('Does not display unselected units', () => {
        expect(wrapper.find(`.test-unit-${secondUnitId}`).exists()).toBe(false);
      });
      it('Displays a message when no units are selected and isSearchLoading is false' +
         'and displayEmptyResults is false and alignedItems.length > 1', async () => {
        wrapper.vm.store.updateAlignedItems(alignedItemsJson);
        wrapper.vm.store.selectedTocItems = [];
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-no-unit-lesson-selected-msg').element).toBeVisible();
      });
      it('Does not Display a message when no units are selected and isSearchLoading is true',
        async () => {
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          wrapper.vm.store.selectedTocItems = [];
          wrapper.vm.isSearchLoading.value = true;
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-no-unit-lesson-selected-msg').element).not.toBeVisible();
        }
      );
      it('Does not Display a message when no units are selected and displayEmptyResults is true',
        async () => {
          wrapper.vm.store.updateAlignedItems(alignedItemsJson);
          wrapper.vm.store.selectedTocItems = [];
          wrapper.vm.displayEmptyResults.value = true;
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-no-unit-lesson-selected-msg').element).not.toBeVisible();
        }
      );
      it('Does not Display a message when no units are selected and there are no alignedItems',
        async () => {
          wrapper.vm.store.updateAlignedItems('[]');
          wrapper.vm.store.selectedTocItems = [];
          await wrapper.vm.$nextTick();
          expect(wrapper.find('.test-no-unit-lesson-selected-msg').element).not.toBeVisible();
        }
      );
      it('Displays the matching content count for the selected units', () => {
        const matchingCount = wrapper.find('.test-matching-content-count').text();
        expect(matchingCount).toBe(`Matching Content (${matchingContentCount})`);
      });
    });


    describe('Selected Standards', () => {
      beforeEach(() => {
        wrapper.vm.store.selectedStandards = ['801B8198-7440-11DF-93FA-01FD9CFF4B22'];
      });
      it('Highlights selected standards', () => {
        const selected =
              wrapper.find('.test-standard-number-801B8198-7440-11DF-93FA-01FD9CFF4B22');
        const notSelected =
              wrapper.find('.test-standard-number-802BBFB8-7440-11DF-93FA-01FD9CFF4B22');
        expect(selected.exists()).toBe(true);
        expect(notSelected.exists()).toBe(false);
      });
    });
  });
