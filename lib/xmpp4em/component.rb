#encoding: utf-8

module XMPP4EM
  
  class Component < BaseClient    
    def initialize user, pass, opts = {}
      super
    end
   
    def jid
      @jid ||= @user.kind_of?(Jabber::JID) ? @user :  Jabber::JID.new(@user)               
    end
    
    def connect host = jid.domain, port = 5222
      EM.connect host, port, ComponentConnection, jid.domain, port do |conn|
        @connection = conn
        conn.client = self
      end
    end
    
    def receive_stanza(stanza)
      
      case stanza.name
        when 'stream'
        if !@authenticated && jid.domain == stanza.attributes['from']
          streamid = stanza.attributes['id']
          hash = Digest::SHA1::hexdigest(streamid.to_s + @pass)      
          send("<handshake>#{hash}</handshake>")          
        end
        return true
        when 'not-authorized'  
        on(:error, 'not-authorized')
        return true
        when 'handshake'        
        @authenticated = true
        on(:login, stanza)
        return true
      end  
      
      false
      
    end
    
  end
end