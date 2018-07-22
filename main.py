import discord
import asyncio
import urllib.request
import json

client = discord.Client()

@client.event
async def on_ready():
   print('Logged in as')
   print(client.user.name)
   print(client.user.id)
   print('------')

@client.event
async def on_message(message):

   if message.content.startswith('!test'):
       #tmp = await client.send_message(message.channel, 'Calculating messages...')
       #async for log in client.logs_from(message.channel, limit=100):
       #    if log.author == message.author:
       #        counter += 1

       await client.edit_message(tmp, 'You are {} .'.format(message.author))

   elif message.content.startswith('!user'):
       await client.send_message(message.channel, 'Information received from API : {username, gamename, game, soloq, flexq, team}')
       username = 'Arailla'
       gamename = 'Arailla'
       game = 'League of Legends'
       soloq = 'Silver I'
       flexq = 'Silver III'
       team = 'none'
       await client.send_message(message.channel,  'Username: {}, \nIn game name: {},\nGame Played: {},\nSoloQ Rank: {},\nFlexQ Rank: {},\nTeam Name: {}'
           .format(username, gamename, game, soloq, flexq, team))
       await send_request(message, "user")

   elif message.content.startswith('!team'):
       await client.send_message(message.channel, 'Information received from API : {name, lvlMin, lvlMax, age, schedule, missingRoles}')
       await send_request(message, "team")

   elif message.content.startswith('!search'):
       await client.send_message(message.channel, 'Information received from API :  {gamename, game, soloq, flexq, schedule, age}')
       await send_request(message, "search")

   elif message.content.startswith('!mentor'):
       await client.send_message(message.channel, 'Information received from API :  {gamename, game, soloq, flexq, followSolo, followTeam, rating, role, top, certified, link}')
       await send_request(message, "mentor")

   elif message.content.startswith('!info'):
       await client.send_message(message.channel, 'Information received from API :  {gamename, game, status, mentor}')
       #display available commands depending on info
       await client.send_message(message.channel, 'Welcome gamename ! You can use the following commands:')
       await send_request(message, "info")

   elif message.content.startswith('!'):
       await client.send_message(message.channel, "Command Unknown : {}".format(message.content))

   #les messages du bot sont comptés comme des events, donc ne rien écrire en dessous pour ne pas boucler dessus

async def send_request(message, command):
   r = urllib.request.urlopen(" https://dfcf0332.ngrok.io/discord/?command="+command)

   data = json.loads(r.read().decode(r.info().get_param('charset') or 'utf-8'))
   await client.send_message(message.channel, data)
   await client.send_message(message.channel, "Command {} requested by {}".format(data["command"], message.author))

client.run('MzA0MzI4ODM5NjU4NjAyNDk3.C9lFGg.BUXyL3xBALjJw44Hox7KZCPHiRM')
