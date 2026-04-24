import { shallowMount } from '@vue/test-utils';
/* eslint-disable-next-line max-len */
import StandardsCategoryList from 'features/gradebook/standards/student_detail_report/StandardsCategoryList';

const props = {
  standardCategoryList: {
    all_standards_content: 0,
    meeting: 0,
    progressing: 0,
    needs_some_support: 0,
    needs_moderate_support: 0,
    needs_high_support: 0,
  },
  unitId: 2965,
};

function getWrapper() {
  return shallowMount(
    StandardsCategoryList,
    {
      props: props,
    });
}

describe(
  'StandardsCategoryListSpec',
  () => {
    let wrapper;
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('Shows the standards category list', ()=> {
      expect(wrapper.findAll('.test-standard-category').length).toBe(6);
    });

    describe(
      'when clicking on a standard category',
      () => {
        let wrapper;
        beforeEach(async () => {
          wrapper = getWrapper();
        });

        it('emits "getStandardsRange" event', async () => {
          const itemElms = await wrapper.findAll('.test-standard-category');
          itemElms[0].trigger('click');
          expect(wrapper.emitted().getStandardsRange).toBeTruthy();
        });
      }
    );
  }
);
