import { mountVueAppOnElm } from 'shared/utils/vue';
import DefaultAudioIcon from './DefaultAudioIcon.vue';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(DefaultAudioIcon, '#default_audio_icon');
});
