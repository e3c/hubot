Robot   = require '../robot'
Adapter = require '../adapter'

Xmpp    = require 'node-xmpp'


class Gtalkbot extends Adapter
  run: ->
    Xmpp.JID.prototype.from = -> @bare().toString()

    @name = @robot.name

    # Client Options
    @options =
      login_url: process.env.HUBOT_LOGIN_URL
      username: process.env.HUBOT_GTALK_USERNAME
      password: process.env.HUBOT_GTALK_PASSWORD
      host: 'talk.google.com'
      port: 5222
      keepaliveInterval: 15000 # ms interval to send query to gtalk server

    if not @options.username or not @options.password
      throw new Error('You need to set HUBOT_GTALK_USERNAME and HUBOT_GTALK_PASSWORD anv vars for gtalk to work')

    # Connect to gtalk servers
    @client = new Xmpp.Client
      jid: @options.username
      password: @options.password
      host: @options.host
      port: @options.port

    # Events
    @client.on 'online', => @online()
    @client.on 'stanza', (stanza) => @readStanza(stanza)
    @client.on 'error', => @error()

    @pending = {}

  online: ->
    @client.send new Xmpp.Element('presence')

    # He is alive!
    console.log @name + ' is online, talk.google.com!'

    roster_query = new Xmpp.Element('iq',
        type: 'get'
        id: (new Date).getTime()
      )
      .c('query', xmlns: 'jabber:iq:roster')

    # Check for buddy requests every so often
    @client.send roster_query
    setInterval =>
      @client.send roster_query
    , @options.keepaliveInterval

  readStanza: (stanza) ->
    # Useful for debugging
    # console.log stanza

    # Check for erros
    if stanza.attrs.type is 'error'
      console.error '[xmpp error] - ' + stanza
      return

    # Check for presence responses
    if stanza.is 'presence'
      @handlePresence stanza
      return

    # Check for message responses
    if stanza.is 'message' or stanza.attrs.type not in ['groupchat', 'direct', 'chat']
      @handleMessage stanza
      return

  handleMessage: (stanza) ->
    jid = new Xmpp.JID(stanza.attrs.from)

    if @isMe(jid)
      return

    # ignore empty bodies (i.e., topic changes -- maybe watch these someday)
    body = stanza.getChild 'body'
    return unless body

    user = @getUser jid
    return @handleUnknownUser(jid) unless user

    # Change status to writing
    @ack user

    message = body.getText()
    # Pad the message with robot name just incase it was not provided.
    message = if not message.match(new RegExp("^"+@name+":?","i")) then @name + " " + message else message

    # Send the message to the robot
    @receive new Robot.TextMessage(user, message)

  handlePresence: (stanza) ->
    jid = new Xmpp.JID(stanza.attrs.from)

    if @isMe(jid)
      return

    # xmpp doesn't add types for standard available mesages
    # note that upon joining a room, server will send available
    # presences for all members
    # http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.1
    stanza.attrs.type ?= 'available'

    switch stanza.attrs.type
      when 'subscribe'
        console.log "#{jid.from()} subscribed to us"

        @client.send new Xmpp.Element('presence',
            from: @client.jid.toString()
            to:   stanza.attrs.from
            id:   stanza.attrs.id
            type: 'subscribed'
        )

      when 'probe'
        @client.send new Xmpp.Element('presence',
            from: @client.jid.toString()
            to:   stanza.attrs.from
            id:   stanza.attrs.id
        )

      when 'available'
        user = @getUser jid
        return @handleUnknownUser(jid) unless user

        user.online = true

        @receive new Robot.EnterMessage(user)

      when 'unavailable'
        user = @getUser jid
        unless user
          delete @pending[jid.from()]
          return

        user.online = false

        @receive new Robot.LeaveMessage(user)

  getUser: (jid) ->
    user = @userForEmail jid.from()
    # This can change from request to request
    user?.endpoint = jid.from()
    return user

  isMe: (jid) ->
    jid.from() == @options.username

  handleUnknownUser: (jid) ->
    console.log "Don't know this #{jid.from()}"
    @pending[jid.from()] = true
    @send endpoint: jid.from(),
      "Have we met?\nTell me who you are by loggin in #{@options.login_url}"

  handleNewUser: (user) ->
    # This might happen when the user was just created.
    for endpoint in user.emails
      if @pending[endpoint]
        delete @pending[endpoint]
        user.endpoint = endpoint
    return user

  send: (user, strings...) ->
    user = @handleNewUser user unless user.endpoint
    return unless user.endpoint

    txt = strings.join(" ")
    message = new Xmpp.Element('message',
        from: @client.jid.toString()
        to: user.endpoint
        type: 'chat'
      ).
      c('body').t(txt).up().
      c('active').attr("xmlns", "http://jabber.org/protocol/chatstates")

    # Send it off
    @client.send message

  ack: (user) ->
    message = new Xmpp.Element('message',
        from: @client.jid.toString()
        to: user.endpoint
        type: 'chat'
      ).c('composing').attr("xmlns", "http://jabber.org/protocol/chatstates")
    # Send it off
    @client.send message

  reply: (user, strings...) ->
    for str in strings
      @send user, "#{str}"

  error: (err) ->
    console.error err

exports.use = (robot) ->
  new Gtalkbot robot
