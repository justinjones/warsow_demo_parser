# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.
module Merb
  class Request
    def api_request
      subdomains.first == 'api' || nil
    end
  end
end

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  match(:api_request => ':api_request') do |api|
    api.resources :demos, :namespace => 'api'
  end
  

  # RESTful routes
  # r.resources :posts
  resources :demos
  resources :players
  resources :maps
  match("/demos/:id/download").
    to(:controller => "demos", :id => ":id", :action => "download").
    name(:demo_download)
    
  resources :maps
  
  defer_to do |request, params|
    if request.subdomains.first == 'api'
      resources :things, :namespace => 'api'
    end
    puts request.subdomains.first
    puts params.inspect
  end

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  default_routes
  
  # Change this for your home page to be available at /
  # r.match('/').to(:controller => 'whatever', :action =>'index')
end