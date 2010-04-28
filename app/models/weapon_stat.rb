class WeaponStat
  include DataMapper::Resource
  
  WEAP_GUNBLADE = 0
	WEAP_SHOCKWAVE = 1
	WEAP_RIOTGUN = 2
	WEAP_GRENADELAUNCHER = 3
	WEAP_ROCKETLAUNCHER = 4
	WEAP_PLASMAGUN = 5
	WEAP_LASERGUN = 6
	WEAP_ELECTROBOLT = 7
	WEAP_INSTAGUN = 8
	
	WEAPONS = [
	  WEAP_GUNBLADE,
	  WEAP_SHOCKWAVE,
	  WEAP_RIOTGUN,
	  WEAP_GRENADELAUNCHER,
	  WEAP_ROCKETLAUNCHER,
	  WEAP_PLASMAGUN,
	  WEAP_LASERGUN,
	  WEAP_ELECTROBOLT,
	  WEAP_INSTAGUN
	  ]
	
	WEAP_ACRONYMS = {
	  WEAP_GUNBLADE => 'GB',
	  WEAP_SHOCKWAVE => 'SW',
	  WEAP_RIOTGUN => 'RG',
	  WEAP_GRENADELAUNCHER => 'GL',
	  WEAP_ROCKETLAUNCHER => 'RL',
	  WEAP_PLASMAGUN => 'PG',
	  WEAP_LASERGUN => 'LG',
	  WEAP_ELECTROBOLT => 'EB',
	  WEAP_INSTAGUN => 'IG'
	}
  
  property :stat_id, Integer
  property :weapon_id, Integer
  property :weapon_name, String
  property :total_shot, Integer, :default => 0
  property :total_hit, Integer, :default => 0
  property :strong_shot, Integer, :default => 0
  property :strong_hit, Integer, :default => 0
  property :weak_shot, Integer, :default => 0
  property :weak_hit, Integer, :default => 0
  
  belongs_to :stat
  
  before :save,  :correct_faulty_values
  
  def player
    self.stat.player
  end
  
  def total_percentage
    if self.total_shot > 0
      (self.total_hit.to_f / self.total_shot.to_f * 100).round rescue 0
    end
  end
  
  def weak_percentage
    if self.weak_shot > 0
      (self.weak_hit.to_f / self.weak_shot.to_f * 100).round rescue 0
    end
  end
  
  def strong_percentage
    if self.strong_shot > 0
      (self.strong_hit.to_f / self.strong_shot.to_f * 100).round rescue 0
    end
  end
  
  def correct_faulty_values
    self.total_hit = self.total_shot if self.total_hit > self.total_shot
    self.weak_hit = self.weak_shot if self.weak_hit > self.weak_shot
    self.strong_hit = self.strong_shot if self.strong_hit > self.strong_shot
  end 
  
  def self.from_demo_reader(dstats)
    dstats.map do |ds|
      ws = new
      %w(weapon_id weapon_name total_shot total_hit strong_shot strong_hit weak_shot weak_hit).each do |attr|
        ws.send("#{attr}=", ds.send(attr))
      end
      ws
    end
  end
end