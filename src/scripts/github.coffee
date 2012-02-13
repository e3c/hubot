_ = require 'underscore'
Github = require 'octonode'
Url = require 'url'


module.exports = (robot) ->
  organization = process.env.HUBOT_GITHUB_ORGANIZATION

  auth_url = Github.auth.config
    client_id: process.env.HUBOT_GITHUB_CLIENT_ID
    client_secret: process.env.HUBOT_GITHUB_CLIENT_SECRET
  .login ['user', 'repo']


  robot.respond /logout/i, (msg) ->
    user = msg.message.user
    msg.send "Good bye #{user.name}. Sad to see you go."
    delete robot.brain.data.users[user.id]


  # Add a URL that will be used to login
  robot.router.get '/github/login', (req, res, next) ->
    res.writeHead 301, 'Content-Type': 'text/plain', 'Location': auth_url
    res.end "Redirecting to #{auth_url}"


  robot.router.get '/github/auth', (req, res, next) ->
    on_error = (err, status) ->
      console.trace()
      console.log 'Error!', err, status
      res.writeHead 500, 'Content-Type': 'text/plain'
      res.end "Unable to finish! Got #{err}"

    access_code = Url.parse(req.url, true).query.code
    Github.auth.login access_code, (err, access_token) ->
      return on_error(err, 500) if err

      client = new Github.client access_token
      client.get '/user', (err, status, info) ->
        return on_error("Invalid login", status) if err or status isnt 200

        client.get "/orgs/#{organization}/members/#{info.login}", (err, status) ->
          return on_error("Not a member of the organization", status) if err or status isnt 204

          user = robot.userCreate info.id,
            name: info.name
            emails: [info.email]
            gravatar_id: info.gravatar_id
            github:
              login: info.login
              access_token: access_token

          client.get '/user/emails', (err, status, emails) ->
            return on_error(err, status) if err or status isnt 200

            user.emails = _.chain(user.emails).concat(emails or [ ]).sort()
              .uniq(true).filter((item) -> item?).value()

            robot.send user, "It's great to meet you #{user.name}. Type 'help' to know more about me."
            res.writeHead 200, 'Content-Type': 'text/plain'
            res.end "Ok. Great to know you #{user.name}!"

