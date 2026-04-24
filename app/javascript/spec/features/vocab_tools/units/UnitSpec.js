import { mount } from '@vue/test-utils';
import Unit from 'features/vocab_tools/units/Unit';
import { getHtmlDocument } from '../../../support/utils';

const unit = {
  id: 514,
  in_course: true,
  media_item_filename: 'https://media.maestro.vhlcentral.com/images/0013/00135911.png',
  name: 'Unité 1',
};

const currentProgram = {
  id: 102,
  image_filename: 'portails1.png',
  language_code: 'fr',
};

const getWrapper = () => {
  return mount(Unit, {
    props: { unit },
    global: {
      provide: { currentProgram, viewAllLessons: false },
    },
  });
};

describe('Vocab Tools Unit', () => {
  describe('I can see a Unit and its information', () => {
    let wrapper;
    const htmlDOM = getHtmlDocument(
      `<input 
        class="js-unit-514" 
        type="hidden" 
        data-vocab-tools-word-path="/79/vocab_tools/words?unit_id=315">
        </input>`
    );
    document.body = htmlDOM.body;

    beforeEach(() => wrapper = getWrapper());

    it('contains the url of the image attach to the unit', () => {
      expect(
        wrapper.get('.test-unit-image').attributes().src
      ).toBe(unit.media_item_filename);
    });

    it('has name of the unit attached on the figure caption', () => {
      expect(wrapper.get('.test-gallery-link').text()).toBe(unit.name);
    });

    it('has a language code for the caption', () => {
      expect(
        wrapper.get('.test-gallery-link').attributes().lang
      ).toBe(currentProgram.language_code);
    });
  });
});
