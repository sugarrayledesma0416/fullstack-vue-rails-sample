// @ts-check

export class MyCustomElement extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.render();
  }

  render() {
    if (this.shadowRoot === null) {
      return;
    }
    this.shadowRoot.innerHTML = `
      <div>
        <h1>Hello from MyCustomElement!</h1>
        <p>This is a custom web component.</p>
      </div>
    `;
  }
}
