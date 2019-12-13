<template>
  <div>
    <my-navbar></my-navbar>

    <div class="container" id="feed-container">
      <div class="columns">
        <div class="column is-4">
              <nav class="panel">
                <p class="panel-heading">
                  About me
                </p>
                <a class="panel-block">
                  <span class="panel-icon">
                    <i class="fas fa-user" aria-hidden="true"></i>
                  </span>
                  Username: {{ this.$store.getters.currentUser }}
                </a>
              </nav>

              <nav class="panel">
                <p class="panel-heading">
                  Search
                </p>
                <div class="panel-block">
                  <form @submit.prevent="search">
                    <p class="control has-icons-left">
                      <input
                        class="input"
                        type="text"
                        v-model="searchQuery"
                        placeholder="Search all tweets for hashtags or mentions">
                      <span class="icon is-left">
                        <i class="fas fa-search" aria-hidden="true"></i>
                      </span>
                    </p>
                  </form>
                </div>
                <div class="panel-block" v-if="searched && searchResults.length == 0">
                  No tweets matching the {{ describeQuery(searchQuery) }} found
                </div>

                <div class="panel-block" v-if="searched && searchResults.length > 0">

                  <div style="width: 100%">
                    <p class="is-size-7">
                      {{ searchResults.length }} tweets matching the {{ describeQuery(searchQuery) }} found:
                    </p>

                    <a
                      v-if="searchQuery.startsWith('#')"
                      class="button is-primary is-small"
                      @click="subscribeToHashtag(searchQuery)">Subscribe to {{ searchQuery }}</a>

                    <a
                      v-else
                      class="button is-primary is-small"
                      @click="subscribeToUser(searchQuery.slice(1))">Subscribe to {{ searchQuery }}</a>

                    <ul style="margin-top: 0.3rem">
                      <li class="search-result-item" v-for="res in searchResults">
                        <p class="is-size-7">
                          <strong>{{ res["user_id"] }}</strong>
                        </p>
                        <p>
                          {{ res["content"] }}
                        </p>
                      </li>
                    </ul>
                  </div>
                </div>
              </nav>

              <nav class="panel">
                <p class="panel-heading">
                  My Tweets
                </p>

                <a class="panel-block" v-if="userTweets.length == 0">
                  <span class="panel-icon">
                    <i class="fas fa-hourglass-start" aria-hidden="true"></i>
                  </span>
                  No tweet from you yet!
                </a>

                <a class="panel-block" v-for="t in userTweets">
                  <span class="panel-icon">
                    <i class="fas fa-star" aria-hidden="true"></i>
                  </span>
                  {{ t }}
                </a>
              </nav>
        </div>

        <div class="column is-4">

          <div class="card">
            <div class="card-content">
              <h1 class="title">Write a Tweet!</h1>

              <form v-on:submit.prevent="createTweet">
                <div class="field">
                  <div class="control">
                    <input class="input" type="text" placeholder="Write a tweet" v-model="tweetForm.tweet">
                  </div>
                </div>

                <div class="field">
                  <div class="control">
                    <button class="button is-primary">Submit</button>
                  </div>
                </div>
              </form>
            </div>
          </div>

          <div class="card">
            <div class="card-content">
              <h1 class="title">
                My Feed
              </h1>

              <p class="help" v-if="feed.length == 0">
                Nothing to show!
              </p>

              <ul>
                <div
                  class="tweet-item"
                  v-for="feedItem in feed"
                  v-if="feedItem.tweet.user_id != $store.getters.currentUser"
                >
                  <p class="subtitle">
                    {{ feedItem.tweet.user_id }}
                  </p>

                  <p class="content">
                    {{ feedItem.tweet.content }}
                  </p>

                  <a @click="createReTweet(feedItem.tweet.content)" class="button is-small">
                    Retweet
                  </a>

                  <p class="has-text-right is-help is-size-7" v-if="feedItem.event == 'tweet_with_hashtag'">
                    Because you're subscribed to the hashtag <strong>{{ feedItem.hashtag }}</strong>
                  </p>

                  <p class="has-text-right is-help is-size-7" v-if="feedItem.event == 'tweet_from_subscribee'">
                    Because you're subscribed to <strong>{{ feedItem.tweet.user_id }}</strong>
                  </p>

                  <p class="has-text-right is-help is-size-7" v-if="feedItem.event == 'tweet_with_mention'">
                    Because you were mentioned
                  </p>
                </div>
              </ul>
            </div>
          </div>
        </div>

        <div class="column is-4">
          <div class="card">
            <div class="card-content" style="height: 50vh; overflow-y: scroll">
              <h2 class="subtitle">
                Events
              </h2>

              <p class="help" v-if="notifications.length == 0">
                No events to show!
              </p>

              <ul>
                <li v-for="n in notifications">
                  <div v-if="n.event == 'new_user'">
                    User {{ n.subject }} joined. <a class="link" @click="subscribeToUser(n.subject)">Subscribe</a>
                  </div>

                  <div v-if="n.event == 'new_hashtag'">
                    New hashtag {{ n.subject }} created. <a class="link" @click="subscribeToHashtag(n.subject)">Subscribe</a>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import * as axios from 'axios'
import {Socket} from "phoenix"
import MyNavbar from "./partials/MyNavbar.vue"

export default {
  name: "feed-page",

  components: {
    MyNavbar
  },

  data () {
    return {
      tweetForm: {
        tweet: ""
      },
      searchQuery: "",
      userTweets: [],
      notifications: [],
      feed: [],
      searchResults: [],
      searched: false,
    }
  },

  created () {
    if (!this.$store.getters.isLoggedIn) {
      console.log("Not logged in. Redirecting to home page")
      this.$router.push("/")
    }

    this.establishSocketConnection()
  },

  watch: {
    searchQuery () {
      this.searched = false
    }
  },

  methods: {
    establishSocketConnection () {
      this.socket = new Socket("/socket", {params: {token: window.userToken}})
      this.socket.connect()

      // this.channel = this.socket.channel("room:" + this.$store.getters.currentUser)

      this.channel = this.socket.channel("room:lobby")

      this.channel.on("shout", data => {
        console.log(data)
      })

      this.channel.on("notification", data => {
        this.notifications.unshift(data)
      })

      this.channel.on("feed", data => {
        if (data["show_for"] == this.$store.getters.currentUser) {
          this.feed.unshift(data)
        }
      })

      this.channel.join()
        .receive("ok", resp => { console.log("Websocket connection to the server established", resp) })
        .receive("error", resp => { console.log("Could not establish websocket connection to the server", resp) })

      this.channel.push('shout', {status: "ok"});
    },

    createTweet () {
      let params = {
        user: this.$store.getters.currentUser,
        tweet: this.tweetForm.tweet
      }

      axios.post("/tweets", params)
      .then(resp => {
        this.userTweets.unshift(resp.data["content"])
        this.tweetForm.tweet = ""
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    },

    subscribeToUser (user) {

      let params = {
        user: this.$store.getters.currentUser,
        "user_to_subscribe_to": user
      }

      axios.post("/subscribe-to-user", params)
      .then(resp => {
        alert("Subscribed to user " + user + " successfully!")
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    },

    subscribeToHashtag (hashtag) {

      let params = {
        user: this.$store.getters.currentUser,
        hashtag: hashtag
      }

      axios.post("/subscribe-to-hashtag", params)
      .then(resp => {
        alert("Subscribed to hashtag " + hashtag + " successfully!")
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    },

    createReTweet(content) {
      let params = {
        user: this.$store.getters.currentUser,
        content: content
      }

      axios.post("/retweet", params)
      .then(resp => {
        this.userTweets.unshift(resp.data["content"])
        alert("Retweeted successfully!")
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    },

    search () {
      let params = {
        query: this.searchQuery
      }

      axios.get("/search", { params })
      .then(resp => {
        this.searchResults = resp.data["records"]
        this.searched = true
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    },

    describeQuery (query) {
      if (query.startsWith("#")) {
        return "hashtag " + query
      }

      if (query.startsWith("@")) {
        return "mention " + query
      }

      return query
    }
  }
}
</script>

<style lang="scss">
#feed-container {
  padding: 3rem;
}

.tweet-item {
  padding: 10px;
  border: 1px solid #eee;
  border-radius: 5px;
  margin-bottom: 1rem;

  p.subtitle {
    font-weight: bold;
    font-size: 1rem;
    color: grey;
    margin-bottom: 0.3rem;
  }

  p.content {
    font-size: 1.3rem;
  }
}

form {
  width: 100%;
}

li.search-result-item {
  padding: 0.2rem;
  background-color: #eee;
  margin-bottom: 0.2rem;
  border-radius: 3px;
}
</style>
