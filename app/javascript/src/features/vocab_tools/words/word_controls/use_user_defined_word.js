import { metaTagContent } from 'shared/utils';

const useUserDefinedWord = () => {
  const metaData = {
    targetLanguageCode: metaTagContent('VHL.program_language'),
    programId: metaTagContent('VHL.program_id'),
  };

  const registerAccentBar = (accentBar) => {
    document.querySelectorAll('.js-word-form-input').forEach((inputElm) => {
      accentBar.register(inputElm);
    });
  };

  const attachToAccentBarEvents = (inputSelectors, word) => {
    const targetWordElm = document.querySelector(inputSelectors.target);
    const translationWordElm = document.querySelector(inputSelectors.translation);
    const definitionWordElm = document.querySelector(inputSelectors.definition);

    $(targetWordElm).on('accented_character_added', () => {
      word.new_target = targetWordElm.value;
    });

    $(translationWordElm).on('accented_character_added', () => {
      word.new_translation = translationWordElm.value;
    });

    $(definitionWordElm).on('accented_character_added', () => {
      word.new_definition = definitionWordElm.value;
    });
  };

  const detachFromAccentBarEvents = (inputSelectors) => {
    const targetWordElm = document.querySelector(inputSelectors.target);
    const translationWordElm = document.querySelector(inputSelectors.translation);
    const definitionWordElm = document.querySelector(inputSelectors.definition);

    // detaching from jquery event
    $(targetWordElm).off('accented_character_added');
    $(translationWordElm).off('accented_character_added');
    $(definitionWordElm).off('accented_character_added');
  };

  const showPinyin = (metaData.targetLanguageCode === 'zh');

  return {
    attachToAccentBarEvents,
    detachFromAccentBarEvents,
    metaData,
    registerAccentBar,
    showPinyin,
  };
};

export default useUserDefinedWord;
