// Based on https://googlechromelabs.github.io/howto-components/howto-label/
class GroupChatLabelStudent extends HTMLElement {
  constructor() {
    super();
    this.addEventListener('click', this._on_click);
  }

  static get observedAttributes() {
    return ['for', 'class'];
  }

  get for() {
    const value = this.getAttribute('for');
    return value === null ? '' : value;
  }

  set for(value) {
    this.setAttribute('for', value);
  }

  connectedCallback() {
    this._update_label();
  }

  attributeChangedCallback(name, old_value, new_value) {
    switch(name) {
      case 'for':
        this._update_label();
        break;
      case 'class':
        // The update to the class attribute done by handlebars, for some reason causes the current_target
        // query to return null, so we need to update the label to refresh the target element.
        this._update_label();
        var current_target = this.current_label_target();
        if (old_value !== new_value && current_target) {
          if (this.classList.contains('c-roster__username--available')){
            current_target.disabled = false;
          } else {
            current_target.disabled = true;
          }
        }
        break;
    }
  }

  _on_click(event) {
    let input_element = this.current_label_target();
    if (!input_element || event.target === input_element) {
      return;
    }
    input_element.focus();
    input_element.click();
  }

  // An id is required for the tag for this to work.
  current_label_target() {
    let scope = this.getRootNode();
    return scope.querySelector(`[aria-labelledby="${this.id}"]`);
  }

  _find_target() {
    if (this.for) {
      let scope = this.getRootNode();
      return scope.getElementById(this.for); 
    }
  }

  _update_label() {
    let old_target = this.current_label_target();
    let new_target = this._find_target();
    if (!new_target || old_target === new_target) {
      return;
    }
    if (old_target) {
      old_target.removeAttribute('aria-labelledby');
    }
    new_target.setAttribute('aria-labelledby', this.id);    
  }
}

customElements.define('group-chat-label-student', GroupChatLabelStudent)
