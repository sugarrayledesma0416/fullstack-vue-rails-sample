<template>
  <span :class="iconModel.allClasses">
    <span ref="refSvgContainer" v-html="iconModel.iconSvg" />
    <span v-if="iconModel.text" class="c-embedded-icon__label">
      {{ iconModel.text }}
    </span>
    <span v-else class="u-screen-reader-only">
      {{ iconModel.defaultText }}
    </span>
  </span>
</template>

<script>
  import useMusicIconModel from './use_music_icon_model';
  import { onMounted, ref } from 'vue';

  /**
  * Note for this huge svg import list:-
  * This component would support & import all the SVGs eventually
  * (as per variant list MusicIconModel.VARIANTS/ DEPRECATED_VARIANTS).
  * And code for the same is included below.
  * But for optimization, only in-use icons are uncommented and imported.
  */
  import add from '!!raw-loader!MusicAssets/images/music/v1/icons/core/add.svg';
  import arrowDown from '!!raw-loader!MusicAssets/images/music/v1/icons/core/arrow-down.svg';
  // import arrowLeft from '!!raw-loader!MusicAssets/images/music/v1/icons/core/arrow-left.svg';
  // import arrowRight from '!!raw-loader!MusicAssets/images/music/v1/icons/core/arrow-right.svg';
  import arrowUp from '!!raw-loader!MusicAssets/images/music/v1/icons/core/arrow-up.svg';
  import audio from '!!raw-loader!MusicAssets/images/music/v1/icons/core/audio.svg';
  // import cancel from '!!raw-loader!MusicAssets/images/music/v1/icons/core/cancel.svg';
  // import cards from '!!raw-loader!MusicAssets/images/music/v1/icons/core/cards.svg';
  // import caret from '!!raw-loader!MusicAssets/images/music/v1/icons/core/caret.svg';
  import checkmark from '!!raw-loader!MusicAssets/images/music/v1/icons/core/checkmark.svg';
  import circleBack from '!!raw-loader!MusicAssets/images/music/v1/icons/core/circle-back.svg';
  import circleFront from '!!raw-loader!MusicAssets/images/music/v1/icons/core/circle-front.svg';
  import close from '!!raw-loader!MusicAssets/images/music/v1/icons/core/close.svg';
  // import comment from '!!raw-loader!MusicAssets/images/music/v1/icons/core/comment.svg';
  import copy from '!!raw-loader!MusicAssets/images/music/v1/icons/core/copy.svg';
  import deleteSvg from '!!raw-loader!MusicAssets/images/music/v1/icons/core/delete.svg';
  import edit from '!!raw-loader!MusicAssets/images/music/v1/icons/core/edit.svg';
  // import email from '!!raw-loader!MusicAssets/images/music/v1/icons/core/email.svg';
  import help from '!!raw-loader!MusicAssets/images/music/v1/icons/core/help.svg';
  import infoBlue
    from '!!raw-loader!MusicAssets/images/music/icons/flash-banners/icon-info-blue.svg';
  // import list from '!!raw-loader!MusicAssets/images/music/v1/icons/core/list.svg';
  // import logout from '!!raw-loader!MusicAssets/images/music/v1/icons/core/logout.svg';
  // import maximize from '!!raw-loader!MusicAssets/images/music/v1/icons/core/maximize.svg';
  // import minimize from '!!raw-loader!MusicAssets/images/music/v1/icons/core/minimize.svg';
  // import minus from '!!raw-loader!MusicAssets/images/music/v1/icons/core/minus.svg';
  import pause from '!!raw-loader!MusicAssets/images/music/v1/icons/core/pause.svg';
  import play from '!!raw-loader!MusicAssets/images/music/v1/icons/core/play.svg';
  import print from '!!raw-loader!MusicAssets/images/music/v1/icons/core/print.svg';
  import record from '!!raw-loader!MusicAssets/images/music/v1/icons/core/record.svg';
  import reference from '!!raw-loader!MusicAssets/images/music/v1/icons/core/reference.svg';
  import returnSvg from '!!raw-loader!MusicAssets/images/music/v1/icons/core/return.svg';
  // import save from '!!raw-loader!MusicAssets/images/music/v1/icons/core/save.svg';
  // import screen from '!!raw-loader!MusicAssets/images/music/v1/icons/core/screen.svg';
  import shuffle from '!!raw-loader!MusicAssets/images/music/v1/icons/core/shuffle.svg';
  import stop from '!!raw-loader!MusicAssets/images/music/v1/icons/core/stop.svg';
  // import tools from '!!raw-loader!MusicAssets/images/music/v1/icons/core/tools.svg';
  import user from '!!raw-loader!MusicAssets/images/music/v1/icons/core/user.svg';

  // This is map with key as supported icons variants, and value as loaded svg
  // For optimization, only in-use icons are uncommented and imported.
  // Rest of the code is included in commented format.
  const loadedSvgMap = {
    add,
    'arrow-down': arrowDown,
    // 'arrow-left': arrowLeft,
    // 'arrow-right': arrowRight,
    'arrow-up': arrowUp,
    audio,
    // cancel,
    // cards,
    // caret,
    checkmark,
    'circle-back': circleBack,
    'circle-front': circleFront,
    close,
    // comment,
    copy: copy,
    'delete': deleteSvg,
    edit,
    // email,
    help,
    // logout,
    // list,
    // maximize,
    // minimize,
    // minus,
    'info-blue': infoBlue,
    pause,
    play,
    print,
    record,
    reference,
    'return': returnSvg,
    // save,
    // screen,
    shuffle,
    stop,
    // tools,
    user,
  };

  const ALLOWED_VARIANTS = [
    'add',
    'arrow-right',
    'arrow-left',
    'arrow-up',
    'arrow-down',
    'audio',
    'cancel',
    'cards',
    'caret',
    'checkmark',
    'circle-back',
    'circle-front',
    'close',
    'comment',
    'copy',
    'delete',
    'edit',
    'email',
    'help',
    'info-blue',
    'list',
    'maximize',
    'minimize',
    'minus',
    'pause',
    'play',
    'print',
    'record',
    'reference',
    'return',
    'save',
    'screen',
    'shuffle',
    'stop',
    'tools',
    'user',
  ];
  const ALLOWED_DEPRECATED_VARIANTS = ['logout'];
  const ALLOWED_SIZES = ['sm', 'md', 'lg', 'xl'];

  export default {
    name: 'MusicIcon',
    props: {
      classes: {
        type: Array,
        default: [],
      },
      invert: {
        type: Boolean,
        default: false,
      },
      size: {
        type: String,
        default: 'md',
        validator: (value) => {
          return ALLOWED_SIZES.includes(value);
        },
      },
      text: String,
      variant: {
        type: String,
        required: true,
        validator: (value) => {
          return ALLOWED_VARIANTS.concat(ALLOWED_DEPRECATED_VARIANTS).includes(
            value
          );
        },
      },
    },
    setup(props) {
      const refSvgContainer = ref(null);
      const { getVariant, getModel } = useMusicIconModel(props);

      onMounted(() => {
        const svgElm = refSvgContainer.value?.querySelector('svg');
        svgElm?.classList.add('c-svg');
      });

      const {
        allClasses,
        defaultText,
        text,
        variant,
      } = getModel();

      return {
        iconModel: {
          allClasses,
          defaultText,
          iconSvg: loadedSvgMap[getVariant()],
          text,
          variant,
        },
        refSvgContainer,
      };
    },
  };
</script>
