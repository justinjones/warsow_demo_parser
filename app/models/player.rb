class Player
  include DataMapper::Resource
  
  property :name,                   String
  property :downloads,              Integer, :default => 0
  property :rating,                 Integer, :default => 0
  property :demos_count,            Integer, :default => 0
  
  has n, :demos, :through => Resource
  has n, :stats
  has n, :player_stats, :class_name => 'Stat', :spectator.eql => false
  has n, :spectator_stats, :class_name => 'Stat', :spectator.eql => true
  
  before :save,  :set_rating
  before :save,  :count_demos
  
  def self.from_demo_reader(dplayer)
    name = dplayer.name.gsub(/\^\d/, '')
    (first(:name => name) || create(:name => name))
  end
  
  def colored_name
    names = {}
    stats.each do |ps|
      names[ps.colored_name] ||= 0
      names[ps.colored_name] += 1
    end
    names.sort_by { |k,v| v }.first.first
  end
  
  def other_demos_with(other_player)
    self.demos.to_a & other_player.demos.to_a
  end
  
  def count_demos
    self.demos_count = demos.size
  end
  
  def set_rating
    self.rating = self.downloads / self.demos.count rescue 0
  end
  
  def self.popular
    all(:order => [:rating.desc, :demos_count.desc], :limit => 10)
  end
  
  def alltime_stats
    all_stats = WeaponStat.all(:stat_id.in => player_stats.map { |ps| ps.id })
    ret = []
    WeaponStat::WEAPONS.each do |weap_id|
      puts all_stats.inspect
      weap_stats = all_stats.select { |ws| ws.weapon_id == weap_id }
      total_shot = total_hit = weak_shot = weak_hit = strong_shot = strong_hit = 0
      weap_stats.each do |ws|
        total_shot += ws.total_shot
        total_hit += ws.total_hit
        weak_shot += ws.weak_shot
        weak_hit += ws.weak_hit
        strong_shot += ws.strong_shot
        strong_hit += ws.strong_hit
        ret << WeaponStat.new(:weapon_id => ws.weapon_id, :total_shot => total_shot, :total_hit => total_hit,
                  :weak_shot => weak_shot, :weak_hit => weak_hit, :strong_shot => strong_shot, :strong_hit => strong_hit)
        
      end
    end
    ret
  end
  
  def clan_name(players)
    clans = []
    while player1 = players.pop
      players.each do |player2|
        i = 0
        clan = nil
        while player1[0..i] == player2[0..i] do
          i += 1
          clan = player1[0..i]
        end
        clans << clan if clan
      end
    end
    clans
    
    i = Hash.new { |h,k| h[k] = 0 }
    arr.each { |e| i[e] +=1 }
  end
        
end

