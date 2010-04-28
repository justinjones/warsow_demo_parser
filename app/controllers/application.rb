# all your other controllers should inherit from this one to share code.
#dependencies "authenticated_system_controller"

class Application < Merb::Controller
  
  protected
  def api_authorized?
    logged_in? && current_user.api_client?
  end
  
  def api_login_required
    api_authorized? || throw(:halt, :access_denied)
  end
end