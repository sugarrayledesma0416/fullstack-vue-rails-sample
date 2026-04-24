<template>
  <div v-if="show" class="c-modal-overlay">
    <div class="c-modal-container">
      <button 
        v-if="errorMessage" 
        class="c-modal-close-button u-txt-black u-pos-abs" 
        @click="onClose" 
        aria-label="Close modal">
        <music-icon-close size="sm" style="height: 100%; width: 100%;" />
      </button>
      <div class="c-icon-container" v-if="!errorMessage">
        <music-icon-double-black-star size="xxl" style="height: 100%; width: 100%;" />
      </div>

      <h2 :class="['c-modal-title', { 'u-txt-20': errorMessage }]">
        {{ errorMessage ? "Error" : "AI Suggestions Generating..." }}
      </h2>

      <p :class="['c-modal-text', { 'u-txt-16': errorMessage }]">
        {{ errorMessage || "Analyzing student answers and creating feedback." }}
      </p>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  show: {
    type: Boolean,
    required: true
  },
  errorMessage: {
    type: String,
    default: null
  }
});

const emit = defineEmits(['close']);

const onClose = () => {
  emit('close');
};
</script>

<style scoped>
.c-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.c-modal-container {
  position: relative;
  background: radial-gradient(circle at 80% -50%, #f8c7b9, #fcdfcd, #faffe5, #e1f6ef);
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0px 10px 20px rgba(0, 0, 0, 0.15);
  text-align: center;
  z-index: 10000;
}

.c-modal-close-button {
  top: 10px;
  right: 16px;
  background: none;
  border: none;
  font-size: 2rem;
  color: #333;
  cursor: pointer;
  line-height: 1;
  z-index: 10001;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.2); }
  100% { transform: scale(1); }
}

.c-icon-container music-icon-double-black-star {
  animation: pulse 1.5s infinite ease-in-out;
}
</style>