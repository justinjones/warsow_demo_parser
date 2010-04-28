require 'digest/sha1'
begin
  require File.join(File.dirname(__FILE__), '..', '..', "lib", "authenticated_system", "authenticated_dependencies")
rescue 
  nil
end
class User
  include DataMapper::Resource
  include AuthenticatedSystem::Model
  
  attr_accessor :password, :password_confirmation
  
  property :login,                      String
  property :email,                      String
  property :crypted_password,           String
  property :salt,                       String
  property :remember_token_expires_at,  DateTime
  property :remember_token,             String
  property :created_at,                 DateTime
  property :updated_at,                 DateTime
  
  validates_length         :login,                   :within => 3..40
  validates_is_unique     :login
  validates_present       :email
  # validates_format         :email,                   :as => :email_address
  validates_length         :email,                   :within => 3..100
  validates_is_unique     :email
  validates_present       :password,                :if => proc {password_required?}
  validates_present       :password_confirmation,   :if => proc {password_required?}
  validates_length         :password,                :within => 4..40, :if => proc {password_required?}
  validates_is_confirmed   :password,                :groups => :create
    
  before :save,  :encrypt_password
  
  def login=(value)
    @login = value.downcase unless value.nil?
  end
    


  
end