# the following are all standard ruby libraries
require 'net/https'
require 'yaml'
require 'date'
require 'time'
require 'base64'
require 'rexml/document'
require 'rexml/parsers/streamparser'
require 'rexml/parsers/baseparser'
require 'rexml/light/node'

# An interface to the Warsow Demo Server web-services API. Usage is straightforward:
#
#   session = WarsowDemoServer.new('username', 'password')
# 
# Inspiration taken from Basecamp API

class WarsowDemoServer
  DEMO_SERVER_URL = 'http://localhost:4000'
  
  # A wrapper to encapsulate the data returned by WarsowDemoServer, for easier access.
  class Record #:nodoc:
    attr_reader :type

    def initialize(type, hash)
      @type = type
      @hash = hash
    end

    def [](name)
      name = dashify(name)
      case @hash[name]
        when Hash then 
          @hash[name] = (@hash[name].keys.length == 1 && Array === @hash[name].values.first) ?
            @hash[name].values.first.map { |v| Record.new(@hash[name].keys.first, v) } :
            Record.new(name, @hash[name])
        else @hash[name]
      end
    end

    def id
      @hash["id"]
    end

    def attributes
      @hash.keys
    end

    def respond_to?(sym)
      super || @hash.has_key?(dashify(sym))
    end

    def method_missing(sym, *args)
      if args.empty? && !block_given? && respond_to?(sym)
        self[sym]
      else
        super
      end
    end

    def to_s
      "\#<Record(#{@type}) #{@hash.inspect[1..-2]}>"
    end

    def inspect
      to_s
    end

    private

      def dashify(name)
        name.to_s.tr("_", "-")
      end
  end

  # A wrapper to represent a file that should be uploaded. This is used so that
  # the form/multi-part encoder knows when to encode a field as a file, versus
  # when to encode it as a simple field.
  class FileUpload
    attr_reader :filename, :content
    
    def initialize(filename, content)
      @filename = filename
      @content = content
    end
  end

  attr_accessor :use_xml

  # Connects
  def initialize(user_name, password, use_ssl = false)
    @use_xml = true
    @user_name, @password = user_name, password
    connect!(DEMO_SERVER_URL, use_ssl)
  end
  
  # Return list of all demos
  def demos
    get_records "demo", "/demos"
  end
  
  def post_stuff(demo)
    post_record "/demos/stuff", :demo => demo
  end  
  
  # Return list of all players, or all players for a demo if demo_id is provided
  def players(demo_id = nil)
    get_records "player", demo_id ? "/demos/#{demo_id}/players" : "/players"
  end
  
  # Return information about demo with the given id
  def demo(id)
    get_record "/demos/#{id}"
  end
  
  def player(id)
    get_record "/players/#{id}"
  end
  
  # Create a new demo. 
  # 
  # The +file+ parameter should be an instance of WarsowDemoServer::FileUpload
  # demo = { :map => 'wdm5',
  #          :gametype => 'duel',
  #          :protocol => 10,
  #          :local_id => 1906,
  #          :winner => {
  #            :name => 'nagash',
  #            :colored_name => '^3nag^5ash',
  #            :score => 21
  #
  #          },
  #          :loser => {
  #            :name => 'beastrn',
  #            :colored_name => '^6beastrn',
  #            :score => 18
  #          },
  #          :file => WarsowDemoServer::FileUpload.new('mydemo.wd10', File.read('mydemo.wd10'))
  #       }
  #
  def post_demo(demo, file)
    prepare_file(file)
    post_record "/demos", :demo => demo, :asset => file
  end
  
  # Deletes the demo with the given id, and returns it.
  def delete_demo(id)
    delete_record "/demos/#{id}"
  end
    
  # Make a raw web-service request to WarsowDemoServer. This will return a Hash of
  # Arrays of the response, and may seem a little odd to the uninitiated.
  def request(method, path, parameters = {}, second_try = false)
    puts convert_body(parameters)
    response = send(method, path, convert_body(parameters), "Content-Type" => content_type)    

    if response.code.to_i / 100 == 2
      result = Hash.from_xml(response.body)
    elsif response.code == "302" && !second_try
      connect!(@url, !@use_ssl)
      request(path, parameters, true)
    else
      raise "#{response.message} (#{response.code})"
    end
  end
    
  def get_record(path, parameters={})
    result = request(:get, path, parameters)
    to_record(result)
  end
  
  def post_record(path, parameters={})
    result = request(:post, path, parameters)
    to_record(result)
  end
  
  def put_record(path, parameters={})
    result = request(:post, path, prameters.merge('_method' => 'put'))
    to_record(result)
  end
  
  def delete_record(path, parameters={})
    result = request(:post, path, parameters.merge('_method' => 'delete'))
  end
  
  def get_records(node, path, parameters={})
    result = request(:get, path, parameters).values.first or return []
    result = result[node] or return []
    result = [result] unless Array === result
    result.map { |row| Record.new(node, row) }
  end
  
  def to_record(result)
    (result && !result.empty?) ? Record.new(result.keys.first, result.values.first) : nil
  end
    

  # A convenience method for wrapping the result of a query in a Record
  # object. This assumes that the result is a singleton, not a collection.
  def record(path, parameters={})
    result = request(path, parameters)
    (result && !result.empty?) ? Record.new(result.keys.first, result.values.first) : nil
  end

  # A convenience method for wrapping the result of a query in Record
  # objects. This assumes that the result is a collection--any singleton
  # result will be wrapped in an array.
  def records(node, path, parameters={})
    result = request(path, parameters).values.first or return []
    result = result[node] or return []
    result = [result] unless Array === result
    result.map { |row| Record.new(node, row) }
  end

  private

    def connect!(url, use_ssl)
      @use_ssl = use_ssl
      @url = url
      #@connection = Net::HTTP.new(url, use_ssl ? 443 : 80)
      @connection = Net::HTTP.new('localhost', 4000)
      @connection.use_ssl = @use_ssl
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if @use_ssl
    end

    def convert_body(body)
      body = use_xml ? body.to_xml : body.to_yaml
    end

    def content_type
      use_xml ? "application/xml" : "application/x-yaml"
    end
    
    def get(path, body, header={})
      request = Net::HTTP::Get.new(path, header.merge('Accept' => 'application/xml'))
      request.basic_auth(@user_name, @password)
      @connection.request(request)
    end
    
    def post(path, body, header={})
      request = Net::HTTP::Post.new(path, header.merge('Accept' => 'application/xml'))
      request.basic_auth(@user_name, @password)
      @connection.request(request, body)
    end

    def store_file(contents)
      response = post("/assets", contents, 'Content-Type' => 'application/octet-stream',
        'Accept' => 'application/xml')

      if response.code == "200"
        result = Hash.from_xml(response.body)
        return result["asset"]["id"]
      else
        raise "Could not store file: #{response.message} (#{response.code})"
      end
    end

    def translate_entities(value)
      value.gsub(/&lt;/, "<").
            gsub(/&gt;/, ">").
            gsub(/&quot;/, '"').
            gsub(/&apos;/, "'").
            gsub(/&amp;/, "&")
    end

    def prepare_file(file)
      id = store_file(file.content)
      file = { :file => id,
               :content_type => "application/octet-stream" }
    end
end

# A minor hack to let Xml-Simple serialize symbolic keys in hashes
class Symbol
  def [](*args)
    to_s[*args]
  end
end

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def dasherize
    self.gsub(/_/, '-')
  end
  
  # "foo_bar".camel_case #=> "FooBar"
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end      
end

class Array
  
  def to_xml(options = {})
    to_xml_document(options).to_s
  end
  
  def to_xml_document(options = {})
    raise "Not all elements respond to to_xml" unless all? { |e| e.respond_to? :to_xml_document }

    options[:root]     ||= all? { |e| e.is_a?(first.class) && first.class.to_s != "Hash" } ? first.class.to_s.underscore.pluralize : "records"
    options[:children] ||= options[:root][0..-2] # Hmm, very crappy singularization

    doc = REXML::Document.new
    
    root = doc.add_element(options[:root].to_s.dasherize)
    
    each do |value|
      root << value.to_xml_document(:root => options[:children])
    end
    doc
  end
end

class Hash
  XML_TYPE_NAMES = {
    "Symbol"     => "symbol",
    "Fixnum"     => "integer",
    "Bignum"     => "integer",
    "BigDecimal" => "decimal",
    "Float"      => "float",
    "Date"       => "date",
    "DateTime"   => "datetime",
    "Time"       => "datetime",
    "TrueClass"  => "boolean",
    "FalseClass" => "boolean"
  }
  
  XML_FORMATTING = { 
    "symbol" => Proc.new { |symbol| symbol.to_s },
    "date"     => Proc.new { |date| date.to_s },
    "datetime" => Proc.new { |time| time.xmlschema },
    "binary"   => Proc.new { |binary| Base64.encode64(binary) },
    "yaml"     => Proc.new { |yaml| yaml.to_yaml }   
  }
  
  def to_xml(options = {})
    to_xml_document(options).to_s
  end

  def to_xml_document(options = {})
    doc = REXML::Document.new
    
    root = doc.add_element(options[:root].to_s.dasherize)
    
    each do |key, value|
      case value
      when ::Hash
        root << value.to_xml_document(options.merge({ :root => key}))
      when ::Array
        root << value.to_xml_document(options.merge({ :root => key}))
      else
        type_name = XML_TYPE_NAMES[value.class.to_s]
        
        node = root.add_element(key.to_s.dasherize)
        node << REXML::Text.new(XML_FORMATTING[type_name] ? XML_FORMATTING[type_name].call(value) : value.to_s)
        node.attributes["type"] = type_name
      end
    end
    doc
  end
  
  # Converts the hash into xml attributes
  # 
  #   { :one => "ONE", "two"=>"TWO" }.to_xml_attributes
  #   #=> 'one="ONE" two="TWO"'
  # 
  def to_xml_attributes
    map do |k,v|
      %{#{k.to_s.camel_case.sub(/^(.{1,1})/) { |m| m.downcase }}="#{v}"} 
    end.join(' ')
  end
  
  class << self
    # Converts valid XML into a Ruby Hash structure.
    # <tt>xml</tt>:: A string representation of valid XML
    # 
    # == Typecasting
    # Typecasting is performed on elements that have a "<tt>type</tt>" attribute of
    # <tt>integer</tt>:: 
    # <tt>boolean</tt>:: anything other than "true" evaluates to false
    # <tt>datetime</tt>:: Returns a Time object.  See +Time+ documentation for valid Time strings
    # <tt>date</tt>:: Returns a Date object.  See +Date+ documentation for valid Date strings 
    # 
    # Keys are automatically converted to +snake_case+
    #
    # == Caveats
    # * Mixed content tags are assumed to be text and any xml tags are kept as a String
    # * Any attributes other than type on a node containing a text node will be discarded
    #
    # == Examples
    #
    # === Standard 
    # <user gender='m'>
    #   <age type='integer'>35</age>
    #   <name>Home Simpson</name>
    #   <dob type='date'>1988-01-01</dob>
    #   <joined-at type='datetime'>2000-04-28 23:01</joined-at>
    #   <is-cool type='boolean'>true</is-cool>
    # </user>
    #
    # evaluates to 
    # 
    # { "user" => 
    #         { "gender"    => "m",
    #           "age"       => 35,
    #           "name"      => "Home Simpson",
    #           "dob"       => DateObject( 1998-01-01 ),
    #           "joined_at" => TimeObject( 2000-04-28 23:01),
    #           "is_cool"   => true 
    #         }
    #     }
    #
    # === Mixed Content
    # <story>
    #   A Quick <em>brown</em> Fox
    # </story>
    #
    # evaluates to
    # { "story" => "A Quick <em>brown</em> Fox" }
    # 
    # === Attributes other than type on a node containing text
    # <story is-good='fasle'>
    #   A Quick <em>brown</em> Fox
    # </story>
    #
    # evaluates to
    # { "story" => "A Quick <em>brown</em> Fox" }
    #
    # <bicep unit='inches' type='integer'>60</bicep>
    #
    # evaluates with a typecast to an integer.  But ignores the unit attribute
    # { "bicep" => 60 }
    def from_xml( xml )
      ToHashParser.from_xml(xml)
    end
  end
end

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the underlying
# parser
class REXMLUtilityNode # :nodoc:
  attr_accessor :name, :attributes, :children

  def initialize(name, attributes = {})
    @name       = name.tr("-", "_")
    @attributes = undasherize_keys(attributes)
    @children   = []
    @text       = false
  end

  def add_node(node)
    @text = true if node.is_a? String
    @children << node
  end

  def to_hash
    if @text || attributes.has_key?('type') || (attributes.empty? && children.empty?)
      return { name => typecast_value( translate_xml_entities( inner_html ) ) }
    else
      #change repeating groups into an array
      # group by the first key of each element of the array to find repeating groups
      groups = @children.inject({}) { |s,e| (s[e.name] ||= []) << e; s }
      
      hash = {}
      groups.each do |key, values|
        if values.size == 1
          hash.merge! values.first
        else
          hash.merge! key => values.map { |element| element.to_hash[key] }
        end
      end
      
      # merge the arrays, including attributes
      hash.merge! attributes unless attributes.empty?
      
      { name => hash }
    end
  end

  def typecast_value(value)
    puts value
    return value unless attributes["type"]
    
    case attributes["type"]
      when "integer"  then value.to_i
      when "boolean"  then value.strip == "true"
      when "datetime" then ::Time.parse(value).utc
      when "date"     then ::Date.parse(value)
      #when "array"    then puts @children.inspect
      else                 value
    end
  end

  def translate_xml_entities(value)
    value.gsub(/&lt;/,   "<").
          gsub(/&gt;/,   ">").
          gsub(/&quot;/, '"').
          gsub(/&apos;/, "'").
          gsub(/&amp;/,  "&")
  end

  def undasherize_keys(params)
    params.keys.each do |key, vvalue|
      params[key.tr("-", "_")] = params.delete(key)
    end
    params
  end

  def inner_html
    @children.join
  end

  def to_html
    "<#{name}#{attributes.to_xml_attributes}>#{inner_html}</#{name}>"
  end

  def to_s 
    to_html
  end
end

class ToHashParser # :nodoc:

  def self.from_xml(xml)
    stack = []
    parser = REXML::Parsers::BaseParser.new(xml)
    
    while true
      event = parser.pull
      case event[0]
      when :end_document
        break
      when :end_doctype, :start_doctype
        # do nothing
      when :start_element
        stack.push REXMLUtilityNode.new(event[1], event[2])
      when :end_element
        if stack.size > 1
          temp = stack.pop
          stack.last.add_node(temp)
        end
      when :text, :cdata
        stack.last.add_node(event[1]) unless event[1].strip.length == 0
      end
    end
    stack.pop.to_hash
  end
end
