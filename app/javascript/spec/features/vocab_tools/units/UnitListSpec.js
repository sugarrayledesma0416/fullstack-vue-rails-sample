import { mount } from '@vue/test-utils';
import UnitList from 'features/vocab_tools/units/UnitList';
import Unit from 'features/vocab_tools/units/Unit';
import { getHtmlDocument } from '../../../support/utils';

let wrapper;
const unitsData = {
  enrolled: false,
  language_name: 'Spanish',
  units: [
    {
      id: 315,
      in_course: true,
      media_item_filename: 'https://media.maestro.vhlcentral.com/images/0014/00145551.jpg',
      name: 'Lección 13',
    },
    {
      id: 316,
      in_course: true,
      media_item_filename: 'https://media.maestro.vhlcentral.com/images/0014/00145553.jpg',
      name: 'Lección 14',
    },
    {
      id: 317,
      in_course: false,
      media_item_filename: 'https://media.maestro.vhlcentral.com/images/0014/00145555.jpg',
      name: 'Lección 15',
    },
  ],
};

const currentProgram = {
  id: 79,
  image_filename: 'portales1.png',
  language_code: 'es',
};

const getWrapper = (props) => {
  return mount(UnitList, {
    props,
    global: {
      provide: { currentProgram },
    },
  });
};

const htmlDOM = getHtmlDocument(
  `<input
    class="js-unit-315"
    type="hidden"
    data-vocab-tools-word-path="/79/vocab_tools/words?unit_id=315">
  <input
    class="js-unit-316"
    type="hidden"
    data-vocab-tools-word-path="/79/vocab_tools/words?unit_id=316">
  <input
    class="js-unit-317"
    type="hidden"
    data-vocab-tools-word-path="/79/vocab_tools/words?unit_id=317">`
);

const expectUnitToBeVisible = (unitId) => {
  expect(
    wrapper.get(`.test-gallery-images-${unitId}`).element
  ).toBeVisible();
};

const expectUnitNotToBeVisible = (unitId) => {
  expect(
    wrapper.get(`.test-gallery-images-${unitId}`).element
  ).not.toBeVisible();
};

describe('Vocab Tools Units', () => {
  document.body = htmlDOM.body;

  describe('As a Instructor, I can see a list of units and its information', () => {
    beforeEach(() => {
      const props = { unitsData, enrolled: false, viewAllLessons: false };
      wrapper = getWrapper(props);
    });

    it('does not display the lesson view controls', () => {
      expect(
        wrapper.get('.test-lesson-view-controls').element
      ).not.toBeVisible();
    });

    it('renders three Unit components', () => {
      expect(wrapper.findAllComponents(Unit)).toHaveLength(3);
    });
  });

  describe('As a Student, I can see a list of units and its information', () => {
    beforeEach(() => {
      const props = { unitsData, enrolled: true, viewAllLessons: false };
      wrapper = getWrapper(props);
    });

    it('displays the lesson view controls', () => {
      expect(
        wrapper.get('.test-lesson-view-controls').element
      ).toBeVisible();
    });

    it('displays "View all lessons in this program" text', () => {
      const programLessons = wrapper.get('.test-program-lessons');
      expect(programLessons.element).toBeVisible();
      expect(programLessons.text()).toBe('View all lessons in this program');
    });

    it('renders three Unit components', () => {
      expect(wrapper.findAllComponents(Unit)).toHaveLength(3);
    });

    it('does not display the unit with "in_course" as "false"', () => {
      expectUnitNotToBeVisible(unitsData.units[2].id);
    });

    it('does not display the unit with "in_course" as "true"', () => {
      expectUnitToBeVisible(unitsData.units[0].id);
      expectUnitToBeVisible(unitsData.units[1].id);
    });
  });

  describe('when the user chooses to view all lessons in the program', () => {
    beforeEach(async () => {
      const props = { unitsData, enrolled: true, viewAllLessons: false };
      wrapper = getWrapper(props);
      await wrapper.get('.test-program-lessons').trigger('click');
    });

    it('displays "View only lessons for this course" text', () => {
      const courseLessons = wrapper.get('.test-course-lessons');
      expect(courseLessons.element).toBeVisible();
      expect(courseLessons.text()).toBe('View only lessons for this course');
    });

    it('displays the unit with "in_course" as "false"', () => {
      expectUnitToBeVisible(unitsData.units[2].id);
    });
  });
});
