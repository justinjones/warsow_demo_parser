class Map
  include DataMapper::Resource
  
  property :name,           String
  property :url,            String
  property :description,    Text
  
  validates_present :name
  
  has n, :demos
  
  def self.mapshots_path
    Merb.root / 'public' / 'mapshots'
  end
  
  def mapshots_path
    self.class.mapshots_path
  end
end

class WarsowMap < Map
  def self.mapshots_path
    super / 'warsow'
  end
end

class PromodeMap < Map
  def self.mapshots_path
    super / 'promode'
  end
end

class CSMap < Map
  def self.mapshots_path
    super / 'cs'
  end
end

class CSSMap < Map
  def self.mapshots_path
    super / 'css'
  end
end
  
  
    