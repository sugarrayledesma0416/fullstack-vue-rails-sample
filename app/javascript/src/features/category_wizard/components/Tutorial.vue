<template>
  <div
    v-show="tutorial.store.showGettingStarted"
    ref="gradebookExplanation"
    class="tutorial__gradebook-explanation">
    <div class="tutorial__explanation-inner">
      <div class="tutorial__explanation-title" :class="testClass('tutorial-title')">
        What is a category?
      </div>

      <ul class="tutorial__gradebook-examples">
        <li
          v-for="example in tutorial.examples"
          :key="example"
          :ref="el => { gradebookExamples[example.css] = el }"
          cw-lightbox
          class="tutorial__gradebook-example">
          <div class="tutorial__instructions" :class="testClass(`instructions-${example.css}`)">
            {{ example.text }}
          </div>
          <div :ref="el => { lightboxImages[example.css] = el }" class="tutorial__lightbox-image">
            <img
              :src="example.image"
              class="tutorial__cat-lightbox-image"
              :class="testClass(`lightbox-image-${example.css}`)">
          </div>
          <div
            :ref="el => { zoomedImages[example.css] = el }"
            class="tutorial_zoomed-image  u-hidden"
            :class="[
              `tutorial_zoomed-image-${example.css}`,
              testClass(`zoomed-image-${example.css}`)
            ]">
            <div
              :ref="el => { closeBtns[example.css] = el }"
              class="tutorial__close-zoom">
              close
            </div>
            <img :src="example.zoomedImage" class="cat-lightbox-image-zoomed">
          </div>
        </li>
      </ul>

      <div class="tutorial__category-start-btn">
        <StandardButton
          v-if="tutorial.store.active"
          variant="primary"
          @click="tutorial.getStarted()">
          Get started
        </StandardButton>
      </div>
    </div>
  </div>
</template>

<script>
  import { StandardButton, testClass } from 'music';
  import { inject, onMounted, ref } from 'vue';

  export default {
    name: 'Tutorial',
    components: { StandardButton },
    setup() {
      const closeBtns = ref([]);
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');
      const gradebookExamples = ref([]);
      const gradebookExplanation = ref(null);
      const lightboxImages = ref([]);
      const tutorial = inject('tutorial');
      const zoomedImages = ref([]);

      /**
       * Add Zoom Image Event.
       * @param {HTMLElement} elm
       * @param {Number} index
       */
      const addImageZoomEvent = function(elm, index) {
        const lightboxImage = lightboxImages.value[index];
        const closeImage = closeBtns.value[index];
        const zoomedImage = zoomedImages.value[index];

        // Clicking on an image opens up the larger image.
        lightboxImage.addEventListener('click', function() {
          gradebookExplanation.value.insertAdjacentHTML(
            'beforeend',
            '<div class="ui-widget-overlay  js-zoom-blocker"></div>'
          );
          zoomedImage.classList.remove('u-hidden');

          document.querySelector('.js-zoom-blocker')?.addEventListener('click', function() {
            zoomedImage.classList.add('u-hidden');
            document.querySelector('.js-zoom-blocker')?.remove();
          });
        });

        // Clicking the "X" closes the image.
        closeImage.addEventListener('click', function() {
          zoomedImage.classList.add('u-hidden');
          document.querySelector('.js-zoom-blocker').remove();
        });
      };

      onMounted(() => {
        for (const index in gradebookExamples.value) {
          if (Object.prototype.hasOwnProperty.call(gradebookExamples.value, index)) {
            addImageZoomEvent(gradebookExamples.value[index], index);
          }
        }
      });

      return {
        closeBtns,
        config,
        courseDataStore,
        gradebookExamples,
        gradebookExplanation,
        lightboxImages,
        testClass,
        tutorial,
        zoomedImages,
        StandardButton,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  @import '~MusicAssets/stylesheets/music/library/v1/parts/utilities';

  .tutorial__cat-lightbox-image {
    border: rpx(1) solid #D3D3D3;
    box-shadow: rpx(2) rpx(2) rpx(5) 0 #d3d3d3;
    cursor: pointer;
    display: block;
    height: rpx(267);
    width: rpx(225);
  }

  .tutorial__category-start-btn {
    padding: 1rem;
    text-align: right;
  }

  .tutorial__close-zoom {
    background: url(/images/dialog_close_small.png) top right no-repeat;
    cursor: pointer;
    display: block;
    height: 1.25rem;
    overflow: hidden;
    position: absolute;
    right: rpx(-10);
    text-indent: -999em;
    top: rpx(-10);
    width: 1.25rem;
    z-index: 2502;
  }

  .tutorial__container {
    padding-bottom: rpx(10);
    text-align: right;
  }

  .tutorial__explanation {
    height: rpx(445);
    left: 0;
    position: absolute;
    width: rpx(900);
    z-index: 100;
  }

  .tutorial__explanation-title {
    color: #565656;
    font-size: rpx(12);
    font-weight: bold;
    line-height: rpx(14);
    padding: rpx(10) rpx(18);
  }

  .tutorial__gradebook-examples {
    margin-bottom: mod(1.5);
    padding-top: mod(1);
  }

  .tutorial__gradebook-example {
    display: inline-block;
    position: relative;
    max-width: mod(19);
    vertical-align: top;
    margin-right: 2rem;
    padding-left: 0;
  }

  .tutorial__instructions {
    font-size: rpx(12);
    height: rpx(30);
    line-height: rpx(14);
    margin-bottom: rpx(10);
    margin-left: rpx(18);
    vertical-align: top;
  }

  .tutorial__lightbox-image {
    background: url(/images/lightbox-category-bg.png) rpx(14) 0 no-repeat;
    height: 17.5rem;
    padding-left: rpx(18);
    padding-top: rpx(7);
    position: relative;
  }

  .tutorial_zoomed-image {
    box-shadow: $box-shadow-1;
    height: rpx(290);
    left: rpx(-150);
    position: absolute;
    top: 0;
    width: rpx(531);
    z-index: 2500;
  }

  .tutorial_zoomed-image-grade {
    left: rpx(-442);
  }

  .tutorial_zoomed-image-toc {
    left: rpx(142);
  }
</style>
