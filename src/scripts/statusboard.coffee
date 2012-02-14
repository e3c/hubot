_ = require 'underscore'
FayeNodeAdapter = require('faye').NodeAdapter

module.exports = (robot) ->
  faye = new FayeNodeAdapter mount:'/faye', timeout: 60
  faye.attach robot.connect
  client = faye.getClient()

  properties =
    '/statuses': ->
      statuses = for id, statuses of robot.brain.get 'statuses'
        {
          user: robot.userForId id
          message: statuses[0].message
          time: statuses[0].time
        }
      _.sortBy statuses, (status) -> status.user.name
    '/weather': ->
      robot.brain.get 'weather'

  faye.bind 'subscribe', (clientId, channel) ->
    console.log "Client #{clientId} subscribed to #{channel}"
    setTimeout ->
      client.publish channel, properties[channel]() if properties[channel]
    , 2000

  robot.brain.on 'changed', (prop, value) ->
    channel = "/#{prop}"
    client.publish channel, properties[channel]() if properties[channel]
