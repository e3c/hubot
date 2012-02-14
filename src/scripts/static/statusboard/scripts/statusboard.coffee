pad = (str, length=2) ->
    str = String str
    while str.length < length
        str = '0' + str
    str

daysago = (date) ->
  day_diff = Math.floor ((new Date()).getTime() - date.getTime()) / 86400000
  return "today" if day_diff <= 0
  return "yesterday" if day_diff is 1
  return "#{day_diff} days ago" if day_diff < 7
  return "#{Math.ceil day_diff / 7 } weeks ago" if day_diff < 31
  return "#{Math.ceil day_diff / 30 } months ago"

$ ->
  faye = new Faye.Client "#{location.origin}/faye", timeout: 120
  faye.subscribe '/statuses', (statuses) ->
    content = for status in statuses
      time = new Date status.time
      """
      <li>
          <span class="user">#{status.user.name}</span>
          <span class="arrow-left"></span>
          <span class="sts">#{status.message}</span>
          <span class="date">
            <em>#{daysago time}</em> #{pad(time.getHours())}:#{pad(time.getMinutes())}
          </span>
      </li>
      """
    $('div.status ul').html content.join ''
