import { mount } from '@vue/test-utils';
import OtherFeaturesSettings from 'features/program_config/components/OtherFeaturesSettings';

/**
 * This method returns props for OtherFeaturesSettings component
 * @param {boolean} bChecked - Boolean value for checkbox
 * @param {string} languageCode - Language code for the program
 * @return {Object} - Props for OtherFeaturesSettings component
 */
const getOtherFeaturesSettings = (bChecked, languageCode) => {
  return {
    allowAssessmentsRandomization: bChecked,
    audioTranscripts: bChecked,
    hideActivities: bChecked,
    hideAssessment: bChecked,
    hideMyContent: bChecked,
    hideTranslation: bChecked,
    languageCode: languageCode,
    practiceTestAnalyticsEnabled: bChecked,
    questionBanksEnabled: bChecked,
    shareToPortfolio: bChecked,
    showSkillsAndRefinementFilters: bChecked,
    pmrStandardReportsAllowed: bChecked,
    enableConcurrentEnrollment: bChecked,
    speechRec: bChecked,
    studyCenter: bChecked,
    vocabDefinition: bChecked,
    vocabWords: bChecked,
  };
};

let wrapper;
const getWrapper = (propsData) => mount(OtherFeaturesSettings, {
  propsData,
  global: {
    stubs: {
      BasicDialog: {
        template: '<div class="basic-dialog-stub"><slot name="body"></slot><slot name="footer"></slot></div>',
        props: ['title', 'isConfirmationDialog', 'isModal'],
        emits: ['close-dialog']
      },
      StandardButton: {
        template: '<button class="standard-button-stub" @click="$emit(\'click\')"><slot></slot></button>',
        props: ['variant'],
        emits: ['click']
      }
    }
  }
});

/**
 * This method returns whether the checkbox with the given css selector is checked
 * or not in the wrapper
 * @param {string} elmSelector - Css selector for checkbox
 * @return {boolean} - Whether the checkbox is checked
 */
const getCheckedState = (elmSelector) => {
  return wrapper.get(elmSelector).element.checked;
};

/**
 * This method simulates 'change' event in the checkbox with the given css selector
 * @param {string} elmSelector - Css selector for checkbox
 */
const triggerChangeInCheckbox = async (elmSelector) => {
  const checkbox = wrapper.find(elmSelector);
  await checkbox.trigger('click');
  await checkbox.trigger('change');
};

describe('Other Features Settings in Program Config', () => {
  describe('When program language is English', () => {
    describe('When all configuration values are set to false', () => {
      beforeEach(() => {
        const otherFeaturesSettings = getOtherFeaturesSettings(false, 'en');
        wrapper = getWrapper(otherFeaturesSettings);
      });

      it('contains unchecked checkbox to configure "Hide Translation Column in Vocab Tools"',
        () => {
          expect(getCheckedState('.test-datastore-hide-translation')).toBeFalsy();
        }
      );

      it('contains unchecked checkbox to configure "Show Definition Column in Vocabulary Tools"',
        () => {
          expect(getCheckedState('.test-datastore-vocab-definition')).toBeFalsy();
        }
      );

      it('contains unchecked checkbox to configure "Previous Vocabulary feature"', () => {
        expect(getCheckedState('.test-datastore-vocabulary-feature')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Share to Portfolio"', () => {
        expect(getCheckedState('.test-datastore-share-to-portfolio')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Skills and Refinement Filters"', () => {
        expect(getCheckedState('.test-datastore-show-skills-and-refinement-filters')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Enable Concurrent Enrollment"', () => {
        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Enable Speech Recognition"', () => {
        expect(getCheckedState('.test-datastore-speech-rec')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Hide Activities in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-activities')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Hide Assessment in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-assessment')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Hide My Content in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-my-content')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Show Audio Transcript in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-audio-transcripts')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Show Study Center on Student Dashboard"',
        () => {
          expect(getCheckedState('.test-datastore-study-center')).toBeFalsy();
        }
      );

      it('contains unchecked checkbox to configure "Allow assessments randomization"', () => {
        expect(getCheckedState('.test-datastore-allow-assessments-randomization')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Standard Reports"', () => {
        expect(getCheckedState('.test-datastore-pmr-standard-reports-allowed')).toBeFalsy();
      });

      it('contains unchecked checkbox to configure "Supports Question Banks in custom assessments"',
        () => {
          expect(getCheckedState('.test-datastore-question-banks-enabled')).toBeFalsy();
        }
      );

      it('contains an unchecked checkbox to configure ' +
         '"Show Practice Test link in Gradebook Analytics navigation"',
      () => {
        expect(
          getCheckedState('.test-datastore-practice-test-analytics-enabled')
        ).toBeFalsy();
      }
      );

      it('checks checkbox for "Show Definition Column in Vocabulary Tools" ' +
        'when "Hide Translation" checkbox is checked',
      async () => {
        await triggerChangeInCheckbox('.test-datastore-hide-translation');
        expect(getCheckedState('.test-datastore-vocab-definition')).toBeTruthy();
      });
    });

    describe('When all configuration values are set to true', () => {
      beforeEach(() => {
        const otherFeaturesSettings = getOtherFeaturesSettings(true, 'en');
        wrapper = getWrapper(otherFeaturesSettings);
      });

      it('contains checked checkbox to configure "Hide Translation Column in Vocab Tools"',
        () => {
          expect(getCheckedState('.test-datastore-hide-translation')).toBeTruthy();
        }
      );

      it('contains checked checkbox to configure "Show Definition Column in Vocabulary Tools"',
        () => {
          expect(getCheckedState('.test-datastore-vocab-definition')).toBeTruthy();
        }
      );

      it('contains checked checkbox to configure "Previous Vocabulary feature"', () => {
        expect(getCheckedState('.test-datastore-vocabulary-feature')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Share to Portfolio"', () => {
        expect(getCheckedState('.test-datastore-share-to-portfolio')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Skills and Refinement Filters"', () => {
        expect(getCheckedState('.test-datastore-show-skills-and-refinement-filters')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Standard Reports"', () => {
        expect(getCheckedState('.test-datastore-pmr-standard-reports-allowed')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Enable Concurrent Enrollment"', () => {
        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Enable Speech Recognition"', () => {
        expect(getCheckedState('.test-datastore-speech-rec')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Hide Activities in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-activities')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Hide Assessment in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-assessment')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Hide My Content in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-hide-my-content')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Show Audio Transcript in Content Menu"', () => {
        expect(getCheckedState('.test-datastore-audio-transcripts')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Show Study Center on Student Dashboard"',
        () => {
          expect(getCheckedState('.test-datastore-study-center')).toBeTruthy();
        }
      );

      it('contains checked checkbox to configure "Allow assessments randomization"', () => {
        expect(getCheckedState('.test-datastore-allow-assessments-randomization')).toBeTruthy();
      });

      it('contains checked checkbox to configure "Supports Question Banks ' +
        'in custom assessments"', () => {
        expect(getCheckedState('.test-datastore-question-banks-enabled')).toBeTruthy();
      });

      it('contains a checked checkbox to configure ' +
         '"Show Practice Test link in Gradebook Analytics navigation"',
      () => {
        expect(
          getCheckedState('.test-datastore-practice-test-analytics-enabled')
        ).toBeTruthy();
      }
      );

      it('unchecks checkbox for "Show Definition Column in Vocabulary Tools" ' +
        'when "Hide Translation" checkbox is unchecked',
      async () => {
        await triggerChangeInCheckbox('.test-datastore-hide-translation');
        expect(getCheckedState('.test-datastore-vocab-definition')).toBeFalsy();
      });
    });
  });

  describe('When program language is not English', () => {
    beforeEach(() => {
      const otherFeaturesSettings = getOtherFeaturesSettings(false, 'fr');
      wrapper = getWrapper(otherFeaturesSettings);
    });

    it('does not contain checkbox to configure "Hide Translation Column in Vocab Tools"', () => {
      expect(wrapper.find('.test-datastore-hide-translation').exists()).toBeFalsy();
    });
  });

  describe('Concurrent Enrollment Dialog', () => {
    describe('Standard dialog content and behavior', () => {
      beforeEach(() => {
        const otherFeaturesSettings = getOtherFeaturesSettings(false, 'en');
        wrapper = getWrapper(otherFeaturesSettings);
      });

      it('displays correct confirmation message', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const confirmationText = wrapper.find('.concurrent-enrollment-change-requirement').text();

        expect(confirmationText).toContain('changes enrollment and student work transfer behavior');
        expect(confirmationText).toContain('Written approval from the K12 General Manager');
      });

      it('has Confirm and Cancel buttons', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');

        expect(wrapper.find('.test-confirm-concurrent-enrollment-btn').exists()).toBeTruthy();
        expect(wrapper.find('.test-cancel-concurrent-enrollment-btn').exists()).toBeTruthy();
      });
    });

    describe('When concurrent enrollment is initially disabled', () => {
      beforeEach(() => {
        const otherFeaturesSettings = getOtherFeaturesSettings(false, 'en');
        wrapper = getWrapper(otherFeaturesSettings);
      });

      it('shows dialog when user tries to enable concurrent enrollment', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeTruthy();
      });

      it('shows dialog with title "Enable Concurrent Enrollment?"', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const dialog = wrapper.findComponent('.basic-dialog-stub');

        expect(dialog.props('title')).toBe('Enable Concurrent Enrollment?');
      });

      it('keeps checkbox enabled when user clicks Confirm', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const confirmButton = wrapper.find('.test-confirm-concurrent-enrollment-btn');
        await confirmButton.trigger('click');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeTruthy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('does not show dialog when user confirms and then changes the checkbox back to its original value', async () => {
        // Change the checkbox value and confirm the change.
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const confirmButton = wrapper.find('.test-confirm-concurrent-enrollment-btn');
        await confirmButton.trigger('click');

        // Change the checkbox value again and do not see the dialog.
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('reverts checkbox to disabled when user clicks Cancel', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const cancelButton = wrapper.find('.test-cancel-concurrent-enrollment-btn');
        await cancelButton.trigger('click');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeFalsy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('reverts checkbox to disabled when user clicks X (close dialog)', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const dialog = wrapper.findComponent('.basic-dialog-stub');
        await dialog.vm.$emit('close-dialog');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeFalsy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });
    });

    describe('When concurrent enrollment is initially enabled', () => {
      beforeEach(() => {
        const otherFeaturesSettings = getOtherFeaturesSettings(true, 'en');
        wrapper = getWrapper(otherFeaturesSettings);
      });

      it('shows dialog when user tries to disable concurrent enrollment', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeTruthy();
      });

      it('shows dialog with title "Disable Concurrent Enrollment?"', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const dialog = wrapper.findComponent('.basic-dialog-stub');

        expect(dialog.props('title')).toBe('Disable Concurrent Enrollment?');
      });

      it('keeps checkbox disabled when user clicks Confirm', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const confirmButton = wrapper.find('.test-confirm-concurrent-enrollment-btn');
        await confirmButton.trigger('click');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeFalsy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('does not show dialog when user confirms and then changes the checkbox back to its original value', async () => {
        // Change the checkbox value and confirm the change.
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const confirmButton = wrapper.find('.test-confirm-concurrent-enrollment-btn');
        await confirmButton.trigger('click');

        // Change the checkbox value again and do not see the dialog.
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('reverts checkbox to enabled when user clicks Cancel', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const cancelButton = wrapper.find('.test-cancel-concurrent-enrollment-btn');
        await cancelButton.trigger('click');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeTruthy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });

      it('reverts checkbox to enabled when user clicks X (close dialog)', async () => {
        await triggerChangeInCheckbox('.test-datastore-enable-concurrent-enrollment');
        const dialog = wrapper.findComponent('.basic-dialog-stub');
        await dialog.vm.$emit('close-dialog');

        expect(getCheckedState('.test-datastore-enable-concurrent-enrollment')).toBeTruthy();
        expect(wrapper.find('.concurrent-enrollment-change-requirement').exists()).toBeFalsy();
      });
    });
  });
});
