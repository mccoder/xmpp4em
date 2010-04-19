#encoding: utf-8
require 'xmpp4em'

started = Time.now
users = {}
connected = 0

EM.epoll

EM.run{  
  user = XMPP4EM::Component.new("test.localhost", 'secret')
  user.on(:login) do
    connected += 1
    p ['connected', "#{connected}"]  
    
    p ['done', Time.now - started]
    #EM.stop_event_loop      
  end
  user.on(:iq) do |stanza|
	p ["IQ",stanza]
	stanza.to,stanza.from=stanza.from,stanza.to
	user.send stanza
  end
  user.on(:message) do |stanza|
	p ["message", stanza]
	stanza.to,stanza.from=stanza.from,stanza.to
	user.send stanza
  end
  user.on(:presence) do |stanza|
	p ["presence", stanza]
	stanza.to,stanza.from=stanza.from,stanza.to
	user.send stanza
  end
  user.on(:disconnect) do
    p ['disconnected']
  end
  
  user.connect('127.0.0.1', 5555)  
}