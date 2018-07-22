jQuery ->

  user = $('#user-id')

  if user.length > 0

    App.notification = App.cable.subscriptions.create {
      channel:"NotificationChannel"
      user: user.data('id')
      },
      connected: ->
        # Called when the subscription is ready for use on the server

      disconnected: ->
        # Called when the subscription has been terminated by the server

      received: (data) ->
        # Called when there's incoming data on the websocket for this channel
        $notifications = $("#notifications")
        $bell = $("#notifs-badge")
        $notifications.prepend data['notification']
        $bell.html(data['unread'])
        $bell.css('display', 'inline-block')
