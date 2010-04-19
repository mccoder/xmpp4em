#encoding: utf-8

module XMPP4EM
  
  class ClientConnection < BaseConnection     
    def namespace; 'jabber:client'; end;
    
    private
    def pre_process_stanza(stanza)   
      return if 'stream'!=stanza.prefix && 'features'!=stanza.name
      @stream_features, @stream_mechanisms = {}, []
      stanza.each do |e|
        if e.name == 'mechanisms' and e.namespace == 'urn:ietf:params:xml:ns:xmpp-sasl'
          e.each_element('mechanism') do |mech|
            @stream_mechanisms.push(mech.text)
          end
        else
          @stream_features[e.name] = e.namespace
        end
      end
    end
  end
  
end
