import FlashcardLayout from 'features/dictionary_flashcards/FlashcardLayout';
import Deck from 'models/vocab_tools/deck';
import Word from 'models/vocab_tools/word';
import { createApp } from 'vue';

document.addEventListener('DOMContentLoaded', () => {
  const dataElm = document.querySelector('.js-dictionary-flashcards-rails-data');
  const railsData = JSON.parse(dataElm.getAttribute('data-from-dom'));

  const wordsData = JSON.parse(railsData.content_object).words;
  const words = wordsData.map((wordHash) => {
    return new Word(wordHash);
  });

  const deck = new Deck(words, 'words');

  const elm = document.querySelector('.js-dictionary-flashcards-app');
  const app = createApp(FlashcardLayout, {
    targetLanguage: railsData.language,
  });

  app.provide('deck', deck);
  app.mount(elm);
});
