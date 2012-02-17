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
  Math.floor (today.getTime() - date.clear().getTime()) / 86400000


formatDays = (dayDiff) ->
  return 'today' if dayDiff <= 0
  return 'yesterday' if dayDiff is 1
  return "#{dayDiff} days ago" if dayDiff < 7
  return "#{Math.ceil dayDiff / 7 } weeks ago" if dayDiff < 31
  return "#{Math.ceil dayDiff / 30 } months ago"

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
