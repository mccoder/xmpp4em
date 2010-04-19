module XMPP4EM
  class NotConnected < Exception; end

  autoload :ClientConnection, 'xmpp4em/client_connection'
  autoload :Client, 'xmpp4em/client'
  autoload :BaseClient, 'xmpp4em/base_client'  
  autoload :ComponentConnection, 'xmpp4em/component_connection'
  autoload :BaseConnection, 'xmpp4em/base_connection'
  autoload :Component, 'xmpp4em/component'
end
