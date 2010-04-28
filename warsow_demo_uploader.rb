## EDIT THESE SETTINGS ##

# The path to your directory of server recorded demos.
DEMO_DIRECTORY = '/Users/nagash/.warsow/basewsw/demos/server'

# The path to your console log files ('logconsole' server directive).
# One for each server
CONSOLE_LOGFILES = [ '/Users/nagash/.warsow/basewsw/wswconsole.log' ]

# The Username you use to login
USERNAME = 'username'
# The Password you use to login
PASSWORD = 'password'

# How often to scan for new demos (default: every 10 minutes)
# Leave commented out if you wish to use cron.
# SLEEP_TIME = 60 * 10

# History file - used so that the same demo is not uploaded twice.
HIST_FILE = DEMO_DIRECTORY + '/wswuploader_hist.txt'

## DONT EDIT BELOW THIS LINE ##

POST_URL = "http://#{USERNAME}:#{PASSWORD}@localhost:4000/demos"

require 'net/http'
require 'uri'

module Nagash
  module Warsow
    VERSION = 0.1
    
    class ConsoleParser
      FRAG_PATTERNS = [
        /^(.*?) tried to invade (.*?)'s personal space$/
        /^(.*?) was impaled by (.*?)'s gunblade$/
        /^(.*?) was popped by (.*?)'s grenade$/
        /^(.*?) was instagibbed by (.*?)'s instabeam$/
        /^(.*?) was impaled by (.*?)'s gunblade$/
        /^(.*?) was killed by (.*?)'s (?:almighty gunblade|riotgun)$/,
        /^(.*?) was impaled by (.*?)'s gunblade$/,
        /^(.*?) was cut by (.*?)'s lasergun$/,
        /^(.*?) didn't see (.*?)'s grenade$/,
        /^(.*?) almost dodged (.*?)'s rocket$/,
        /^(.*?) ate (.*?)'s rocket$/,
        /^(.*?) was bolted by (.*?)'s electrobolt$/,
        /^(.*?) was melted by (.*?)'s plasmagun$/
        ]
      
      SUICIDE_PATTERNS = [
        /^(.*?) [0-9^]*?suicides$/,
        /^(.*?) [0-9^]*?cratered$/,
        /^(.*?) [0-9^]*?was squished$/,
        /^(.*?) [0-9^]*?sank like a rock$/,
        /^(.*?) [0-9^]*?melted$/,
        /^(.*?) [0-9^]*?sacrificed to the lava god$/,
        /^(.*?) [0-9^]*?blew up$/,
        /^(.*?) [0-9^]*?found a way out$/,
        /^(.*?) [0-9^]*?saw the light$/,
        /^(.*?) [0-9^]*?got blasted$/,
        /^(.*?) [0-9^]*?was in the wrong place$/,
        /^(.*?) [0-9^]*?killed (itself|herself|himself)$/,
        /^(.*?) [0-9^]*?was killed by$/
        ]
      
      DEFAULT_START_PATTERN = /^(?:All players are ready.  Match starting!|Recording server demo:)/
      DEFAULT_END_PATTERN = /^(?:Timelimit hit.|Scorelimit hit.|Fraglimit hit.|Stopped server demo recording:)/
      
      attr_accessor :players
      
      def initialize(logfile)
        raise "Log file not found" unless File.exists?(logfile) && File.file?(logfile)
        @logfile = File.new(logfile)
        @players = []
      end
      
      def self.parse_section(logfile, start_pattern = DEFAULT_START_PATTERN, end_pattern = DEFAULT_END_PATTERN)
        new(logfile).parse_section(start_pattern, end_pattern)
      end
      
      def parse_section(start_pattern = DEFAULT_START_PATTERN, end_pattern = DEFAULT_END_PATTERN)
        do_parse = false
        @logfile.each do |line|
          do_parse = true if line =~ start_pattern
          do_parse = false if line =~ end_pattern
          parse_line(line) if do_parse
        end
        @logfile.rewind
      end
      
      def parse_line(line)
        add_players(line) if has_players?(line)
        # Parse anything else?
      end
      
      def add_players(line)
        match = nil
        if kill_match?(line)
          match = line.match(FRAG_PATTERNS.detect { |p| line =~ p })
        else
          match = line.match(SUICIDE_PATTERNS.detect { |p| line =~ p })
        end
        
        if match[2]
          player = @players.detect { |p| p.name == match[2] } || Nagash::Warsow::ConsolePlayer.new(match[2])
          player.score += 1
          @players << player unless @players.include?(player)
        end
        
        if match[1]
          player = @players.detect { |p| p.name == match[1] } || Nagash::Warsow::ConsolePlayer.new(match[1])
          player.score -= 1 if death_match?(line)
          @players << player unless @players.include?(player)
        end

        @players
      end
      
      def has_players?(line)
        kill_match?(line) || death_match?(line)
      end
      
      def kill_match?(line)
        FRAG_PATTERNS.any? { |p| line =~ p }
      end
      
      def death_match?(line)
        SUICIDE_PATTERNS.any? { |p| line =~ p }
      end
    end
    
    class ConsolePlayer
      attr_accessor :name, :score
      
      def initialize(name)
        @name = name
        @score = 0
      end
    end
    
    module Multipart

      class Param
        attr_accessor :key, :value
        def initialize(key, value)
          @key   = key
          @value = value
        end

        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"\r\n\r\n#{value}\r\n)
        end
      end

      class FileParam
        attr_accessor :key, :filename, :content
        def initialize(key, filename, content)
          @key      = key
          @filename = filename
          @content  = content
        end

        def to_multipart
          return %(Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n) + "Content-Type: application/octect-stream\r\n\r\n" + content + "\r\n"
        end
      end

      class Post
        BOUNDARY = '----------0xKhTmLbOuNdArY'
        CONTENT_TYPE = "multipart/form-data, boundary=" + BOUNDARY

        def initialize(params = {}, prefix = nil)
          @multipart_params = []
          push_params(params, prefix)
        end

        def push_params(params, prefix = nil)
          params.sort_by {|k| k.to_s}.each do |key, value|
            param_key = prefix.nil? ? key : "#{prefix}[#{key}]"
            if value.respond_to?(:read)
              @multipart_params << FileParam.new(param_key, value.path, value.read)
            else
              if value.is_a?(Hash)
                value.keys.each do |k|
                  push_params(value, param_key)
                end
              else
                @multipart_params << Param.new(param_key, value)
              end
            end
          end
        end

        def to_multipart
          query = @multipart_params.collect { |param| "--" + BOUNDARY + "\r\n" + param.to_multipart }.join("") + "--" + BOUNDARY + "--"
          return query, CONTENT_TYPE
        end
      end 

    end    
    
    class Demo
      attr_accessor :map, :gametype, :players, :protocol, :filename
      
      def initialize(filename)
        @filename = filename
        match = @filename.match(/\d\d\d\d-\d\d-\d\d_\d\d-\d\d_([\d\w]+)_([\d\w]+)_(.+?)_vs_(.+?)_auto(\d\d\d\d).wd(\d+)/)
        @gametype, @map, @protocol = match[1], match[2], match[5]
        @player = [ match[3], match[4] ]
      end
    end
    
    
    class Uploader
      def initialize(url)
        @url = URI.parse(url)
      end
      
      def uploaded?(demo)
        return false if !File.exists?(HIST_FILE)
        ret = nil
        File.open(HIST_FILE) do |file|
          ret = file.detect { |line| line =~ /^#{Regexp.escape(File.basename(demo.filename))}$/ }
        end
        ret
      end
      
      def upload(demo, opts = {})
        # upload the file
        puts "Starting to upload #{File.basename(demo.filename)}..."
        
        File.open(HIST_FILE, 'a+') do |file|
          file.puts(File.basename(demo.filename))
        end
        
        file = File.new(demo.filename)
        opts.merge!('demo[uploaded_data]' => file)
        
        data, content_type = Nagash::Warsow::Multipart::Post.new(opts).to_multipart
        
        file.close
        
        req = Net::HTTP::Post.new(@url.path, 'Content-Type' => content_type, 'Accept' => 'application/xml')
        req.body = data
        req.basic_auth @url.user, @url.password if @url.user
        Net::HTTP.start(@url.host, @url.port) do |http|
          res = http.request(req)
          begin
            res.value
            puts "Uploaded Successfully :)"
          rescue
            puts "Upload Failed :("
          end
        end
      end
    end
    
    
    class Scanner
      def initialize(directory, uploader, parser)
        @directory = directory
        @uploader = uploader
        @parser = parser
      end
      
      def scan
        Dir["#{@directory}/*.wd10"].each do |filename|
          demo = Nagash::Warsow::Demo.new(filename)
          next if demo.gametype != 'duel' || @uploader.uploaded?(demo)
          
          @parser.parse_section(/Recording server demo:(.*?)#{Regexp.escape(File.basename(filename))}/,
                                /Stopped server demo recording:(.*?)#{Regexp.escape(File.basename(filename))}/)
          
          params = {}
          @parser.players.each_with_index do |player, idx|
            params.merge!("players[#{idx}][colored_name]" => player.name,
                        "players[#{idx}][score]" => player.score)
          end
          
          @uploader.upload(demo, params)
        end
      end
    end
    
  end
end

uploader = Nagash::Warsow::Uploader.new(POST_URL)
parser = Nagash::Warsow::ConsoleParser.new(CONSOLE_LOGFILE)
scanner = Nagash::Warsow::Scanner.new(DEMO_DIRECTORY, uploader, parser)

if Object.const_defined?('SLEEP_TIME')
  while true do
    puts "Scanning.."
    scanner.scan
    sleep SLEEP_TIME
  end
else
  scanner.scan
end
  