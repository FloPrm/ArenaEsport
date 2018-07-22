jQuery ->

  user = $('#user-id')

  if user.length > 0

    App.appearance = App.cable.subscriptions.create "AppearanceChannel",
      connected: ->
        # Called when the subscription is ready for use on the server

      disconnected: ->
        # Called when the subscription has been terminated by the server

      received: (data) ->
        # Called when there's incoming data on the websocket for this channel
        $userStatus = $('#status-user-' + data['user_id'])
        $friendList = $('#friends-list')
        onlineFriends = document.getElementById("friends-list").getElementsByClassName("status-online")
        $lastOnline = $('#' + onlineFriends[onlineFriends.length - 1].closest('li').id)
        $friend = $('#friend-' + data['user_id'])
        $friendStatus = $('#status-friend-' + data['user_id'])
        $friendOffline = $('#offline-' + data['user_id'])
        if $friend.length > 0
          if data['online'] is true
            $userStatus.removeClass('status-offline').addClass('status-online')
            $friendStatus.removeClass('status-offline').addClass('status-online')
            $friendOffline.css('display', 'none')
            $friendList.prepend $friend
          else if data['online'] is false
            $userStatus.removeClass('status-online').addClass('status-offline')
            $friendStatus.removeClass('status-online').addClass('status-offline')
            $friendOffline.html(data['offline'])
            $friendOffline.css('display', 'block')
            if $lastOnline.length > 0
              $lastOnline.after $friend
