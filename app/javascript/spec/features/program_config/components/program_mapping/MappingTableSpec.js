import { mount } from '@vue/test-utils';
import MappingTable from 'features/program_config/components/program_mapping/MappingTable';

const programToProgramMapping = {
  getDestLessonStrands: jest.fn(),
};

VHL = { Music: { V1: {}}};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
};

const lesson = {
  name: 'Lesson 1',
  concepts: [
    {
      id: 1,
      name: 'Concept 1',
      strands_for_dest_lesson_array: [
        ['Contextos', '1'],
        ['Fotonovela', '2'],
      ],
    },
    {
      id: 2,
      name: 'Concept 2',
      strands_for_dest_lesson_array: [
        ['Cultura', '3'],
        ['Estructura', '4'],
      ],
    },
  ],
};

const getWrapper = () => {
  return mount(MappingTable, {
    global: {
      provide: {
        programId: 1,
        programToProgramMapping,
      },
    },
    props: {
      lesson,
      lessonsForDestPrograms: [
        ['Lesson 1', 1],
        ['Lesson 1', 2],
      ],

    },
  });
};

describe('MappingTable', () => {
  let wrapper;

  describe('on mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it("displays Lesson's name", () => {
      expect(wrapper.get('.test-lesson-title').text()).toContain('Lesson 1');
    });

    it('displays all lesson`s concept name', () => {
      lesson.concepts.forEach((concept) => {
        expect(
          wrapper.get(`.test-concept-${concept.id} .test-concept_name`).text()
        ).toContain(concept.name);
      });
    });

    it('displays all lesson`s concept strands', () => {
      lesson.concepts.forEach((concept) => {
        const strands = concept.strands_for_dest_lesson_array;
        const options = wrapper.get(
          `.test-concept-${concept.id} .test-concept-strands`
        ).findAll('option');

        strands.forEach((strand, i) => {
          const option = options[i+1];
          expect(option.attributes('value')).toEqual(strand[1]);
          expect(option.text()).toEqual(strand[0]);
        });
      });
    });
  });

  describe('when concept`s lesson is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const select = wrapper.find(
        '.test-concept-1 .test-concept-lessons'
      );
      select.element.value = 2;
      await select.trigger('change');
    });

    it('fetches strands for selected lesson', () => {
      expect(
        programToProgramMapping.getDestLessonStrands
      ).toHaveBeenCalledWith(2);
    });
  });
});
