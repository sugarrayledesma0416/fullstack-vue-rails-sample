import { mount } from '@vue/test-utils';
import ShareActivitiesApp from 'features/created_activities/ShareActivitiesApp.vue';

describe('ShareActivitiesApp', () => {
  const draftActivityID = '9099';
  const privateActivityID = '9199';
  const sharedActivityID = '9299';
  const activityIDs = [draftActivityID, privateActivityID, sharedActivityID];
  const props = {
    activityData: [
      { id: draftActivityID, shared: false, draft: true },
      { id: privateActivityID, shared: false, draft: false },
      { id: sharedActivityID, shared: true, draft: false },
    ],
    programID: '340',
  };

  let metaTag;
  let wrapper;
  let div;
  let linksWrapper;
  let sharedActivityLink;
  let privateActivityLink;
  let modal;
  let updateButton;
  let cancelButton;
  let selector;

  beforeEach( ()=> {
    metaTag = document.createElement('meta');
    metaTag.setAttribute('name', 'csrf-token');
    metaTag.setAttribute('content', 'abc');
    document.head.appendChild(metaTag);
    div = document.createElement('div');
    document.body.appendChild(div);
    linksWrapper = document.createElement('ul');
    activityIDs.forEach( (id) => {
      const item = document.createElement('li');
      item.id = `share_activity_${id}`;
      linksWrapper.appendChild(item);
    });
    document.body.appendChild(linksWrapper);
    wrapper = mount(ShareActivitiesApp, { props, attachTo: div });

    privateActivityLink = document.getElementById(`js-share-id-${privateActivityID}`);
    sharedActivityLink = document.getElementById(`js-share-id-${sharedActivityID}`);
  });

  afterEach( ()=> {
    document.body.innerHTML = '';
  });

  it('renders share links for non draft activities', ()=> {
    const links = linksWrapper.querySelectorAll('a');
    expect(links.length).toBe(2);
  });

  describe('ShareActivityModal', () => {
    it('shows the modal after clicking the manage share link', async ()=> {
      await privateActivityLink.click();
      modal = wrapper.get('.dialog-block--modal').element;
      expect(modal).toBeVisible();
    });

    it('closes the modal after clicking the cancel button', async ()=> {
      await privateActivityLink.click();
      cancelButton = wrapper.get('#cancel-button').element;
      await cancelButton.click();
      modal = document.querySelector('.dialog-block--modal');
      expect(modal).toBeFalsy();
    });

    it('shows a selector with the share options', async ()=> {
      await privateActivityLink.click();
      selector = wrapper.get('#share-selector').element;
      expect(selector).toBeVisible();
    });

    it('shows the current share status as the default option', async () =>{
      await sharedActivityLink.click();
      selector = wrapper.get('#share-selector').element;
      expect(selector.value).toBe('share');
    });

    it('shows the update button disabled by default', async () => {
      await privateActivityLink.click();
      updateButton = wrapper.get('#update-button').element;
      expect(updateButton).toBeDisabled();
    });

    it('enables the update button after changing the selector to an applicable action', async () => {
      await privateActivityLink.click();
      const options = wrapper.get('#share-selector').findAll('option');
      updateButton = wrapper.get('#update-button').element;
      await options[0].setSelected();
      expect(updateButton).not.toBeDisabled();
    });
  });
});


