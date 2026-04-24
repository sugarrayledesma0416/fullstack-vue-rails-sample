<template>
  <div 
    class="c-row  c-row--vocab-tools  add-zone--print  js-add-zone"
    :class="{'u-bord-radius-8': ssjrStudent}">
    <div 
      class="u-no-max-width"
      :class="{ 'u-bord-bot-0': ssjrStudent }">
      <button
        type="button"
        :aria-label="`Add Word to ${lesson.name}`"
        :aria-controls="`a11y-add-user-word-form-${unit.id}-${lesson.id}`"
        class="c-no-button  is-navigable  u-dis-flex  flex-justify-start"
        :class="[
          `js-lesson-${lesson.id}-add-word`,
          testClass(`lesson-${lesson.id}-add-word`),
          { 'u-txt-upper': !ssjrStudent },
        ]"
        @click="$emit('showAddWord', { lesson })">
        <MusicIcon variant="add" size="md" class="u-pad-rt-8" aria-hidden="true" />  Add Word
      </button>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  import MusicIcon from 'shared/vue/MusicIcon';

  export default {
    name: 'AddWordIcon',
    components: { MusicIcon },
    props: {
      lesson: { required: true, type: Object },
      ssjrStudent: { default: false, type: Boolean },
      unit: { required: true, type: Object },
    },
    emits: ['showAddWord'],
    setup(props, { emit }) {
      return { testClass };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-no-button {
    margin-left: rpx(-8);

    @include viewport-min('sm') {
      margin-left: rpx(-24);
    }
  }
</style>
