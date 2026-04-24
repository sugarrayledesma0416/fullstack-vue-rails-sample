import { useAutoPlayAudio } from 'shared/use_auto_play_audio';

jest.mock('vue', () => ({
  reactive: jest.fn((obj) => obj),
  computed: jest.fn((fn) => ({ value: fn() })),
}));

describe('useAutoPlayAudio', () => {
  let mockAudioCollectionScheduler;
  let audioPaths;

  beforeEach(() => {
    mockAudioCollectionScheduler = {
      files: [],
      play_all: jest.fn(),
      stop_and_reset: jest.fn(),
    };

    global.VHL = {
      Audio: {
        CollectionScheduler: jest.fn().mockImplementation(() => mockAudioCollectionScheduler),
      },
    };

    audioPaths = ['path/to/audio1.mp3', 'path/to/audio2.mp3'];
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('initializes with correct default state when audioPaths is empty', () => {
    const { hasAudio, isAudioPlaying, pause, play } = useAutoPlayAudio([]);
    expect({ hasAudio: hasAudio.value, isAudioPlaying: isAudioPlaying.value, pause, play })
      .toEqual({
        hasAudio: false,
        isAudioPlaying: false,
        pause: expect.any(Function),
        play: expect.any(Function),
      });
  });

  it('initializes audioFiles when audioPaths is provided', () => {
    mockAudioCollectionScheduler.files = audioPaths;
    const { hasAudio } = useAutoPlayAudio(audioPaths);

    expect(hasAudio.value).toBeTruthy();
  });

  it('plays audio and updates isPlaying state', () => {
    mockAudioCollectionScheduler.files = audioPaths;
    const { play } = useAutoPlayAudio(audioPaths);
    play();

    expect(mockAudioCollectionScheduler.play_all).toHaveBeenCalledWith({
      callback: expect.any(Function),
      when: 'before',
      last_callback: expect.any(Function),
    });
  });

  it('pauses audio and resets state', () => {
    mockAudioCollectionScheduler.files = audioPaths;
    const { pause } = useAutoPlayAudio(audioPaths);
    pause();

    expect(mockAudioCollectionScheduler.stop_and_reset).toHaveBeenCalled();
  });

  it('does not attempt to play if no audio files exist', () => {
    const { play } = useAutoPlayAudio([]);
    play();

    expect(mockAudioCollectionScheduler.play_all).not.toHaveBeenCalled();
  });

  it('does not attempt to pause if no audio files exist', () => {
    const { pause } = useAutoPlayAudio([]);
    pause();

    expect(mockAudioCollectionScheduler.stop_and_reset).not.toHaveBeenCalled();
  });
});
