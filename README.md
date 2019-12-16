# Distributed Twitter Engine

A distributed engine for a twitter-like application using Phoenix/Elixir, with posts, hashtags, user-mentions, re-posts, and subscriptions.

## Features
* The User model
* The Tweet model with support for hashtags and user-mentions.
* Subscribing to a user
* Subscribing to a hashtag
* Retweeting a tweet
* Querying tweets with a hashtag or mention
* The front-end (built using Vue.js) and the back-end (built using Phoenix) interact with each other via HTTP and a websocket connection between a client and the server.
* Global events (such as a user joining the system, or an hashtag being created) is broadcasted to all connected clients live via Phoenix channels.
* Client-specific payload such as tweets from users she/he has subscribed to, or with hashtags she/he has subscribed is only received by that client live via Phoenix channels.
* A simulation for more users performing more requests to the engine can be run in the background, which every client is able to interact with.


## Demo

https://youtu.be/96pKx_2NXIk

## Instructions

To start the Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
