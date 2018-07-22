jQuery ->

  team = $('#chatbox-team-id')

  if team.length > 0

    App.chat = App.cable.subscriptions.create {
      channel:"ChatChannel"
      team: team.data('team')
      },
      connected: ->
        # Called when the subscription is ready for use on the server

      disconnected: ->
        # Called when the subscription has been terminated by the server

      received: (data) ->
        # Called when there's incoming data on the websocket for this channel
        $messages = $("#chatbox")
        $chatbody = $("#chatbox-main")
        $messages.append data['message']
        $chatbody.css('display', 'block')
        $messages.scrollTop $messages.prop('scrollHeight')
        ion.sound.play("button_tiny")
