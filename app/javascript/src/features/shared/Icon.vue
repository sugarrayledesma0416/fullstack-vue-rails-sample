<template>
  <span
    ref="container"
    class="c-embedded-icon"
    :class="iconClasses"
    v-html="svg" />
</template>

<script>
  import { onMounted, reactive, ref } from 'vue';
  const ALLOWED_SIZES = ['', 'sm', 'md', 'lg', 'xl', 'xxl'];

  export default {
    name: 'Icon',
    props: {
      svg: String,
      size: {
        default: '',
        type: String,
        validator: (value) => {
          return ALLOWED_SIZES.includes(value);
        },
      },
    },
    setup(props) {
      /**
       * NOTE: `container` has to be defined in the scope of this function for it
       *       to be scoped to each instance of the component.
       *
       *       I originally placed it in the scope of `<script>`, before the
       *       `export default...`, and found that the 'c-svg' class was added
       *       only in the last instance of the component (because there was only
       *       one copy of `container` across all instances).
       */
      const container = ref(null);
      const iconClasses = reactive([]);

      onMounted(function() {
        const svgElm = container.value.querySelector('svg');
        svgElm.classList.add('c-svg');

        if (props.size !== '') {
          iconClasses.push(`c-embedded-icon--${props.size}`);
        }
      });

      return { container, iconClasses };
    },
  };
</script>

<style lang="scss" scoped>
  .c-embedded-icon--sm::v-deep(svg) {
    width: 0.75rem;
    height: 0.75rem;
    line-height: 0.75rem;
    background-size: 0.75rem 0.75rem;
  }

  .c-embedded-icon--md::v-deep(svg) {
    width: 1rem;
    height: 1rem;
    line-height: 1rem;
    background-size: 1rem 1rem;
  }

  .c-embedded-icon--lg::v-deep(svg) {
    width: 1.5rem;
    height: 1.5rem;
    line-height: 1.5rem;
    background-size: 1.5rem 1.5rem;
  }

  .c-embedded-icon--xl::v-deep(svg) {
    width: 2rem;
    height: 2rem;
    line-height: 2rem;
    background-size: 2rem 2rem;
  }

  .c-embedded-icon--xxl::v-deep(svg) {
    background-size: 4rem 4rem;
    height: 4rem;
    line-height: 4rem;
    width: 4rem;
  }
</style>
