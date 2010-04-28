class Rating
  include DataMapper::Resource
  
  property :user_id,            Integer
  property :demo_id,            Integer
  property :rating,             Integer
  
  belongs_to :user
  belongs_to :demo
end