import { mount } from '@vue/test-utils';
import { useAutoPlayAudio } from 'shared/use_auto_play_audio.js';
import DefaultAudioIcon from 'views/activities/default_activity_context/DefaultAudioIcon.vue';
import MusicMediaButton from 'shared/vue/MusicMediaButton.vue';

// Mock the useAutoPlayAudio composable
jest.mock('shared/use_auto_play_audio.js', () => ({
  useAutoPlayAudio: jest.fn(),
}));

// Mock HTMLMediaElement methods
HTMLMediaElement.prototype.play = jest.fn();
HTMLMediaElement.prototype.pause = jest.fn();

describe('DefaultAudioIcon', () => {
  let mockUseAutoPlayAudio;

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseAutoPlayAudio = {
      hasAudio: false,
      isAudioPlaying: false,
      play: jest.fn(),
      pause: jest.fn(),
    };
    useAutoPlayAudio.mockReturnValue(mockUseAutoPlayAudio);
  });

  function getWrapper(optionalProps = {}) {
    const props = { audioPaths: '[]', ...optionalProps };
    return mount(DefaultAudioIcon, {
      props,
      global: {
        stubs: { MusicMediaButton: true },
      },
    });
  }

  describe('when no audio paths are provided', () => {
    let wrapper;

    beforeEach(() => {
      mockUseAutoPlayAudio.hasAudio = false;
      wrapper = getWrapper();
    });

    it('does not render the audio button', () => {
      expect(wrapper.find('.test-default-audio-icon').exists()).toBeFalsy();
    });
  });

  describe('when audio paths are provided', () => {
    let wrapper;

    beforeEach(() => {
      mockUseAutoPlayAudio.hasAudio = true;
      mockUseAutoPlayAudio.isAudioPlaying = false;
      wrapper = getWrapper({ audioPaths: '["/path/to/audio.mp3"]' });
    });

    it('renders the audio button', () => {
      expect(wrapper.find('.test-default-audio-icon').exists()).toBeTruthy();
    });

    it('passes correct props to MusicMediaButton', () => {
      const musicMediaButton = wrapper.findComponent(MusicMediaButton);
      expect(musicMediaButton.props()).toEqual(
        expect.objectContaining({
          variant: 'listen',
          toggle: 'stop',
          size: 'sm',
          onActivate: expect.any(Function),
          onDeactivate: expect.any(Function),
          state: 'default',
        })
      );
    });

    it('calls play when MusicMediaButton is activated', async () => {
      const musicMediaButton = wrapper.findComponent(MusicMediaButton);
      await musicMediaButton.vm.$emit('activate');

      expect(mockUseAutoPlayAudio.play).toHaveBeenCalled();
    });

    it('calls pause when MusicMediaButton is deactivated', async () => {
      const musicMediaButton = wrapper.findComponent(MusicMediaButton);
      await musicMediaButton.vm.$emit('deactivate');

      expect(mockUseAutoPlayAudio.pause).toHaveBeenCalled();
    });
  });
});
