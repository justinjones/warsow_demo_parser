class DemoPlayer
  GAMETYPES = {
    'ffas' => :ffa,
    'races' => :race,
    'duels' => :duel,
    'tdms' => :tdm,
    'ctfs' => :ctf,
    'cas' => :ca,
    'das' => :da
  }
  
  attr_accessor :name, :number, :score, :ping, :kills, :team_kills, :deaths, :suicides,
                :team, :ready, :dead, :player_class, :coach, :waiting, :race_time, :spectator, :stats
  
  def initialize(name = 'player', number = nil, ping = nil)
    @name, @number, @ping = name, number, ping
  end
  
  class << self
    def from_scoreboard(gametype, player_names, scoreboard)
      @@player_names = player_names

      regex = /^&(\w)\s+((:?\d+\s+)+)/
      matchdata = regex.match(scoreboard)

      if matchdata
        args = matchdata[2].split(/\s/).map { |i| i.to_i }
        puts args.inspect
        case matchdata[1]
        when 't' # Team
          @@team_number, @@team_score = args[0], args[1]
          nil
        when 'p' # Player
          send("parse_#{GAMETYPES[gametype].to_s}", *args)
        when 's' # Spectator
          parse_spectator(*args)
        when 'w' # Challenger / Waiting List
          parse_spectator(*args)
        when 'c' # Connecting Person
          parse_connecting(*args)
          #dont care abotu connecting players?
        else
          nil
        end
      end    
    end

    def parse_ffa(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.score, p.ping, p.ready = args
      p
    end

    def parse_race(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.race_time, p.ping, p.ready = args
      p
    end

    def parse_duel(*args)
      puts args.inspect
      name = @@player_names[args[1]]
      p = new(name)
      p.team, p.number, p.score, p.kills, p.deaths, p.suicides, p.ping = args
      p
    end

    def parse_tdm(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.score, p.kills, p.deaths, p.suicides, p.team_kills, p.ping, p.ready, p.coach = args
      p.team = @@team_number
      p
    end

    def parse_ctf(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.score, p.ping, p.ready, p.coach = args
      p.team = @@team_number
      p
    end

    def parse_ca(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.score, p.kills, p.player_class, p.ping, p.dead, p.ready, p.coach, p.team = args
      p
    end

    def parse_da(*args)
      parse_duel(*args)
    end

    def parse_spectator(*args)
      name = @@player_names[args[0]]
      p = new(name)
      p.number, p.ping = args
      p.spectator = true
      p
    end

    def parse_connecting(*args)
      p = new
      p.number, p.ping = args.first, 0
      p.spectator = true
      p
    end
  end
  
  def coach=(bool)
    (bool == 0 || bool == false) ? @coach = false : @coach = true
  end
  
  def ready=(bool)
    (bool == 0 || bool == false) ? @ready = false : @ready = true
  end
  
  def waiting=(bool)
    (bool == 0 || bool == false) ? @waiting = false : @waiting = true
  end
end

class DemoWeaponStat
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
	  WEAP_RIOTGUN,
	  WEAP_GRENADELAUNCHER,
	  WEAP_ROCKETLAUNCHER,
	  WEAP_PLASMAGUN,
	  WEAP_LASERGUN,
	  WEAP_ELECTROBOLT,
	  WEAP_INSTAGUN
	  ]
	
  WEAPON_NAMES = {
    WEAP_GUNBLADE => 'Gunblade',
    WEAP_RIOTGUN => 'Riotgun',
    WEAP_GRENADELAUNCHER => 'Grenade Launcher',
    WEAP_ROCKETLAUNCHER => 'Rocket Launcher',
    WEAP_PLASMAGUN => 'Plasma Gun',
    WEAP_LASERGUN => 'Laser Gun',
    WEAP_ELECTROBOLT => 'Electro Bolt',
    WEAP_INSTAGUN => 'Instagun'
  }
  
  attr_accessor :weapon_id, :weapon_name, :total_shot, :total_hit, :weak_shot, :weak_hit, :strong_shot, :strong_hit
  
  def initialize(weap_id, player_id, total_shot, total_hit = 0, strong_shot = 0, strong_hit = 0)
    @weapon_id = weap_id
    @weapon_name = WEAPON_NAMES[weap_id]
    @total_shot = total_shot
    @total_hit = total_hit
    @strong_shot = strong_shot
    @strong_hit = strong_hit
    
    if weapon_id == WEAP_LASERGUN || weapon_id == WEAP_ELECTROBOLT
      @weak_shot = total_shot - strong_shot
      puts total_hit.inspect
      puts strong_hit.inspect
      @weak_hit = total_hit - strong_hit
    end
  end
  
  def total_percentage
    @total_shot > 0 ? (@total_hit.to_f / @total_shot.to_f * 100).round : 0.0
  end
  
  def weak_percentage
    @weak_shot > 0 ? (@weak_hit.to_f / @weak_shot.to_f * 100).round : 0.0
  end
  
  def strong_percentage
    @strong_shot > 0 ? (@strong_hit.to_f / @strong_shot.to_f * 100).round : 0.0
  end
  
  def self.from_plstats(plstats)
    regex = /plstats 0 " ((:?\d+\s*)+)/
    match = regex.match(plstats)
    args = match[1].split(/\s+/).map { |i| i.to_i }
    
    stats = []
    player_id = args.shift
    WEAPONS.each do |weap_id|
      total_shot = total_hit = strong_shot = strong_hit = 0
      puts args.inspect
      total_shot = args.shift
      unless total_shot == 0
        total_hit = args.shift
        
        if (weap_id == WEAP_LASERGUN || weap_id == WEAP_ELECTROBOLT)
          strong_shot = args.shift
          if strong_shot != total_shot
            strong_hit = args.shift
          else
            strong_hit = total_hit
          end
        end
      end
      puts "#{weap_id} #{player_id.inspect} #{total_shot} #{total_hit} #{strong_shot} #{strong_hit}"
      stats << new(weap_id, player_id, total_shot, total_hit, strong_shot, strong_hit)
    end
    stats    
  end
  
end

class DemoReader
  attr_reader :filename, :version, :mapname, :time, :playernames, :scoreboards, :gamemode, :player, :valid, :players, :spectators


  def initialize(filename)
    @filename = filename
    @version = -1
    @mapname = nil
    @time = nil
    @time_in_msec = nil
    @playernames = []
    @scoreboards = []
    @stats = []
    @players = []
    @spectators = []
    @gamemode = nil
    @player = nil
    @valid = false

    self.init()
  end


  def init()
    file = File.new(@filename, 'r')

    return if file.stat.size < 10

    file.pos += 4  # skip 4 byte message length
    file.pos += 1  # skip 1 byte "svc_serverdata"


    # version
    # reads 4 bytes and decodes the little-endian format
    @version = file.read(4).unpack('V')[0]

    # just support for wd8 and wd9 files
    return unless [8, 9, 10].include? @version

    content = file.gets nil
    file.close
    
    # mapname
    regex = /cs 1 "([^"]+)"/
    @mapname = regex.match(content)[1].downcase

    # detect scoreboard

    regex = /scb \"([^\"]+)/
    matchdata = regex.match(content)

    while matchdata
      @scoreboards.push matchdata[1]
      matchdata = regex.match(matchdata.post_match)
    end
    
    
    # detect player stats
    
    regex = /plstats 0 "([^"]+)/
    matchdata = regex.match(content)
    
    while matchdata
      @stats.push matchdata[0]
      matchdata = regex.match(matchdata.post_match)
    end



    # detect game mode

    regex = /&([^ ]+) /

    gamemodes = []
    @scoreboards.each { |scb|
      matchdata = regex.match(scb)
      gamemodes.push matchdata[1]
    }
    gamemodes.uniq!
    if gamemodes.length.zero?
      @gamemode = 'unknown'
    else
      if gamemodes.length == 1
        @gamemode = gamemodes.first
        @gamemode.chop! if ['races', 'dms', 'ctfs'].include? @gamemode
      else
        @gamemode = "multiple gamemodes found: #{gamemodes.join(', ')}!"
      end
    end



    # detect time by sent message string with time from server
    if @gamemode == 'race'
      matches = []
      regex = /(Server record|Race finished): ([0-9]+:[0-9]+\.[0-9]+)/
      matchdata = regex.match(content)

      while matchdata
        matches.push matchdata[2]
        matchdata = regex.match(matchdata.post_match)
      end

      if matches.length > 0
        @time = matches.sort.first
      end
    end



    #detect all player names
    matches = []
    regex = /cs ([0-9]+) \"\\name\\([^\0]*)\\hand/
    rest_content = content
    matchdata = regex.match(rest_content)

    while matchdata
      # damit werden doppelte eintraege durch den letzten aktuellen ueberschrieben
      matches[matchdata[1].to_i - 1568] = matchdata[2]
      rest_content = matchdata.post_match
      matchdata = regex.match(rest_content)
    end

    if matches.length > 0
      # save player names only
      @playernames = []
      matches.each_with_index { |player, number|
        #playernames.push [number, player].join(': ')
        @playernames[number] = player
      }
    end



    # detect player

    playernames = @playernames.compact.sort.uniq
    if playernames.length == 1
      @player = playernames.first
    else
      if @time && @gamemode == 'race' && !@scoreboards.empty? && !playernames.empty?
        min, sec, msec = @time.scan(/^([0-9]+):([0-9]+)\.([0-9]+)$/).flatten.map { |x| x.to_i }
        min = 9 if min > 9                                                      # scoreboard does not support race times > 9:55:999; max minute value is 9 !
        t = "#{min}#{sec}#{msec}"
        regex = Regexp.new("&p ([0-9]+) #{t}")
        playerids = @scoreboards.join('').scan(regex).flatten.uniq
        if playerids.length == 1
          @player = @playernames[playerids.first.to_i]
        end
      end
    end
    
    # detect players & spectators
    @scoreboards.each do |scoreboard|
      regex = /&\w\s+(:?\d+\s+)+/
      match = regex.match(scoreboard)
      
      while match
        puts match.to_a.inspect
        player = DemoPlayer.from_scoreboard(@gamemode, @playernames, match[0])
        if player && !player.spectator
          @players.reject! { |p| p.number == player.number }
          @players << player
        elsif player && player.spectator
          @spectators.reject! { |p| p.number == player.number }
          @spectators << player
        end
        match = regex.match(match.post_match)
      end
    end
    
    # add stats to players
    @players.each do |player|
      stat = @stats.select { |s| s =~ /plstats 0 " #{player.number}/ }.last
      player.stats = DemoWeaponStat.from_plstats(stat)
    end

    @valid = true
  end


  def time_in_msec
    return @time_in_msec unless @time_in_msec.nil?

    # time str to int
    if @time.kind_of? String
      min, sec, msec = @time.scan(/^([0-9]+):([0-9]+)\.([0-9]+)$/).flatten.map { |x| x.to_i }
      @time_in_msec = msec + sec * 1000 + min * 60 * 1000
    end
  end
end