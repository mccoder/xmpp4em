#encoding: utf-8
require 'stringio'
require 'rexml/parsers/sax2parser'

require 'xmpp4r/idgenerator'
require 'xmpp4r/xmppstanza'
require 'xmpp4r/iq'
require 'xmpp4r/message'
require 'xmpp4r/presence'

module XMPP4EM
  
  class BaseConnection < EventMachine::Connection
    
    def initialize host, port=5222
      @host, @port = host, port
      @client = nil
    end
    attr_accessor :client, :host, :port, :logger
    
    def connection_completed
      @logger.debug{'connected'} if @logger
      @stream_features, @stream_mechanisms = {}, []
      @keepalive = EM::Timer.new(60){ send_data("\n") }
      @client.on(:connected)
      init
    end
    attr_reader :stream_features
    
    include EventMachine::XmlPushParser
    
    def encode2utf8(text)
      text.respond_to?(:force_encoding) ? text.force_encoding("utf-8") : text
    end
    
    def start_element name, attrs
      e = REXML::Element.new(name)
      attrs.each { |name, value|
        e.add_attribute(name, encode2utf8(value))
      }
      
      @current = @current.nil? ? e : @current.add_element(e)
      
      if @current.name == 'stream' and not @started
        @started = true
        process
        @current = nil
      end
    end
    
    def end_element name
      if name == 'stream:stream' and @current.nil?
        @started = false
      else
        if @current.parent
          @current = @current.parent
        else
          process
          @current = nil
        end
      end
    end
    
    def characters text
      @current.text = @current.text.to_s + encode2utf8(text) if @current
    end
    
    def error *args
      p ['error', *args]
    end
    
    def receive_data data
      @logger.debug{"<< #{data}"} if @logger
      super
    end
    
    def send data, &blk
      @logger.debug{ ">> #{data}"} if @logger
      send_data data.to_s     
    end
    
    def unbind
      if @keepalive
        @keepalive.cancel
        @keepalive = nil
      end
      @client.on(:disconnect)
      @logger.debug{'disconnected'} if @logger
    end
    
    def reconnect host = @host, port = @port
      super
    end
    
    def init
      send "<?xml version='1.0' ?>" unless @started
      @started = false
      send "<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='#{namespace;}' xml:lang='en' version='1.0' to='#{@host}'>"
    end
    
    private
    
    def  pre_process_stanza(stanza)
    end    
    
    def process
      if @current.namespace('').to_s == '' # REXML namespaces are always strings
        @current.add_namespace(@streamns)
      end
      stanza = @current
      if  'stream'==stanza.prefix
        if 'stream'==stanza.name
          @streamid = stanza.attributes['id']      
          #All connections has the same namespace
          @streamns = 'jabber:client'    
        end
        pre_process_stanza(stanza)	 
      end
      # Any stanza, classes are registered by XMPPElement::name_xmlns
      begin
        stanza = Jabber::XMPPStanza::import(@current)
      rescue Jabber::NoNameXmlnsRegistered
        stanza = @current
      end
      @client.receive(stanza)
    end
  end
  
end
