import RecordingControlsManager from 'shared/vue/recording_controls_manager';

const mockSetupPlayer = jest.fn();
const mockSetupAudioPlayback = jest.fn();
const mockSetupAudioRecorder = jest.fn();

jest.mock(
  'shared/vue/use_player_setup',
  () => {
    return jest.fn().mockImplementation(
      (refPlayerInstance, audioButtonState, localState) =>{
        return {
          onPlayerActivate: jest.fn(),
          onPlayerDeactivate: jest.fn(),
          setupAudioPlayer: mockSetupPlayer,
        };
      }
    );
  }
);

jest.mock(
  'shared/vue/use_recording_player_setup',
  () => {
    return jest.fn().mockImplementation(
      (refPlayerInstance, refPlaybackButton, localState) => {
        return {
          initPlayer: jest.fn(),
          onPlayBackActivate: jest.fn(),
          onPlayBackDeactivate: jest.fn(),
          resetPlayerMediaButton: jest.fn(),
          setupAudioPlayBack: mockSetupAudioPlayback,
        };
      }
    );
  }
);

jest.mock(
  'shared/vue/use_recorder_setup',
  () => {
    return jest.fn().mockImplementation(
      (refRecorderInstance, localState) => {
        return {
          onRecorderActivate: jest.fn(),
          onRecorderDeactivate: jest.fn(),
          onRecorderVolume: jest.fn(),
          setupAudioRecorder: mockSetupAudioRecorder,
        };
      }
    );
  }
);


describe(
  'RecordingControlsManager',
  () => {
    const audio1Src = '/audio1.mp3';
    const baseDir = 'recording_v2/';
    const cdnPrefix = 'cdnPrefix';
    const mediaItemRecordingEndpoint = 'https://path/to/media_item/recording';

    const recordingConfig = {
      audioPromptSrc: audio1Src,
      baseDir: baseDir,
      cdnPrefix: cdnPrefix,
      endpoint: mediaItemRecordingEndpoint,
      hasCompareButton: false,
    };

    const recorderState = {
      isRecordingInProgress: false,
      playerState: 'disabled',
      recorderState: 'default',
      recordingCdnPrefix: cdnPrefix,
      recordingEndpoint: mediaItemRecordingEndpoint,
      recordingPath: '',
      useSpecifiedPathAsUrl: true,
    };

    const refCompareButton = { value: 'aaa' };
    const refPlaybackButton = { value: 'bbb' };

    function newRecordingControlsManager() {
      return new RecordingControlsManager(
        recorderState,
        recordingConfig,
        refCompareButton,
        refPlaybackButton
      );
    }

    let recordingControls;
    beforeEach(
      () => {
        recordingControls = newRecordingControlsManager();
      }
    );

    describe(
      'initRecordingControls',
      () => {
        it(
          'sets up a recording to allow creating a new recording',
          async () => {
            recordingControls.initRecordingControls();

            expect(mockSetupAudioRecorder).toHaveBeenCalledWith(
              {
                audioPromptSrc: audio1Src,
                baseDir: baseDir,
                cdnPrefix: cdnPrefix,
                endpoint: mediaItemRecordingEndpoint,
                hasCompareButton: false,
              }
            );
          }
        );

        it(
          'sets the audio play back to a blank source if there is no existing audio',
          async () => {
            recordingControls.initRecordingControls();

            expect(mockSetupAudioPlayback).toHaveBeenCalledWith('');
          }
        );

        it(
          'sets the audio play back to the url when there is a recording present',
          async () => {
            recorderState.recordingPath = '/recordingPath.mp3';
            recordingControls.initRecordingControls();

            expect(mockSetupAudioPlayback).toHaveBeenCalledWith('/recordingPath.mp3');
          }
        );

        it(
          'sets up audio player for the url of the existing audio when present',
          async () => {
            recordingControls.initRecordingControls();

            expect(mockSetupPlayer).toHaveBeenCalledWith(audio1Src);
          }
        );

        describe(
          'resetRecordingControls',
          () => {
            it(
              'sets the recordingPath to blank',
              () => {
                recorderState.recordingPath = 'something';
                recordingControls.resetRecordingControls();

                expect(recorderState.recordingPath).toBe('');
              }
            );

            it(
              'sets the refPlayerInstance value to null',
              () => {
                recordingControls.refPlayerInstance = { value: { is_playing: jest.fn() }};
                recordingControls.resetRecordingControls();

                expect(recordingControls.refPlayerInstance.value).toBe(null);
              }
            );

            it(
              'sets the player state to disabled',
              () => {
                recorderState.playerState = 'default';
                recordingControls.resetRecordingControls();

                expect(recorderState.playerState).toBe('disabled');
              }
            );

            it(
              'sets the disableDelete to true',
              () => {
                recorderState.disableDelete = false;
                recordingControls.resetRecordingControls();

                expect(recorderState.disableDelete).toBeTruthy();
              }
            );
          }
        );
      }
    );
  }
);
