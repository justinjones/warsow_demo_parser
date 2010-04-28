require 'rest_client'

class WarsowREST < REST::Client
  
  def initialize(userid, password, use_ssl=false)
    @host = 'http://localhost:4000'
    @use_ssl = use_ssl
    @userid = userid
    @password = password
    @user_agent = 'WarsowServer.rb/1.0 RestClient.rb/1.0'
    @media_type = 'application/vnd.demoupload+xml'
    
    has n, :assets
    has n, :demos
  end
end