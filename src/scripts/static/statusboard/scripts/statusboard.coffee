daysago = (date) ->
  day_diff = Math.floor ((new Date()).getTime() - date.getTime()) / 86400000
  return "today" if day_diff <= 0
  return "yesterday" if day_diff is 1
  return "#{day_diff} days ago" if day_diff < 7
  return "#{Math.ceil(day_diff / 7)} weeks ago" if day_diff < 31
  return "#{Math.ceil(day_diff / 30)} moths ago"

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
            <em>#{daysago time}</em> #{time.getHours()}:#{time.getMinutes()}
          </span>
      </li>
      """
    $('div.status ul').html content.join ''
