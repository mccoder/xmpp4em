#encoding: utf-8
require 'xmpp4r/sasl'
require 'resolv'

module XMPP4EM
  
  class Client < BaseClient
    
    def initialize user, pass, logger=nil, opts = {}
      super      
      @opts = { :auto_register => false }.merge(opts)        
    end
    
    def jid
      @jid ||= if @user.kind_of?(Jabber::JID)
        @user
      else
        @user =~ /@/ ? Jabber::JID.new(@user) : Jabber::JID.new(@user, 'localhost')
      end
    end
    
    def connect host = jid.domain, port = 5222
      #if host=='localhost' || host=='127.0.0.1' || %r{^([0-9]{1,3}.){3}[0-9]{1,3}$}.match(host)
        target_host, target_port= host, port
      #else
       # target_host, target_port = resolve_host(host)
      #end
      EM.connect target_host, target_port, ClientConnection, jid.domain, port do |conn|
        @connection = conn
        conn.client = self
	conn.logger=@logger
      end
    end   
    
    def resolve_host(domain)
      srv = []
      begin        
        Resolv::DNS.open { |dns|
          # If ruby version is too old and SRV is unknown, this will raise a NameError
          # which is catched below
          #debug("RESOLVING:\n_xmpp-client._tcp.#{domain} (SRV)")
          srv = dns.getresources("_xmpp-client._tcp.#{domain}", Resolv::DNS::Resource::IN::SRV)
        }
      rescue NameError
        
      end
      
      unless srv.blank?
        # Sort SRV records: lowest priority first, highest weight first
        srv.sort! { |a,b| (a.priority != b.priority) ? (a.priority <=> b.priority) : (b.weight <=> a.weight) }        
        #debug "USING #{srv.first.target.to_s}"
        return srv.first.target.to_s, srv.first.port
      else
        #debug "USING #{domain}:5222"          
        return domain, 5222
      end
      
    end
    
    def login &blk
      Jabber::SASL::new(self, 'PLAIN').auth(@pass)
      @auth_callback = blk if block_given?
    end
    
    def register &blk
      reg = Jabber::Iq.new_register(jid.node, @pass)
      reg.to = jid.domain
      
      send(reg){ |reply|
        blk.call( reply.type == :result ? :success : reply.type )
      }
    end 
    
    def send_msg to, msg
      send_safe Jabber::Message::new(to, msg).set_type(:chat)
    end
    
    def receive_stanza(stanza)
      
      case stanza.name
        when 'features'
        unless @authenticated
          login do |res|
            # log ['login response', res].inspect
            if res == :failure and @opts[:auto_register]
              register do |res|
                #p ['register response', res]
                login unless res == :error
              end
            end
          end
          
        else
          if @connection.stream_features.has_key? 'bind'
            iq = Jabber::Iq.new(:set)
            bind = iq.add REXML::Element.new('bind')
            bind.add_namespace @connection.stream_features['bind']            
            resource = bind.add REXML::Element.new('resource')
            resource.text=jid.resource
            
            send(iq){ |reply|
              if reply.type == :result and jid = reply.first_element('//jid') and jid.text
                # log ['new jid is', jid.text].inspect
                @jid = Jabber::JID.new(jid.text)
              end
            }
          end
          
          if @connection.stream_features.has_key? 'session'
            iq = Jabber::Iq.new(:set)
            session = iq.add REXML::Element.new('session')
            session.add_namespace @connection.stream_features['session']
            
            send(iq){ |reply|
              if reply.type == :result
                on(:login, stanza)
              end
            }
          end
        end
        
        return true
        
        when 'success', 'failure'
        if stanza.name == 'success'
          @authenticated = true
          @connection.reset_parser
          @connection.init
        end
        
        @auth_callback.call(stanza.name.to_sym) if @auth_callback
        return true
      end
      false
    end    
    
  end
end
