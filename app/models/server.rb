class Server
  include DataMapper::Resource
  
  property :user_id,                  Integer
  property :address,                  String
  property :port,                     Integer
  property :hostname,                 String
  
  belongs_to :user
end

