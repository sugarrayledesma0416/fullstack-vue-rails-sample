import { shallowMount } from '@vue/test-utils';
import AssessmentMultipleSelect
  from 'features/gradebook/standards/section_report_filters/components/AssessmentMultipleSelect';
import { createPinia, setActivePinia } from 'pinia';

describe(
  'AssessmentMultipleSelect',
  () => {
    const pinia = createPinia();
    setActivePinia(pinia);

    const assessmentName1 = 'Assessment One';
    const assessmentName2 = 'Assessment Two';
    const assessmentId1 = 123456;
    const assessmentId2 = 567890;
    const propsData = {
      assessments: [
        [assessmentName1, assessmentId1],
        [assessmentName2, assessmentId2],
      ],
    };

    let wrapper;

    function getWrapper(propsData = {}) {
      return shallowMount(
        AssessmentMultipleSelect,
        {
          propsData,
          global: {
            plugins: [pinia],
            stubs: {
              BasicDisclosure: {
                template: '<button class="test-basic-disclosure"><slot /></button>',
              },
            },
          },
        }
      );
    }

    beforeEach(() => {
      wrapper = getWrapper();
    });

    describe('when the component is first rendered', () => {
      it('is empty', () => {
        expect(wrapper.findAll('.test-assessment-checkbox').length).toEqual(0);
      });

      it('is disabled', () => {
        expect(wrapper.find('.test-assessment-multi-select').attributes('disabled')).toBeDefined();
      });
    });

    describe('when the options prop is set to a non-empty array', () => {
      beforeEach(() => {
        wrapper = getWrapper(propsData);
      });

      it('has inputs with the expected values', () => {
        const inputs = wrapper.findAll('.test-assessment-checkbox');
        expect(inputs.map((input) => input.attributes('value'))).toEqual(
          [assessmentId1.toString(), assessmentId2.toString()]
        );
      });

      it('has inputs with the expected text', () => {
        const inputs = wrapper.findAll('.test-assessment-label');
        expect(inputs.map((input) => input.text())).toEqual(
          [assessmentName1, assessmentName2]
        );
      });

      it('is enabled', () => {
        expect(wrapper.find('.test-assessment-multi-select').attributes('disabled')).toBeFalsy();
      });
    });

    describe('checked appearance', () => {
      beforeEach(async () => {
        wrapper = getWrapper(propsData);
        wrapper.find(`#assessment-id-${assessmentId2}`).setChecked();
        wrapper.find(`#assessment-id-${assessmentId2}`).trigger('change');
        await wrapper.vm.$nextTick();
      });

      describe('when a row is checked', () => {
        it('has the "selected-row" class added to it', async () => {
          expect(wrapper.find('#assessment-option-1').classes()).toContain('selected-row');
        });
      });

      describe('when a row is unchecked', () => {
        it('has the "selected-row" class removed from it', async () => {
          wrapper.find(`#assessment-id-${assessmentId2}`).setChecked(false);
          wrapper.find(`#assessment-id-${assessmentId2}`).trigger('change');
          await wrapper.vm.$nextTick();
          expect(wrapper.find('#assessment-option-1').classes()).not.toContain('selected-row');
        });
      });
    });
  }
);
