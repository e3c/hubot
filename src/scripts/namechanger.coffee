# Set your username
#
# call me <something> - Set your user name to something
# my name is <something> - Set your user name to something
module.exports = (robot) ->
  robot.respond /(call me|my name is) ([\w\s]+)$/i, (msg) ->
    msg.user.original_name = msg.user.name

    # Capitalize just to be sure.
    msg.user.name = (msg.match[2].trim().charAt(0).toUpperCase() +
      msg.match[2].trim().substring(1).toLowerCase())

    msg.send "From now on I'll call you #{msg.user.name}."

