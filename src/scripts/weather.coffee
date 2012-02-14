# Weather tells you the forecast using Google's Weather API
#
# weather <location> - Tells the current weather at the location.
# forecast <location> - Tells the next three days of weather for location.
Http = require 'http'
Iconv = require 'iconv-lite'
Ltx = require 'ltx'
Qs = require 'querystring'


toCelsius = (f) ->
  Math.round (parseInt(f) - 32) * 5 / 9


parseWeather = (xml) ->
  weather = Ltx.parse(xml)?.getChild 'weather'
  return unless weather

  current = weather.getChild('current_conditions')
  information = weather.getChild('forecast_information')

  city: information?.getChild('city')?.attrs.data or 'Error'
  current:
    temp: current?.getChild('temp_c')?.attrs.data or '-100'
    condition: current?.getChild('condition')?.attrs.data or 'Error'
  forecast: for forecast in weather.getChildren('forecast_conditions') or []
    null # Work around CoffeeScript Bug 
    low: toCelsius forecast.getChild('low')?.attrs.data or '-148'
    high: toCelsius forecast.getChild('high')?.attrs.data or '-148'
    condition: forecast.getChild('condition')?.attrs.data or 'Error'
    dayOfWeek: forecast.getChild('day_of_week')?.attrs.data or 'Error'


requestWeather = (location, callback) ->
  req = Http.request
    host: 'www.google.com'
    path: "/ig/api?#{Qs.stringify weather: location}"
    agent: false

  req.on 'error', callback

  req.on 'response', (res) ->
    body = new Buffer 4096
    body.fill '\0'
    body_offset = 0
    res.on 'data', (chunk) ->
      chunk.copy body, body_offset
      body_offset += chunk.length

    res.on 'end', ->
      encodedResult = iconv.fromEncoding body.slice(0, body_offset), 'latin1'
      callback null, parseWeather encodedResult

  req.end()


module.exports = (robot) ->
  if process.env.HUBOT_WEATHER_LOCATION
    storeWeather = ->
      requestWeather process.env.HUBOT_WEATHER_LOCATION, (err, weather) ->
        robot.brain.set 'weather', weather unless err

    setInterval storeWeather, 3600000
    storeWeather()

  robot.respond /weather\s?(.*)$/i, (msg) ->
    location = msg.match[1] or process.env.HUBOT_WEATHER_LOCATION
    return msg.send "Please, inform me a location" unless location

    requestWeather location, (err, weather) ->
      msg.send "Weather on #{weather.city} is #{weather.current.temp}˚C and #{weather.current.condition}."

  robot.respond /forecast\s?(.*)$/i, (msg) ->
    location = msg.match[1] or process.env.HUBOT_WEATHER_LOCATION
    return msg.send "Please, inform me a location" unless location

    requestWeather location, (err, weather) ->
      forecast = ["Forecast for #{weather.city}:"]
      for day in weather.forecast
        forecast.push "#{day.dayOfWeek}: #{day.condition}. Low #{day.low}˚C / High #{day.high}˚C"
      msg.send forecast.join('\n')

