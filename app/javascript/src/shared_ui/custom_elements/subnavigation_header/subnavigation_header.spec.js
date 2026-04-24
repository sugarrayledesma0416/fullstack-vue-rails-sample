import M3SubnavigationHeader from './subnavigation_header';
import menuClasses from './_subnavigation_header.module.scss'
customElements.define('m3-subnavigation-header', M3SubnavigationHeader);
let wrapper;
let otherElements = `
    <sl-button>Blah</sl-button>
    <a>Blah</a>`;
let moreOptionsMenu = `
    <m3-more-options-menu>
      <sl-menu>
        <sl-menu-item>
          Option 1
        </sl-menu-item>
        <sl-menu-item>
          Option 2
        </sl-menu-item>
      </sl-menu>
    </m3-more-options-menu>
  `;
let menu

const headerTemplate = () => {
  wrapper = document.createElement('m3-subnavigation-header');
  wrapper.setAttribute('page-title', 'Page title');
  wrapper.setAttribute('description', 'Description');
  wrapper.setAttribute('title-id', 'page-title-id');
  wrapper.innerHTML = `
    ${moreOptionsMenu}
    ${otherElements}
  `;
  document.body.appendChild(wrapper)
}

beforeEach(() => {
  document.body.innerHTML = '';
  headerTemplate();
});

describe('M3SubnavigationHeader', () => {
  it('creates the component', () => { 
    expect(wrapper).toBeInstanceOf(M3SubnavigationHeader);
  });

  it('renders h1 with page-title', () => {
    expect(wrapper.querySelector('h1').textContent.trim()).toBe('Page title');
  });

  it('renders h1 with title-id', () => {
    expect(wrapper.querySelector('h1').getAttribute('id')).toBe('page-title-id');
  });

  it('renders p with description', () => {
    expect(wrapper.querySelector('p').textContent.trim()).toBe('Description');
  });

  it('renders more-options-menu', () => {
    expect(wrapper.querySelector('m3-more-options-menu')).not.toBe(null);
  });

  it('renders components to the left of m3-more-options-menu', () => {
    const moreMenu = wrapper.querySelector('m3-more-options-menu');
    const allHeaderChildren = Array.from(wrapper.querySelector('l-line-v3').children);
    expect(allHeaderChildren.map(el => el.tagName.toLowerCase()))
     .toEqual(['l-stack-v3', 'sl-button', 'a', 'm3-more-options-menu']);
  });
});
