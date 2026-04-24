/** For reference: This composable is ported from music/app/models/music/components/icon.rb */

/**
 * This composable has logic and properties/methods for rendering icon component's html.
 * @param {Object} props vue js props object.
 * @return {Object} an object wrapping following methods
 * getVariant,
 * getModel,
 */
const useMusicIconModel = (props) => {
  const getVariant = () => props.variant;

  const getText = () => {
    if (props.text == 'default') {
      return getDefaultText();
    } else {
      return props.text;
    }
  };

  const getDefaultText = () => {
    return capitalize(props.variant);
  };

  const capitalize = (text) => {
    return text.charAt(0).toUpperCase() + text.slice(1);
  };

  const getAllClasses = () => {
    const base = 'c-embedded-icon';
    const arr = [];
    arr.push(base);
    if (props.variant) {
      arr.push(`${base}--${props.variant}`);
    }

    arr.push(`${base}--${props.size}`);

    if (props.invert) {
      arr.push(`${base}--inverted`);
    }

    if (props.classes.length) {
      arr.push(...props.classes);
    }

    return arr.join('  ');
  };

  /* This method returns object with keys used in icon component's html template */
  const getModel = () => {
    return {
      allClasses: getAllClasses(),
      defaultText: getDefaultText(),
      text: getText(),
      variant: getVariant(),
    };
  };

  return {
    getVariant,
    getModel,
  };
};

export default useMusicIconModel;
