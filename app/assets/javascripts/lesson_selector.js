var VHL = VHL || {};
VHL.LessonSelector = VHL.LessonSelector || {};

VHL.LessonSelector.Dropdowns = {
  init: function (dropdownElement) {

    //Get Menu Option list which are focusable. Header of multi selector unit are non-focusable therefore kept out of the list.
    var menuOption = dropdownElement.find(".js-ls-dropdown-list-item:not(.js-ls-dropdown--multilesson-header)");
    var menuItemList = dropdownElement.find(".js-ls-dropdown-list");

    var current = dropdownElement.find(".js-current");
    var disclosure = dropdownElement.find(".js-disclosure");
    var currentIndex = -1;

    var links = dropdownElement.find('a');

    var KEY_CODES = {
      ENTER: 13,
      TAB: 9,
      ESCAPE: 27,
      SPACE: 32,
      UP_ARROW: 38,
      DOWN_ARROW: 40
    };

    attachLinksEventHandlers();
    attachMenuOptionEventHandlers();
    selectDefaultElement();

    // Get if theme is t-vol
    var is_vol = $('body').hasClass('t-vol');

    function selectDefaultElement() {
      var selectedElement = menuItemList.find("[data-selected='true']");
      if (selectedElement.length < 1) {
        selectedElement = links.eq(0);
      }

      // Add Selected item styles
      selectedElement.addClass("is-selected");
      selectedElement.addClass("is-target");

      selectCurrentMenuOption(selectedElement);
    }


    /*
    Setting max height of the dropdown on window resize.
    1. windowHeight is calculating the total height of the window
    2. elTopHeight is calculating the height from the top of the window plus total width of the element
    3. dropdownHeight is calculating the height of the dropdown to be opened according to the size of the window
     */
    function setMaxHeight() {
      var windowHeight = document.documentElement.clientHeight;
      var $dropdown = button.closest(".js-ls-dropdown");
      var elTopHeight = $dropdown.offset().top + $dropdown.outerHeight(true);
      var dropdownMaxHeight = windowHeight - elTopHeight - 32;
      menuItemList.css("max-height", dropdownMaxHeight);
    }

    function attachLinksEventHandlers() {
      links.each((index, link) => {
        $(link).on('click', (event) => {
          event.preventDefault;
          current.html(event.target.html());
          current.attr('lang', event.target.attr('lang'));
          disclosure.removeAttr('open');

          current.focus();
        });

        $(link).on('keydown', (event) => {
          if (event.keyCode === KEY_CODES.ESCAPE) {
            disclosure[0].removeAttribute('open');
            current[0].focus();
            event.preventDefault();
          }

          if (event.keyCode === KEY_CODES.DOWN_ARROW) {
            if (currentIndex === links.length - 1) {
              currentIndex = -1;
              current.focus();
            } else {
              currentIndex++;
              links.eq(currentIndex).focus();
            }
            event.preventDefault();
          }

          if (event.keyCode === KEY_CODES.UP_ARROW) {
            if (currentIndex === 0) {
              currentIndex = -1;
              current.focus();
            } else {
              currentIndex--;
              links.eq(currentIndex).focus();
            }
            event.preventDefault();
          }

          if (event.keyCode === KEY_CODES.TAB) {
            const linkEls = links.get();
            const firstLink = linkEls[0];
            const lastLink = linkEls[linkEls.length - 1];

            if (event.shiftKey && event.target === firstLink) {
              lastLink.focus();
              event.preventDefault();
            } else if (!event.shiftKey && event.target === lastLink) {
              firstLink.focus();
              event.preventDefault();
            }
          }
        });
      });

      current.keydown((event) => {
        if (event.keyCode === KEY_CODES.ENTER || event.keyCode === KEY_CODES.SPACE) {
          disclosure[0].setAttribute('open', '');

          const selectedOption = Array.from(menuOption.get()).find(
            el => el.getAttribute('data-selected') === 'true'
          );
          if (selectedOption) {
            const selectedLink = selectedOption.querySelector('a');
            if (selectedLink) {
              selectedLink.focus();
              currentIndex = links.get().indexOf(selectedLink);
            }
          } else {
            const linkEls = links.get();
            if (linkEls.length > 0) {
              linkEls[0].focus();
              currentIndex = 0;
            }
          }

          event.preventDefault();
        }

        if (event.keyCode === KEY_CODES.DOWN_ARROW) {
          disclosure.attr('open', '');
          links.first().focus();
          currentIndex = 0;
          event.preventDefault();
        }

        if (event.keyCode === KEY_CODES.UP_ARROW) {
          disclosure.attr('open', '');
          links.eq(links.length - 1).focus();
          currentIndex = links.length - 1;
          event.preventDefault();
        }
      });

      // Lesson selector should close when user clicks anywhere else in the page
      $(document).click((event) => {
        if (!$(event.target).closest(disclosure). length) {
          disclosure.removeAttr('open');

          var $icon = current.find('.js-disclosure-icon');
          $icon.removeClass('c-icon--up-arrow');
          $icon.addClass('c-icon--down-arrow');
        }
      });

      disclosure.on('click', (event) => {
        showArrow();
        event.stopPropagation();
      });
    }

    function showArrow() {
      var hasAttrOpen = disclosure.attr('open') !== undefined;

      // Switch the arrow icon
      var $icon = current.find('.js-disclosure-icon');
      if (hasAttrOpen) {
        $icon.removeClass('c-icon--up-arrow');
        $icon.addClass('c-icon--down-arrow');
      } else {
        $icon.removeClass('c-icon--down-arrow');
        $icon.addClass('c-icon--up-arrow');
      }
    }

    /*
    Attach event handlers for Option Item
    1. Select the highlighted option when user clicks on it
    */
    function attachMenuOptionEventHandlers() {
      menuOption.click(function (e) {
        selectSubMenuAndRedirect($(this));
      });
    }

    /*
    Utility Function to Select the Option Element passed as paramter and redirect it to that Lesson
    */
    function selectSubMenuAndRedirect(optionElement) {
      // In case the target element is not already selected
      if (optionElement.attr("data-selected") != "true") { 
        menuOption.attr("data-selected", "false");
        optionElement.attr("data-selected", "true");
        window.location.href = button.find(".js-ls-dropdown-button-item").attr("selectedValue");
      } 
    }

    function selectCurrentMenuOption(selectedOption) {
      const currentElement = current[0];
      const selectedItem = selectedOption[0].querySelector('.js-ls-dropdown-list-item-data');
      if (!selectedItem) return;

      const clonedContent = selectedItem.cloneNode(true);
      clonedContent.querySelectorAll('a.c-ls-dropdown__list-item-text').forEach(a => {
        const span = document.createElement('span');
        span.className = a.className;
        if (a.hasAttribute('lang')) span.setAttribute('lang', a.getAttribute('lang'));
        span.innerHTML = a.innerHTML;
        a.replaceWith(span);
      });

      currentElement.innerHTML = '';
      while (clonedContent.firstChild) {
        currentElement.appendChild(clonedContent.firstChild);
      }

      const selectedLink = selectedItem.querySelector('.c-ls-dropdown__list-item-text');
      if (selectedLink && selectedLink.hasAttribute('lang')) {
        currentElement.setAttribute('lang', selectedLink.getAttribute('lang'));
      } else {
        currentElement.removeAttribute('lang');
      }

      const arrow = document.createElement('span');
      arrow.className = 'c-icon--lg c-icon--down-arrow c-ls-dropdown__button-arrow js-disclosure-icon';
      currentElement.appendChild(arrow);
      currentElement.focus();
    }
  }
};

$(document).ready(function () {
  var $dropdownContainer = $(".js-ls-dropdown");
  if ($dropdownContainer.length > 0) {
    VHL.LessonSelector.Dropdowns.init($dropdownContainer);
  }
});
