import { mount } from '@vue/test-utils';
import { useAutoPlayAudio } from 'shared/use_auto_play_audio.js';
import Icon from 'shared/custom_elements/vhl_icon';
import JuniorDirectionLineIcon from 'views/activities/supersite_junior_activity_context/JuniorDirectionLineIcon';

// Mock the useAutoPlayAudio composable
jest.mock('shared/use_auto_play_audio.js', () => ({
  useAutoPlayAudio: jest.fn(),
}));

customElements.define('vhl-icon', Icon);

HTMLMediaElement.prototype.load = jest.fn();

describe('JuniorDirectionLineIcon', () => {
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
    const props = Object.assign(
      {
        audioIconPath: 'path/to/audio/icon',
        juniorDirectionLineIconPath: 'path/to/direction/line/icon',
      },
      optionalProps
    );

    return mount(JuniorDirectionLineIcon, { props });
  }

  function penguinBlock(wrapper) {
    return wrapper.find('.test-penguin');
  }

  function audioBlock(wrapper) {
    return wrapper.find('.test-audio');
  }

  function expectPenguinBlock(wrapper) {
    expect(penguinBlock(wrapper).exists()).toBeTruthy();
  }

  function expectAudioBlock(wrapper) {
    expect(audioBlock(wrapper).exists()).toBeTruthy();
  }

  function expectNoAudioBlock(wrapper) {
    expect(audioBlock(wrapper).exists()).toBeFalsy();
  }

  describe('when no audio path is included', () => {
    let wrapper;
    beforeEach(() => {
      mockUseAutoPlayAudio.hasAudio = false;
      wrapper = getWrapper();
    });

    it('shows the penguin icon', () => expectPenguinBlock(wrapper));
    it('does not show the audio icon', () => expectNoAudioBlock(wrapper));
  });


  describe('when an audio path is included', () => {
    let wrapper;
    beforeEach(() => {
      mockUseAutoPlayAudio.hasAudio = true;
      wrapper = getWrapper({ audioPaths: '["path/to/audio.mp3"]' });
    });

    it('shows the penguin icon', () => expectPenguinBlock(wrapper));
    it('shows the audio icon', () => expectAudioBlock(wrapper));

    describe('when the audio icon is clicked', () => {
      it('calls play if audio is not playing', async () => {
        const playMock = useAutoPlayAudio().play;
        await audioBlock(wrapper).trigger('click');

        expect(playMock).toHaveBeenCalled();
      });
    });
  });
});
