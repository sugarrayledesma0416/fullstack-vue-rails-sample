import { elmFromString } from '../../support/utils.js';
import FormComponent from 'institution_admin/shared/form_component.js';

describe('FormComponent', () => {
  describe('setting displayed/visible', () => {
    let formComponent;

    beforeEach(() => {
      document.body.append(elmFromString(`
        <div class="js-foo">
          <div class="js-bar"></div>
        </div>
      `));

      formComponent = new FormComponent(document.querySelector('.js-foo'));
    });

    describe('#setDisplayed', () => {
      it('removes the u-hidden class if display = true', () => {
        formComponent.getElm('js-bar').classList.add('u-hidden');
        formComponent.setDisplayed('js-bar', true);
        expect(formComponent.getElm('js-bar')).not.toHaveClass('u-hidden');
      });

      it('adds the u-hidden class if display = false', () => {
        formComponent.setDisplayed('js-bar', false);
        expect(formComponent.getElm('js-bar')).toHaveClass('u-hidden');
      });
    });

    describe('#setVisible', () => {
      it('removes the u-invisible class if visible = true', () => {
        formComponent.getElm('js-bar').classList.add('u-invisible');
        formComponent.setVisible('js-bar', true);
        expect(formComponent.getElm('js-bar')).not.toHaveClass('u-invisible');
      });

      it('adds the u-invisible class if visible = false', () => {
        formComponent.setVisible('js-bar', false);
        expect(formComponent.getElm('js-bar')).toHaveClass('u-invisible');
      });
    });
  });
});
