# analytics tracking account
# wtf is our m3 live analytics accounts?  don't set it here!
LOCAL_ANALYTICS_ACCOUNT = 'UA-17436181-1' unless defined? LOCAL_ANALYTICS_ACCOUNT

# Rails-authorization-plugin configuration.
AUTHORIZATION_MIXIN = 'object roles'
LOGIN_REQUIRED_REDIRECTION = "/"
LOGIN_REQUIRED_MESSAGE = "You must be logged in to access this page"
PERMISSION_DENIED_REDIRECTION = "/home"

# Used in hack of rails_authorization plugin; still needed?
STORE_LOCATION_METHOD = :store_location

# jwplayer license key
JWPLAYER_KEY = '7IPuJXudhDa2VghPqUZq8eCCJqZvr+ZVerzQX3kDvrA='
