$(document).ready(function() {

   /*
    * jQuery accessible and keyboard-enhanced navigation with dropdown
    * Website: http://a11y.nicolas-hoffmann.net/subnav-dropdown/
    * License MIT: https://github.com/nico3333fr/jquery-accessible-subnav-dropdown/blob/master/LICENSE
    */
   // loading expand paragraphs
   var $nav_system = $('.js-nav-system'),
       $body = $('body');
   if ($nav_system.length) { // if there is at least one :)

      // initialization
      var $nav_system_link = $('.js-nav-system__link');
      
      $nav_system_link.each(function(index_to_expand) {
         var $this = $(this),
             index_lisible = index_to_expand + 1,
             $parent_item = $this.parents('.js-nav-system__item'),
             $subnav = $this.next('.js-nav-system__subnav');

         // if there is a subnav adjacent to the link
         if ($subnav.length === 1) {
            showSubMenu($parent_item, false);
         }
      });

   }
    function showSubMenu(element, bShowSubMenu) {
        var label=element.find(".js-nav-system__link");
        var subMenu = element.children(".js-nav-system__subnav");
	    if (bShowSubMenu) {
            label.attr('aria-expanded','true');
            subMenu.attr('data-visually-hidden','false');
	    }
	    else {
	        label.attr('aria-expanded','false');
            subMenu.attr('data-visually-hidden','true');
	    }
	}
   // events on main menu
   // mouse !
   $body.on('mouseenter', '.js-nav-system__item', function(event) {
         var $this = $(this),
             $subnav_link = $this.children('.js-nav-system__link'),
             $subnav = $this.children('.js-nav-system__subnav');

         $this.attr({
            'data-show-sub': 'true'
         });

         // show submenu
         if ($subnav.length === 1) {
            showSubMenu($this, true);
         }

      })
      .on('mouseleave', '.js-nav-system__item', function(event) {
         var $this = $(this),
             $subnav_link = $this.children('.js-nav-system__link'),
             $subnav = $this.children('.js-nav-system__subnav');

         $this.attr({
            'data-show-sub': 'false'
         });
         // show submenu
         if ($subnav.length === 1) {
            showSubMenu($this, false);
         }

      })
        // click
      .on('click', '.js-nav-system__link', function (event) {
         var $this = $(this),
             $parent = $this.parents('.js-nav-system'),
             $parent_item = $this.parents('.js-nav-system__item'),
             $subnav = $this.next('.js-nav-system__subnav');

         $parent_item.attr({
            'data-show-sub': 'true'
         });

         // hide all other visible menus and show submenu activated
         showSubMenu($parent, false);

         if ($subnav.length === 1) {
            showSubMenu($parent_item, true);
            //Focus the first menu element when menu is opened.
            $subnav.find("li:eq(0) a").focus();
         }
      })
      .on('focusout', '.js-nav-system__link', function(event) {
         var $this = $(this),
             $parent = $this.parents('.js-nav-system'),
             $parent_item = $this.parents('.js-nav-system__item');

         $parent_item.attr({
            'data-show-sub': 'false'
         });
      })
      .on('keydown', '.js-nav-system__link', function(event) {
         var $this = $(this),
             $parent = $this.parents('.js-nav-system'),
             $parent_item = $this.parents('.js-nav-system__item'),
             $subnav = $this.next('.js-nav-system__subnav');

         // event keyboard left
         if (event.keyCode == 37) {
            // select previous nav-system__link

            // if we are on first => activate last
            var $prev_item = $parent_item.prevAll('.js-nav-system__item').children('.js-nav-system__link:visible:first');
            if (!$prev_item.length) {
               $parent_item.nextAll('.js-nav-system__item').children('.js-nav-system__link:visible:last').focus();
            }
            // else activate previous
            else {
               $prev_item.focus();
            }
            event.preventDefault();
         }

         //event keyboard up
         if(event.keyCode == 38) {
            if($subnav.length === 1) {
               // if submenu has been closed => reopen
               showSubMenu($parent_item, true);
               // and select last item
               $subnav.children('.js-nav-system__subnav__item').children('.js-nav-system__subnav__link:visible:last').focus();
            }
            event.preventDefault();
         }

         //Handling the Enter and spacebar key to show submenu if exists
         if (event.keyCode === 13 || event.keyCode === 32){
            
             // hide other menus and show submenu activated
            showSubMenu($parent, false);
            $parent_item.attr({
                'data-show-sub': 'true'
             });
    
            if ($subnav.length === 1) {
                showSubMenu($parent_item, true);
                //Focus the first menu element when menu is opened.
                $subnav.find("li:eq(0) a").focus();
                event.preventDefault();
            }
            
         }

         // event keyboard right
         if (event.keyCode == 39) {
            // select previous nav-system__link

            // if we are on last => activate first
            var $next_item = $parent_item.nextAll('.js-nav-system__item').children('.js-nav-system__link:visible:first');
            if (!$next_item.length) {
               $parent_item.prevAll(" .js-nav-system__item").children(".js-nav-system__link:visible:last").focus();
            }
            // else activate next
            else {
               $next_item.focus();
            }
            event.preventDefault();
         }

         // event keyboard bottom
         if (event.keyCode == 40) {
            // select first nav-system__subnav__link
            if ($subnav.length === 1) {
               // if submenu has been closed => reopen
               showSubMenu($parent_item, true);
               // and select first item
               $subnav.children(" .js-nav-system__subnav__item").children(".js-nav-system__subnav__link:visible:first").focus();
            }
            event.preventDefault();
         }

         // event ESC: close menu if open
         if (event.keyCode == 27) {
           showSubMenu($parent_item, false);
           event.preventDefault();   
         }       

         // event shift + tab 
         /**
          *  if (event.shiftKey && event.keyCode == 9) {
            // shift + tab code goes here
         }
         */
      });

   // events on submenu item
   $body.on('keydown', '.js-nav-system__subnav__link', function(event) {
         var $this = $(this),
             $subnav = $this.parents('.js-nav-system__subnav'),
             $subnav_item = $this.parents('.js-nav-system__subnav__item'),
             $nav_link = $subnav.prev('.js-nav-system__link'),
             $nav_item = $nav_link.parents('.js-nav-system__item'),
             $nav = $nav_link.parents('.js-nav-system');

         // event keyboard bottom
         if (event.keyCode == 40) {
            // if we are on last => activate first
            var $subnav_nextitem = $subnav_item.nextAll('.js-nav-system__subnav__item').children('.js-nav-system__subnav__link:visible:first');
            if (!$subnav_nextitem.length) {
               $subnav_item.prevAll('.js-nav-system__subnav__item').children('.js-nav-system__subnav__link:visible:last').focus();
            }
            // else activate next
            else {
               $subnav_nextitem.focus();
            }
            event.preventDefault();
         }
         // event keyboard top
         if (event.keyCode == 38) {
            // if we are on first => activate last
            var $subnav_previtem = $subnav_item.prevAll('.js-nav-system__subnav__item').children('.js-nav-system__subnav__link:visible:first');
            if (!$subnav_previtem.length) {
               $subnav_item.nextAll('.js-nav-system__subnav__item').children('.js-nav-system__subnav__link:visible:last').focus();
            }
            // else activate previous
            else {
               $subnav_previtem.focus();
            }
            event.preventDefault();
         }
         // event keyboard Esc
         if (event.keyCode == 27) {
            // close the menu
            $nav_link.focus();
            showSubMenu($nav_item, false);
            event.preventDefault();
         }
         // event keyboard right
         if (event.keyCode == 39) {
            // select next nav-system__link
            showSubMenu($nav_item, false);

            // if we are on last => activate first and choose first item
            if ($nav_item.is(".js-nav-system__item:last-child")) {
               $next = $nav.children(" .js-nav-system__item:visible:first");
               var $next_link = $next.children('.js-nav-system__link');
               $next_link.focus();
               $subnav_next = $next_link.next('.js-nav-system__subnav');
               if ($subnav_next.length === 1) {
                  showSubMenu($next, true);
                  $subnav_next.children(".js-nav-system__subnav__item:first").children(".js-nav-system__subnav__link").focus();
               }
            }
            // else activate next
            else {
               $next = $nav_item.nextAll('.js-nav-system__item:visible:first');
               var $next_link = $next.children('.js-nav-system__link');
               $next_link.focus();
               $subnav_next = $next_link.next('.js-nav-system__subnav');
               if ($subnav_next.length === 1) {
                  showSubMenu($next, true);
                  $subnav_next.children(".js-nav-system__subnav__item:first").children(".js-nav-system__subnav__link").focus();
               }
            }
            event.preventDefault();
         }
         // event keyboard left
         if (event.keyCode == 37) {
            // select prev nav-system__link
            showSubMenu($nav_item, false);

            // if we are on first => activate last and choose first item
            if ($nav_item.is(".js-nav-system__item:first-child")) {
               $prev = $nav.children(" .js-nav-system__item:visible:last");
               var $prev_link = $prev.children('.js-nav-system__link');
               $prev_link.focus();
               $subnav_prev = $prev_link.next('.js-nav-system__subnav');
               if ($subnav_prev.length === 1) {
                  showSubMenu($prev, true);
                  $subnav_prev.children(".js-nav-system__subnav__item:first ").children(".js-nav-system__subnav__link").focus();
               }
            }
            // else activate prev
            else {
               $prev = $nav_item.prevAll('.js-nav-system__item:visible:first');
               var $prev_link = $prev.children('.js-nav-system__link');
               $prev_link.focus();
               $subnav_prev = $prev_link.next('.js-nav-system__subnav');
               if ($subnav_prev.length === 1) {
                  showSubMenu($prev, true);
                  $subnav_prev.children(".js-nav-system__subnav__item:first ").children(".js-nav-system__subnav__link").focus();
               }
            }
            event.preventDefault();
         }
         // event tab 
         if (event.keyCode == 9 && !event.shiftKey) { 
             // if we are on last item of the menu and we go forward => hide subnav
             // We are using :has(>:focusable) to check if the li content is focusable.
            if ($subnav.find(".js-nav-system__subnav__item:has(>:focusable):last:visible")[0] === $subnav_item[0]) {
                showSubMenu($nav_item, false);
            }
         }
         //Event shift tab
         if (event.shiftKey && event.keyCode == 9) {
             //If it is the first element of menu then hide the sub-menu.
            if ($subnav.find(".js-nav-system__subnav__item:visible:first")[0] === $subnav_item[0]) {
                showSubMenu($nav_item, false);
            }
        }

      })
      .on('focus', '.js-nav-system__subnav__link', function(event) {
         var $this = $(this),
             $subnav = $this.parents('.js-nav-system__subnav'),
             $subnav_item = $this.parents('.js-nav-system__subnav__item'),
             $nav_link = $subnav.prev('.js-nav-system__link'),
             $nav_item = $nav_link.parents('.js-nav-system__item'),
             $nav = $nav_link.parents('.js-nav-system__item');

         $nav_item.attr({
            'data-show-sub': 'true'
         });
      })
      .on('focusout', '.js-nav-system__subnav__link', function(event) {
         var $this = $(this),
             $subnav = $this.parents('.js-nav-system__subnav'),
             $subnav_item = $this.parents('.js-nav-system__subnav__item'),
             $nav_link = $subnav.prev('.js-nav-system__link'),
             $nav_item = $nav_link.parents('.js-nav-system__item'),
             $nav = $nav_link.parents('.js-nav-system__item');

         $nav_item.attr({
            'data-show-sub': 'false'
         });
      });

   /**
    * Close any open dropdowns on global ESC (should work for hover-opened or click-opened)
    * Dropdown would be closed if its visible per data attributes.
    */
   function hideAllMenusOnEsc(evt) {
      const topLevelItems = document.querySelectorAll('.js-nav-system__item');
      topLevelItems.forEach(function (item) {
         const dowpdownElm = item.querySelector('.js-nav-system__subnav');
         if (!dowpdownElm) return;

         if (dowpdownElm.getAttribute('data-visually-hidden') === 'false') {
            const label = item.querySelector('.js-nav-system__link');
            if (label) label.setAttribute('aria-expanded', 'false');
            dowpdownElm.setAttribute('data-visually-hidden', 'true');
            item.setAttribute('data-show-sub', 'false');
         }
      });

      evt.preventDefault();
   }

   document.addEventListener('keydown', function (evt) {
      if (evt.key === 'Escape' || evt.keyCode === 27) {
         hideAllMenusOnEsc(evt);
      }
   });
});
