Date::clear = ->
  @setHours 0
  @setMinutes 0
  @setSeconds 0
  @setMilliseconds 0
  @


pad = (str, length=2) ->
    str = String str
    while str.length < length
        str = '0' + str
    str


daysAgo = (date) ->
  today = (new Date()).clear()
  referenceDay = (new Date(+date)).clear()
  Math.floor (today.getTime() - referenceDay.getTime()) / 86400000


formatDays = (dayDiff) ->
  return 'today' if dayDiff <= 0
  return 'yesterday' if dayDiff is 1
  return "#{dayDiff} days ago" if dayDiff < 7
  return "#{Math.ceil dayDiff / 7 } weeks ago" if dayDiff < 31
  return "#{Math.ceil dayDiff / 30 } months ago"


imageForCondition = (condition) ->
  condition = condition.trim().toLowerCase()

  imageMapping = {
    'chance of rain': 'cloudy'
    'chance of snow': 'light_snow'
    'chance of storm': 'rain'
    'chance of tstorm': 'rain'
    'clear': 'sun'
    'cloudy': 'cloudy'
    'dust': 'fog'
    'flurries': 'snow'
    'fog': 'fog'
    'freezing drizzle': 'snow'
    'hail': 'icy_rain'
    'haze': 'fog'
    'icy': 'snow'
    'light rain': 'light_rain'
    'light snow': 'light_snow'
    'mist': 'fog'
    'mostly cloudy': 'cloudy'
    'mostly sunny': 'sun'
    'overcast': 'cloudy'
    'partly cloudy': 'cloudy'
    'partly sunny': 'partly_cloudy'
    'rain': 'rain'
    'rain and snow': 'icy_rain'
    'rain showers': 'rain'
    'scattered showers': 'light_rain'
    'scattered thunderstorms': 'rain'
    'showers': 'rain'
    'sleet': 'snow'
    'smoke': 'fog'
    'snow': 'snow'
    'snow showers': 'light_snow'
    'snow storm': 'snow'
    'storm': 'tstorms'
    'sunny': 'sun'
    'thunderstorm': 'tstorms'
  }[condition]

  if not imageMapping
    for key, value of { shower: 'light_rain', 'rain', 'snow', cloud: 'cloudy',  wind: 'fog', storm: 'tstorms', icy: 'snow' }
      if condition.indexOf key isnt -1
        imageMapping = value

    imageMapping or= 'cloudy'

  "http://ssl.gstatic.com/onebox/weather/60/#{imageMapping}.png"


$ ->
  faye = new Faye.Client "#{location.origin}/faye", timeout: 120
  faye.subscribe '/statuses', (statuses) ->
    content = for status in statuses
      time = new Date status.time
      statusClass = if status.user.online then ' online' else ''
      statusOld = if daysAgo(time) >= 1 then ' old' else ''
      """
      <li class="#{statusOld}">
          <span class="user#{statusClass}">#{status.user.name}</span>
          <span class="arrow-left"></span>
          <span class="sts">#{status.message}</span>
          <span class="date">
            <em>#{formatDays daysAgo time}</em> #{pad(time.getHours())}:#{pad(time.getMinutes())}
          </span>
      </li>
      """
    $('div.status ul').html content.join ''

  faye.subscribe '/weather', (weather) ->
    content = """
      <li>
        <img src="#{imageForCondition weather.current.condition}" />
        <h2>TODAY</h2>
        <span class="temp_c">#{weather.current.temp}</span>
      </li>
    """
    for forecast in weather.forecast[1..2]
      content += """
        <li>
          <img src="#{imageForCondition forecast.condition}" />
          <h2>#{forecast.dayOfWeek.toUpperCase()}</h2>
          <span class="high_data">#{forecast.high}˚</span>
          <span class="low_data">#{forecast.low}˚</span>
        </li>
      """
    $('div.weather ul').html content
