require 'builder'
require 'base64'

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
end

class Array
  def to_xml(options = {})
    raise "Not all elements respond to to_xml" unless all? { |e| e.respond_to? :to_xml }

    options[:root]     ||= all? { |e| e.is_a?(first.class) && first.class.to_s != "Hash" } ? first.class.to_s.underscore.pluralize : "records"
    options[:children] ||= options[:root].singularize
    options[:indent]   ||= 2
    options[:builder]  ||= Builder::XmlMarkup.new(:indent => options[:indent])

    root     = options.delete(:root)
    children = options.delete(:children)

    options[:builder].instruct! unless options.delete(:skip_instruct)
    options[:builder].tag!(root.to_s.dasherize) { each { |e| e.to_xml(options.merge({ :skip_instruct => true, :root => children })) } }       
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
  
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end

  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    options.reverse_merge!({ :builder => Builder::XmlMarkup.new(:indent => options[:indent]), :root => "hash" })
    options[:builder].instruct! unless options.delete(:skip_instruct)

    options[:builder].__send__(options[:root].to_s.dasherize) do
      each do |key, value|
        case value
        when ::Hash
          value.to_xml(options.merge({ :root => key, :skip_instruct => true }))
        when ::Array
          value.to_xml(options.merge({ :root => key, :children => key.to_s.singularize, :skip_instruct => true}))
        else
          type_name = XML_TYPE_NAMES[value.class.to_s]

          options[:builder].tag!(key.to_s.dasherize, 
          XML_FORMATTING[type_name] ? XML_FORMATTING[type_name].call(value) : value,
          options[:skip_types] || value.nil? || type_name.nil? ? { } : { :type => type_name }
          )
        end
      end
    end
  end
end

class DateTime
  def xmlschema
    strftime("%Y-%m-%dT%H:%M:%S%Z")
  end
end

module DataMapper #:nodoc:
  module Persistence
    def attribute_names
      self.class.properties.map { |p| p.name.to_s }
    end

    module ClassMethods
      def columns_hash
        @columns_hash ||= self.properties.inject({}) { |hash, column| hash[column.name.to_s] = column; hash }
      end
    end
  end

  module Support
    module Serialization
      # Builds an XML document to represent the model.   Some configuration is
      # availble through +options+, however more complicated cases should use 
      # override ActiveRecord's to_xml.
      #
      # By default the generated XML document will include the processing 
      # instruction and all object's attributes.  For example:
      #    
      #   <?xml version="1.0" encoding="UTF-8"?>
      #   <topic>
      #     <title>The First Topic</title>
      #     <author-name>David</author-name>
      #     <id type="integer">1</id>
      #     <approved type="boolean">false</approved>
      #     <replies-count type="integer">0</replies-count>
      #     <bonus-time type="datetime">2000-01-01T08:28:00+12:00</bonus-time>
      #     <written-on type="datetime">2003-07-16T09:28:00+1200</written-on>
      #     <content>Have a nice day</content>
      #     <author-email-address>david@loudthinking.com</author-email-address>
      #     <parent-id></parent-id>
      #     <last-read type="date">2004-04-15</last-read>
      #   </topic>
      #
      # This behavior can be controlled with :only, :except,
      # :skip_instruct, :skip_types and :dasherize.  The :only and
      # :except options are the same as for the #attributes method.
      # The default is to dasherize all column names, to disable this,
      # set :dasherize to false.  To not have the column type included
      # in the XML output, set :skip_types to false.
      #
      # For instance:
      #
      #   topic.to_xml(:skip_instruct => true, :except => [ :id, :bonus_time, :written_on, :replies_count ])
      #
      #   <topic>
      #     <title>The First Topic</title>
      #     <author-name>David</author-name>
      #     <approved type="boolean">false</approved>
      #     <content>Have a nice day</content>
      #     <author-email-address>david@loudthinking.com</author-email-address>
      #     <parent-id></parent-id>
      #     <last-read type="date">2004-04-15</last-read>
      #   </topic>
      # 
      # To include first level associations use :include
      #
      #   firm.to_xml :include => [ :account, :clients ]
      #
      #   <?xml version="1.0" encoding="UTF-8"?>
      #   <firm>
      #     <id type="integer">1</id>
      #     <rating type="integer">1</rating>
      #     <name>37signals</name>
      #     <clients>
      #       <client>
      #         <rating type="integer">1</rating>
      #         <name>Summit</name>
      #       </client>
      #       <client>
      #         <rating type="integer">1</rating>
      #         <name>Microsoft</name>
      #       </client>
      #     </clients>
      #     <account>
      #       <id type="integer">1</id>
      #       <credit-limit type="integer">50</credit-limit>
      #     </account>
      #   </firm>
      #
      # To include any methods on the object(s) being called use :methods
      #
      #   firm.to_xml :methods => [ :calculated_earnings, :real_earnings ]
      #
      #   <firm>
      #     # ... normal attributes as shown above ...
      #     <calculated-earnings>100000000000000000</calculated-earnings>
      #     <real-earnings>5</real-earnings>
      #   </firm>
      #
      # To call any Proc's on the object(s) use :procs.  The Proc's
      # are passed a modified version of the options hash that was
      # given to #to_xml.
      #
      #   proc = Proc.new { |options| options[:builder].tag!('abc', 'def') }
      #   firm.to_xml :procs => [ proc ]
      #
      #   <firm>
      #     # ... normal attributes as shown above ...
      #     <abc>def</abc>
      #   </firm>
      #
      # You may override the to_xml method in your ActiveRecord::Base
      # subclasses if you need to.  The general form of doing this is
      #
      #   class IHaveMyOwnXML < ActiveRecord::Base
      #     def to_xml(options = {})
      #       options[:indent] ||= 2
      #       xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      #       xml.instruct! unless options[:skip_instruct]
      #       xml.level_one do
      #         xml.tag!(:second_level, 'content')
      #       end
      #     end
      #   end
      def to_xml(options = {})
        defaults = { :root => Inflector.underscore(self.class.name) }
        DataMapper::XmlSerializer.new(self, defaults.merge(options)).to_s
      end
    end
  end

  class XmlSerializer #:nodoc:
    attr_reader :options

    def initialize(record, options = {})
      @record, @options = record, options.dup
    end

    def builder
      @builder ||= begin
        options[:indent] ||= 2
        builder = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

        unless options[:skip_instruct]
          builder.instruct!
          options[:skip_instruct] = true
        end

        builder
      end
    end

    def root
      root = (options[:root] || Inflector.underscore(@record.class.to_s)).to_s
      dasherize? ? root.dasherize : root
    end

    def dasherize?
      !options.has_key?(:dasherize) || options[:dasherize]
    end


    # To replicate the behavior in ActiveRecord#attributes,
    # :except takes precedence over :only.  If :only is not set
    # for a N level model but is set for the N+1 level models,
    # then because :except is set to a default value, the second
    # level model can have both :except and :only set.  So if
    # :only is set, always delete :except.
    def serializable_attributes
      attribute_names = @record.attribute_names

      if options[:only]
        options.delete(:except)
        attribute_names = attribute_names & Array(options[:only]).collect { |n| n.to_s }
      else
        options[:except] = Array(options[:except])
        attribute_names = attribute_names - options[:except].collect { |n| n.to_s }
      end

      attribute_names.collect { |name| Attribute.new(name, @record) }
    end

    def serializable_method_attributes
      Array(options[:methods]).collect { |name| MethodAttribute.new(name.to_s, @record) }
    end


    def add_attributes
      (serializable_attributes + serializable_method_attributes).each do |attribute|
        add_tag(attribute)
      end
    end

    def add_includes
      if include_associations = options.delete(:include)
        root_only_or_except = { :except => options[:except], :only => options[:only] }

        include_has_options = include_associations.is_a?(Hash)

        for association in include_has_options ? include_associations.keys : Array(include_associations)
          association_options = include_has_options ? include_associations[association] : root_only_or_except

          opts = options.merge(association_options)

          case @record.class.reflect_on_association(association).macro
          when :has_many, :has_and_belongs_to_many
            records = @record.send(association).to_a
            unless records.empty?
              tag = records.first.class.to_s.underscore.pluralize
              tag = tag.dasherize if dasherize?

              builder.tag!(tag) do
                records.each { |r| r.to_xml(opts.merge(:root => association.to_s.singularize)) }
              end
            end
          when :has_one, :belongs_to
            if record = @record.send(association)
              record.to_xml(opts.merge(:root => association))
            end
          end
        end

        options[:include] = include_associations
      end
    end

    def add_procs
      if procs = options.delete(:procs)
        [ *procs ].each do |proc|
          proc.call(options)
        end
      end
    end


    def add_tag(attribute)
      builder.tag!(
      dasherize? ? attribute.name.dasherize : attribute.name, 
      attribute.value.to_s, 
      attribute.decorations(!options[:skip_types])
      )
    end

    def serialize
      args = [root]
      if options[:namespace]
        args << {:xmlns=>options[:namespace]}
      end

      builder.tag!(*args) do
        add_attributes
        add_includes
        add_procs
      end
    end        

    alias_method :to_s, :serialize

    class Attribute #:nodoc:
      attr_reader :name, :value, :type

      def initialize(name, record)
        @name, @record = name, record

        @type  = compute_type
        @value = compute_value
      end

      # There is a significant speed improvement if the value
      # does not need to be escaped, as #tag! escapes all values
      # to ensure that valid XML is generated.  For known binary
      # values, it is at least an order of magnitude faster to
      # Base64 encode binary values and directly put them in the
      # output XML than to pass the original value or the Base64
      # encoded value to the #tag! method. It definitely makes
      # no sense to Base64 encode the value and then give it to
      # #tag!, since that just adds additional overhead.
      def needs_encoding?
        ![ :binary, :date, :datetime, :boolean, :float, :integer ].include?(type)
      end

      def decorations(include_types = true)
        decorations = {}

        if type == :binary
          decorations[:encoding] = 'base64'
        end

        if include_types && type != :string
          decorations[:type] = type
        end

        decorations
      end

      protected
      def compute_type
        type = @record.class.columns_hash[name].type

        case type
        when :text
          :string
        when :time
          :datetime
        else
          type
        end
      end

      def compute_value
        value = @record.send(name)

        if formatter = Hash::XML_FORMATTING[type.to_s]
          value ? formatter.call(value) : nil
        else
          value
        end
      end
    end

    class MethodAttribute < Attribute #:nodoc:
      protected
      def compute_type
        Hash::XML_TYPE_NAMES[@record.send(name).class.name] || :string
      end
    end
  end
end
