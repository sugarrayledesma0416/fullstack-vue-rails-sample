var VHL = VHL || {}
/**
 * NOTE: This code originally was in the old chat_client gem:
 *
 * https://github.com/vhl/chat_client/blob/master/app/assets/javascripts/partner_chat/utils.js#L30-L194

/**
 * VHL.Storage provides a high level API for storage of client side data. Like
 * jQuery storage, it will fall back to cookies if LocalStorage is not
 * available, but unlike jQuery storage, this is optional. In other words, you
 * are able to specify if cookie fall back should be used for each piece of data
 * being stored. This allows you to store large amounts of information using the
 * same API that would not necessarily fit in cookie storage, but which are not
 * required by an application.
 *
 * To take an example from the old Partner Chat code:
 *
 * VHL.MessageClient.Contacts maintains a list of contacts. When a user
 * navigates to another page, and session attachment is being used, the initial
 * request for roster should not be required. Rather, that information is stored
 * locally and reused. However, this information is large and should not be
 * stored in cookies, so if LocalStorage is not available, it will simply be
 * requested when the user attaches to an existing session. Whereas small data,
 * such as the BOSH session ID should fall back to cookie storage.
 */
VHL.Storage = (function() {

	/**
	 * Create a new VHL.Storage instance
	 */
	var storage = {}

	/**
	 * Detect whether or not the browser supports localStorage/sessionStorage
	 */
	try {
		storage.HAS_STORAGE = ('localStorage' in window && window['localStorage'] !== null)
	} catch (e) {
		storage.HAS_STORAGE = false
	}

	/**
	 * The error type for the error triggered if storage is not available and
	 * the use_cookies option is set to false.
	 */
	storage.STORAGE_NOT_AVAILABLE = "storage_not_available"

	/**
	 * A date in the far future to use for the cookie expiration time for
	 * non-session persistent data
	 */
	storage.FAR_FUTURE = new Date((new Date()).getFullYear() + 10, 0, 0, 0, 0, 0, 0)

    /**
     * This regex and function originally were in chat_client VHL.Utils:
     *
     * https://github.com/vhl/chat_client/blob/master/app/assets/javascripts/partner_chat/utils.js#L200
     * https://github.com/vhl/chat_client/blob/master/app/assets/javascripts/partner_chat/utils.js#L210-L216
     */
	SUPERDOMAIN_REGEX = new RegExp("[^\\.]+\\.[^\\.]+$");
	parse_super_domain = function(domain) {
		var result = SUPERDOMAIN_REGEX.exec(domain);
		if (result) {
			return result.toString()
		}
		return domain;
	};

	/**
	 * Return an options object with defaults set for any properties in the
	 * argument which are not set. The options argument is optional, and will be
	 * created if needed, however, if specified, it will be directly altered.
	 *
	 * @param {Object} options The options
	 * @return {Object} A new options object with defaults, or the specified
	 *         options object with defaults filled in.
	 */
	function get_options_with_defaults(options) {
		options = options || {}
		options.json = (options.json != undefined) ? options.json : false
		options.use_cookies = (options.use_cookies != undefined) ? options.use_cookies : true
		options.session = (options.session != undefined) ? options.session : false
		options.domain = options.domain || parse_super_domain(document.domain)
		options.path = options.path || "/"
		return options
	}

	/**
	 * Remove all keys which match the specified regular expression
	 */
	storage.remove_all = function(regex, options) {
		if (VHL.Storage.HAS_STORAGE) {
			for (name in localStorage) {
				if (regex.test(name)) {
					delete localStorage[name]
				}
			}
			for (name in sessionStorage) {
				if (regex.test(name)) {
					delete localStorage[name]
				}
			}
		} else {
			if (document.cookie && document.cookie != '') {
				options = get_options_with_defaults(options)
				var split = document.cookie.split(';')
				for ( var i = 0; i < split.length; i++) {
					var name_value = split[i].split("=")
					$.removeCookie(name_value[0], options)
				}
			}
		}
	}

	/**
	 * Remove the data with the specified key and options.
	 *
	 * @param {String} key The key of the data to remove
	 * @param {Object} options The options specified when the data was set
	 */
	storage.remove = function(key, options) {
		options = get_options_with_defaults(options)
		if (VHL.Storage.HAS_STORAGE) {
			localStorage.removeItem(key)
			sessionStorage.removeItem(key)
		} else {
			$.removeCookie(key, options)
		}
	}

	/**
	 * Set the data with the specified key and options.
	 *
	 * @param {String} key The key to set the data under
	 * @param {Object} data The data to set
	 * @param {Object} options The options to use
	 */
	storage.set = function(key, data, options) {
		options = get_options_with_defaults(options)

		if (options.json) {
			data = JSON.stringify(data)
		}

		if (VHL.Storage.HAS_STORAGE) {
			if (options.session) {
				sessionStorage.setItem(key, data)
			} else {
				localStorage.setItem(key, data)
			}
		} else if (options.use_cookies) {
			$.cookie(key, data, {
				expires : (options.session) ? null : VHL.Storage.FAR_FUTURE,
				domain : options.domain,
				path : options.path,
				json : options.json
			})
		}
	},

	/**
	 * Get the data with the specified key. This does not return the data
	 * directly, but rather enclosed within another object which contains other
	 * information about the object, such as its expiration date and last
	 * modified time.
	 */
	storage.get = function(key, options) {
		options = get_options_with_defaults(options)

		var data = null
		if (VHL.Storage.HAS_STORAGE) {
			data = localStorage.getItem(key)
			if (!data) {
				data = sessionStorage.getItem(key)
				if (!data) {
					return null
				}
			}
			if (options.json) {
				return JSON.parse(data)
			}
			return data
		} else {
			return $.cookie(key, options)
		}
	}

	return storage
})();
