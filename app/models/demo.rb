class Demo
  require 'tempfile'
  # Mapping of protocol fixnum => version string
  WARSOW_VERSIONS =  { 8 => '0.2x', 9 => '0.3x', 10 => '0.4x' }
  
  include DataMapper::Resource
  
  property :user_id,                    Integer
  property :gametype,                   String
  property :map_id,                     Integer
  property :protocol,                   Integer
  property :downloads,                  Integer, :default => 0
  property :rating,                     Integer, :default => 0
  property :votes,                      Integer, :default => 0
  property :description,                Text
  property :created_at,                 DateTime
  
  property :filename,                   String
  
  validates_present :gametype, :map_id, :protocol
  validates_format :gametype, :with => /^duel|da$/
  validates_is_number :protocol, :only_integer => :true
  
  belongs_to :user
  belongs_to :map
  
  has n, :players, :through => Resource
  #has_and_belongs_to_many :spectators, :class_name => 'Player'
  has n, :stats
  has n, :player_stats, :class_name => 'Stat', :conditions => { :spectator => false }
  has n, :spectator_stats, :class_name => 'Stat', :conditions => { :spectator => true }
  
  def map_name=(map_name)
    self.map = (Map.first(:name => map_name) || Map.create(:name => map_name))
  end
  
  def teams
    player_stats.map { |p| p.colored_name }.join(' vs ')
  end
  
  def warsow_version
    WARSOW_VERSIONS[self.protocol] || nil
  end
  
  def self.from_demo_reader(filename, attrs = {})
    Demo.new(attrs).from_demo_reader(filename)
  end
  
  def from_demo_reader(filename)
    @tempfile = copy_to_temp_file(filename, :demo)
    require 'wsw_demo_reader'
    dr = DemoReader.new(filename)
    self.map_name = dr.mapname
    self.gametype = dr.gamemode[0..-2] # Chop the trailing 's'
    self.protocol = dr.version
    
    dr.players.each do |dp|
      player = Player.from_demo_reader(dp)
      stat = Stat.from_demo_reader(dp)
      stat.player = player
      stat.weapon_stats = WeaponStat.from_demo_reader(dp.stats)
      self.stats << stat
      self.players << player
    end
    
    dr.spectators.each do |ds|
      player = Player.from_demo_reader(ds)
      stat = Stat.from_demo_reader(ds)
      stat.player = player
      self.stats << stat
    end
    self
  end
    
  def increment_downloads
    self.downloads += 1
    save
    self.players.each do |p|
      p.downloads += 1
      p.save
    end
    self
  end
  
  def self.popular(opts = {})
    all({:order => [:downloads.desc], :limit => 10}.merge(opts))
  end
  
  # File Stuff
  validates_present :filename
  #before :validate, :set_filename
  after :save, :move_tempfile
  
  def uploaded_data
    nil
  end
  
  # Copies the given file path to a new tempfile, returning the closed tempfile.
  def copy_to_temp_file(file, temp_base_name)
    t = Tempfile.new(temp_base_name) do |tmp|
      tmp.close
      FileUtils.cp file, tmp.path
    end
    t
  end
  
  def uploaded_data=(file_data)
    return nil if file_data.nil? || file_data['size'] == 0
    self.from_demo_reader(file_data['tempfile'].path)
  end
  
  def full_filename
    Merb.root + "/demos/#{self.id}/#{self.filename}"
  end
  
  protected
  def set_filename
    case self.gametype
    when 'duel'
      self.filename = [ 'DS', (self.created_at || Time.now).strftime('%Y%m%d-%H%m'), self.gametype, self.players.map { |p| p.name.gsub(/[^a-zA-Z0-9._-]/, '_') }.join('_vs_'), self.map.name ].join('_') + ".wd#{self.protocol}"
    else
      self.filename = [ 'DS', (self.created_at || Time.now).strftime('%Y%m%d-%H%m'), self.gametype, self.map.name ].join('_') + ".wd#{self.protocol}"
    end
  end
  
  def move_tempfile
    if @tempfile
      FileUtils.mkdir_p Merb.root + "/demos/#{self.id}"
      FileUtils.mv @tempfile.path, Merb.root + "/demos/#{self.id}/#{self.filename}"
    end
  end

end

