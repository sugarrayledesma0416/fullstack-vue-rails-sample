import { createApp } from 'vue';
import ComponentWithSubcomponents from './ComponentWithSubcomponents';

document.addEventListener('DOMContentLoaded', () => {
  const componentWithSubcomponents = createApp(ComponentWithSubcomponents);
  const vm = componentWithSubcomponents.mount('#component_with_subcomponents');
});
