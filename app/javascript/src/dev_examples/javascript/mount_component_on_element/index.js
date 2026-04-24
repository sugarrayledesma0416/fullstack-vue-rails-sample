import { createApp } from 'vue';
import ComponentMountedOnElement from './ComponentMountedOnElement';

document.addEventListener('DOMContentLoaded', () => {
  const componentMountedOnElement = createApp(ComponentMountedOnElement);
  const vm = componentMountedOnElement.mount('#component_mounted_on_element');
});
