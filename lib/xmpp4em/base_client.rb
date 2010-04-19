#encoding: utf-8
require 'rubygems'

require 'stringio'
require 'rexml/parsers/sax2parser'

require 'xmpp4r/idgenerator'
require 'xmpp4r/xmppstanza'
require 'xmpp4r/iq'
require 'xmpp4r/message'
require 'xmpp4r/presence'
require 'resolv'

require 'eventmachine'
require 'evma_xmlpushparser'
EM.epoll

module XMPP4EM
  
  class BaseClient
    include EM::Deferrable
    
    def initialize user, pass, logger=nil,opts = {}
      @user = user
      @pass = pass
      @logger=logger
      @deferred_status =:succeeded
      @connection = nil
      @authenticated = false
      @opts = opts
      @auth_callback = nil
      @id_callbacks  = {}
      @on_stanza=nil
      @events_callbacks = {
        :message    => [],
        :presence   => [],
        :iq         => [],
        :exception  => [],
        :login      => [],
        :disconnect => [],
        :connected  => []
      }     
      
      on(:disconnect) do
        @deferred_status = nil
        @authenticated=false
      end         
      on(:login) do
        succeed
      end    
    end
    attr_reader :connection, :user
    
    def reconnect
      @connection.close_connection_after_writing
      @deferred_status = nil
      connect
    end
    
    def connected?
      @connection and !@connection.error?
    end
        
    def register_stanza &blk          
      @on_stanza = blk if block_given?
    end       
    
    def send data, safe=false,  &blk
      
      if block_given? and data.is_a? Jabber::XMPPStanza
        if data.id.nil?
          data.id = Jabber::IdGenerator.instance.generate_id
        end
        @id_callbacks[ data.id ] = blk
      end
      if safe
        callback {   @connection.send(data) }
      else
        @connection.send(data)
      end
    end
    
    def close
      @connection.close_connection_after_writing
      @deferred_status = nil
      @connection = nil
    end
    alias :disconnect :close
        
    def receive stanza
      if stanza.kind_of?(Jabber::XMPPStanza) and stanza.id and blk = @id_callbacks[ stanza.id ]
        @id_callbacks.delete stanza.id
        blk.call(stanza)
        return
      end
      
      return if receive_stanza(stanza)      
      return if @on_stanza && @on_stanza.call(stanza)  
      
      case stanza
        when Jabber::Message then  on(:message, stanza)
        when Jabber::Iq then  on(:iq, stanza)
        when Jabber::Presence then on(:presence, stanza)
      end
    end
    
    def on type, *args, &blk
      if blk
        @events_callbacks[type] << blk
      else
        @events_callbacks[type].each do |blk|
          blk.call(*args)
        end
      end
    end
    
    def add_message_callback  (&blk) on :message,   &blk end
    def add_presence_callback (&blk) on :presence,  &blk end
    def add_iq_callback       (&blk) on :iq,        &blk end
    def on_exception          (&blk) on :exception, &blk end
  end
end
