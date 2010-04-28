class Stat
  include DataMapper::Resource
  
  property :player_id, Integer
  property :demo_id, Integer
  property :colored_name, String
  property :score, Integer
  property :kills, Integer
  property :deaths, Integer
  property :suicides, Integer
  property :team_kills, Integer
  property :ping, Integer
  property :player_class, String
  property :coach, Boolean, :default => false
  property :spectator, Boolean, :default => false
  
  belongs_to :player
  belongs_to :demo
  has n, :weapon_stats
  
  def self.from_demo_reader(dplayer)
    stat = new
    %w(score kills deaths suicides team_kills ping player_class coach spectator).each do |meth|
      stat.send("#{meth}=", dplayer.send("#{meth}"))
    end
    stat.colored_name = dplayer.name
    stat
  end
end
  