const updateFunc = (elm, vnode, ckeditorInstance) => {
  elm.value = ckeditorInstance.getData();
  vnode.el.dispatchEvent(new CustomEvent('input'));
};

export default {
  mounted(elm, binding, vnode) {
    CKEDITOR.env.isCompatible = true;
    const ckeditorInstance = CKEDITOR.replace(elm, binding.value);
    if (ckeditorInstance) {
      ckeditorInstance.on('key', () => updateFunc(elm, vnode, ckeditorInstance));
      ckeditorInstance.on('change', () => updateFunc(elm, vnode, ckeditorInstance));
      ckeditorInstance.on('dataReady', () => updateFunc(elm, vnode, ckeditorInstance));
      ckeditorInstance.on('pasteState', () => updateFunc(elm, vnode, ckeditorInstance));
    }
  },
};

