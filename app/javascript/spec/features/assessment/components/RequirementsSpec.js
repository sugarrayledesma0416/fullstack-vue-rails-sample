import { mount } from '@vue/test-utils';
import Requirements from 'features/assessment/components/Requirements.vue';

function getWrapper(propsData) {
  return mount(Requirements, { propsData });
}

describe('Requirements.vue', () => {
  let wrapper;
  let values;

  describe('renders correctly', () => {
    beforeEach(() => {
      wrapper = getWrapper({
        icons: 'solo_video_recording,audio,microphone,video',
      });
    });

    it('renders the requirement heading', () => {
      expect(
        wrapper.find('.test-requirement-heading').text()
      ).toBe('What is required?');
    });
  });

  describe('filters and displays the list items correctly', () => {
    let items;
    beforeEach(() => {
      wrapper = getWrapper({
        icons: 'solo_video_recording,audio,microphone,video',
      });
      items = wrapper.findAll('.requirement-list li');
    });

    it('displays the correct number of list items', () => {
      expect(items).toHaveLength(3);
    });

    it('displays the correct titles and classes for Listening', () => {
      expect(items[0].text()).toBe('Listening');
      expect(items[0].classes()).toContain('audio');
    });

    it('displays the correct titles and classes for Speaking', () => {
      expect(items[1].text()).toBe('Speaking');
      expect(items[1].classes()).toContain('microphone');
    });

    it('displays the correct titles and classes for Video Recording', () => {
      expect(items[2].text()).toBe('Video Recording');
      expect(items[2].classes()).toContain('video');
    });
  });

  describe('filterValues function behavior for solo_video_recording', () => {
    beforeEach(() => {
      wrapper = getWrapper({ icons: 'solo_video_recording' });
      values = wrapper.vm.filterValues();
    });

    it('returns correct values for solo_video_recording', () => {
      expect(values).toEqual([
        { class: 'audio', title: 'Listening' },
        { class: 'microphone', title: 'Speaking' },
        { class: 'video', title: 'Video Recording' },
      ]);
    });
  });

  describe('filterValues function behavior for audio', () => {
    beforeEach(() => {
      wrapper = getWrapper({ icons: 'audio' });
      values = wrapper.vm.filterValues();
    });

    it('returns correct values for audio', () => {
      expect(values).toEqual([{ class: 'audio', title: 'Listening' }]);
    });
  });

  describe('filterValues function behavior for microphone', () => {
    beforeEach(() => {
      wrapper = getWrapper({ icons: 'microphone' });
      values = wrapper.vm.filterValues();
    });

    it('returns correct values for microphone', () => {
      expect(values).toEqual([{ class: 'microphone', title: 'Speaking' }]);
    });
  });

  describe('filterValues function behavior for video', () => {
    beforeEach(() => {
      wrapper = getWrapper({ icons: 'video' });
      values = wrapper.vm.filterValues();
    });

    it('returns correct values for video', () => {
      expect(values).toEqual([{ class: 'video', title: 'Video Recording' }]);
    });
  });

  describe('filterValues function behavior with duplicate values', () => {
    beforeEach(() => {
      wrapper = getWrapper({ icons: 'audio,audio' });
      values = wrapper.vm.filterValues();
    });

    it('removes duplicate values', () => {
      expect(values).toEqual([{ class: 'audio', title: 'Listening' }]);
    });
  });
});
