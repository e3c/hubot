# Set your status or query others
#
# list status - Lists what everyone is doing
# I am <something> - Set your current status to something
# status <something> - Set your current status to something

Timeago = require 'timeago'

module.exports = (robot) ->
  robot.respond /(list )?status$/i, (msg) ->
    statuses = for id, statuses of robot.brain.get 'statuses', { }
      user = robot.userForId id
      status = statuses[0]
      "#{user.name} was #{status.message} #{Timeago +status.time}."

    if statuses.length > 0
      msg.send statuses...
    else
      msg.send "Don't know anything about anyone."

  robot.respond /(status|i'm|i am) (.*)$/i, (msg) ->
    statuses = robot.brain.get 'statuses', { }

    userStatus = statuses[msg.user.id] or [ ]
    userStatus.unshift message: msg.match[2], time: +(new Date())
    userStatus.splice 5

    statuses[msg.user.id] = userStatus

    robot.brain.set 'statuses', statuses
    msg.send "Ok, you are #{msg.match[2]}"

