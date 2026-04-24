<template>
  <div ref="refRootElm" class="gear-menu-container">
    <VhlLink
      :class="testClass('gear-menu-opener')"
      href="javascript://"
      :title="linkText"
      @click="localStore.showMenu = !localStore.showMenu">
      {{ linkText }}
    </VhlLink>
    <div
      v-show="localStore.showMenu"
      class="gear-menu  category-options"
      :class="testClass('gear-menu')">
      <div
        v-for="(item, index) in menuItems"
        :key="index">
        <VhlLink
          :class="testClass('gear-menu-item')"
          :disabled="item.disabled"
          href="javascript://"
          :title="linkText"
          @click="onItemClick($event, item)">
          {{ item.text }}
        </VhlLink>
      </div>
    </div>
  </div>
</template>

<script>
  import { onMounted, reactive, ref } from 'vue';
  import { testClass } from 'music';
  import VhlLink from 'features/learning_tracks/components/VhlLink';

  /**
   * @typeDef GearMenuItem
   * @property {string} id - identifier for the menu item
   * @property {string} text - text of the menu item
   * @property {boolean} disabled - whether menu item is disabled
   */

  export default {
    name: 'GearMenu',
    components: { VhlLink },
    props: {
      menuItems: { default: () => [], type: Array },
      linkText: { default: '', type: String },
    },
    emits: ['click'],
    setup(props, { emit }) {
      const refRootElm = ref(null);
      const localStore = reactive({
        showMenu: false,
      });

      /**
       * This method hides menu and emits click event for enabled item
       * @param {Event} event
       * @param {GearMenuItem} item
       */
      function onItemClick(event, item) {
        if (!item.disabled) {
          localStore.showMenu = false;
          emit('click', item);
        }
      }

      /* Attach event to hide gear menu when click happens outside. */
      onMounted(function() {
        document.addEventListener('click', function(event) {
          if (localStore.showMenu && !refRootElm.value?.contains(event.target)) {
            localStore.showMenu = false;
          }
        });
      });

      return { localStore, onItemClick, refRootElm, testClass };
    },
  };
</script>
<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .gear-menu-container {
    display: inline-block;
    float: left;
    position: relative;
  }
  .gear-menu {
    background: #FFF;
    border: rpx(1) solid #bdbdbd;
    display: block;
    width: rpx(125);
    font-size: rpx(10);
    position: absolute;
    padding: rpx(5);
    top: rpx(24);
    right: rpx(9);
    z-index: z(menu);
  }
  .gear-menu.category-options {
    left: rpx(-1);
    top: rpx(19);
    width: rpx(100);
  }
</style>
