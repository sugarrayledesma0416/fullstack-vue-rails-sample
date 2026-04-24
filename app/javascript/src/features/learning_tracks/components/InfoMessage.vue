<template>
  <div
    class="choose-template__warning"
    :style="{ backgroundColor: backgroundColor }"
  >
    <p class="info-message">
      <slot name="icon">
        <MusicIcon :variant="iconVariant" class="info-icon" v-if="iconVariant" />
      </slot>
      <slot>
        <span class="info-text">
          {{ message }}
        </span>
      </slot>
    </p>
  </div>
</template>

<script>
import MusicIcon from 'shared/vue/MusicIcon';

export default {
  name: 'InfoMessage',
  components: { MusicIcon },
  props: {
    message: {
      type: String,
      default: '',
    },
    iconVariant: {
      type: String,
      default: null,
    },
    backgroundColor: {
      type: String,
      default: '#E2EFFE',
    },
  }, 
};
</script>

<style scoped>
.choose-template__warning {
  color: #333;
  margin-top: 1rem;
  margin-bottom: 1rem;
  border-radius: 4px;
  font-size: 16px;
  line-height: 1.5;
  display: flex;
  align-items: center;
  font-family: "Open Sans";
}

.info-message {
  display: flex;
  align-items: center;
  padding: 1rem;
  border-radius: 0.25rem;
  gap: 0.5rem;
}

.info-icon {
  flex-shrink: 0;
  width: 24px;
  height: 24px;
}

.info-text {
  font-size: 1rem;
  line-height: 1.5;
  color: #333;
}
</style>
