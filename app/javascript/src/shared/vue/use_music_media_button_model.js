/** For reference: This file is ported from music/app/models/music/components/media_button.rb */

/**
 * This composable has logic and methods for rendering media button component's html.
 * @param {Object} props vue js props object.
 * @return {Object} an object wrapping following method(s)
 * getModel,
 */
const useMusicMediaButtonModel = (props) => {
  const { getText } = useMediaButtonTextHelper(props);

  const getState = () => props.state;

  const getVariant = () => props.variant;

  const getSize = () => props.size;

  const getToggle = () => props.toggle;

  const hasVolume = () => {
    return props.volume ? true : false;
  };

  const getStateClass = () => {
    const stateToClass = {
      loading: 'is-loading',
      active: 'is-active',
      default: 'is-navigable',
      hidden: 'u-hidden',
      // disabled state doesn't use a class
    };
    return stateToClass[props.state];
  };

  const getToggleClass = () => {
    const stateToClass = {
      stop: 'c-media-button--stop',
      pause: 'c-media-button--pause',
      // No toggle class for the default
    };
    return stateToClass[props.toggle];
  };

  const getToggleIconSm = () => {
    return getToggle();
  };

  const getIconVariant = () => {
    // Maps between Media Button and Icon variant names
    const iconVariantMap = {
      listen: 'audio',
      review: 'user',
      correct: 'checkmark',
      speak: 'record',
      record: 'record',
      pause: 'pause',
    };
    const defaultVariant = 'play';
    const iconVariant = iconVariantMap[props.variant];
    return iconVariant || defaultVariant;
  };

  const announceStateChange = () => {
    return props.variant == 'speak' || props.variant == 'record';
  };

  const getClasses = () => props.classes.join('  ');

  /* This method returns object with keys used in media button component's html template */
  const getModel = () => {
    return {
      announceStateChange: announceStateChange(),
      classes: getClasses(),
      hasVolume: hasVolume(),
      iconVariant: getIconVariant(),
      size: getSize(),
      state: getState(),
      stateClass: getStateClass(),
      text: getText(),
      toggle: getToggle(),
      toggleClass: getToggleClass(),
      toggleIconSm: getToggleIconSm(),
      variant: getVariant(),
    };
  };

  return {
    getModel,
  };
};

/**
 * This composable has logic and methods for rendering media button component's text.
 * @param {Object} props vue js props object.
 * @return {Object} an object wrapping following method(s)
 * getText,
 * getDefaultTextBySize,
 * getDefaultText,
 */
const useMediaButtonTextHelper = (props) => {
  const getText = () => {
    let textVal;

    // Maps between Media Button and Icon variant names
    switch (props.text) {
    case null:
    case undefined:
      textVal = getDefaultTextBySize();
      break;
    case 'default':
      textVal = getDefaultText();
      break;
    case 'none':
      textVal = null;
      break;
    case 'speak':
    case 'record':
      textVal = 'record';
      break;
    default:
      textVal = props.text;
      break;
    }

    return textVal;
  };

  const getDefaultTextBySize = () => {
    return props.size == 'md' ? getDefaultText() : '';
  };

  const getDefaultText = () => {
    return humanize(props.variant);
  };

  const humanize = (text) => {
    // Turn underscores and dashes into spaces
    text = text.replace(/[-_]/g, ' ');
    // Capitalizes the first word
    text = text.charAt(0).toUpperCase() + text.slice(1);
    return text.trim();
  };

  return {
    getText,
    getDefaultTextBySize,
    getDefaultText,
  };
};

export default useMusicMediaButtonModel;
