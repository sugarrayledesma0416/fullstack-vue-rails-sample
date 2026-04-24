import { mount } from '@vue/test-utils';
import VhlLink from 'features/learning_tracks/components/VhlLink';

/**
 * @typeDef VhlLinkPropsObject
 * @property {string} featureVariant - Component's feature variant
 * @property {string} href - Value of href for the link
 * @property {string} htmlText - Html text
 * @property {string} isDisabled - Whether link is disabled
 * @property {string} target - Link target
 * @property {string} testSelector - Test class selector
 * @property {string} variant - Component variant
 */

let wrapper;

const props = {
  featureVariant: 'dummy-feature',
  href: 'javascript://',
  htmlText: '',
  isDisabled: false,
  target: '',
  testSelector: 'link',
  variant: 'primary',
};

/**
 * This method gets wrapper for VhlLink component
 * @param {VhlLinkPropsObject} props - vue props for VhlLink component
 * @return {Wrapper}
 */
function getWrapper(props) {
  return mount(VhlLink, {
    props,
    slots: {
      default: '<div class="test-div-in-slot">content here</div>',
    },
  });
}

describe('Link Component', () => {
  describe('mounted', () => {
    beforeEach(() => wrapper = getWrapper(props));

    it('displays anchor tag', () => {
      expect(wrapper.get('.test-link').exists()).toBeTruthy();
    });

    it('displays a tag with variant class as "c-link--primary"', () => {
      expect(
        wrapper.get('.test-link').classes('c-link--primary')
      ).toBeTruthy();
    });

    it('displays a tag with feature variant as "c-link--dummy-feature"', () => {
      expect(
        wrapper.get('.test-link').classes('c-link--dummy-feature')
      ).toBeTruthy();
    });

    it('does not contain is-disabled class', () => {
      expect(
        wrapper.get('.test-link').classes('is-disabled')
      ).toBeFalsy();
    });

    it('contains href as "javascript://"', () => {
      expect(
        wrapper.get('.test-link').element.href
      ).toBe('javascript://');
    });

    it('contains provided content in the slot', () => {
      expect(
        wrapper.find('.test-link').html()
      ).toContain('<div class="test-div-in-slot">content here</div>');
    });

    it('emits click event on link click', async () => {
      await wrapper.get('.test-link').trigger('click');
      expect(wrapper.emitted().click).toBeTruthy();
    });

    it('emits mouseover event on link mouseover', async () => {
      await wrapper.get('.test-link').trigger('mouseover');
      expect(wrapper.emitted().mouseover).toBeTruthy();
    });

    it('emits mouseleave event on link mouseleave', async () => {
      await wrapper.get('.test-link').trigger('mouseleave');
      expect(wrapper.emitted().mouseleave).toBeTruthy();
    });
  });

  describe('isDisabled as true', () => {
    beforeEach(() => {
      props.isDisabled = true;
      wrapper = getWrapper(props);
    });

    it('contains is-disabled class', () => {
      expect(
        wrapper.get('.test-link').classes('is-disabled')
      ).toBeTruthy();
    });
  });

  describe('when "htmlText" vue prop has html value', () => {
    beforeEach(() => {
      props.htmlText = '<span class="class-1">text with <b>html</b></span>';
      wrapper = getWrapper(props);
    });

    it('contains provided html', () => {
      expect(
        wrapper.get('.test-html-text').html()
      ).toContain('<span class="class-1">text with <b>html</b></span>');
    });

    it('does not contain provided content in the slot', () => {
      expect(
        wrapper.find('.test-link').html()
      ).not.toContain('<div class="test-div-in-slot">content here</div>');
    });
  });
});
