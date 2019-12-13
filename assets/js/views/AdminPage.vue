<template>
  <div>
    <my-navbar></my-navbar>

    <div class="container" style="margin-top: 5rem;">
      <div class="columns">
        <div class="column is-6 is-offset-3 card">
          <div class="card-body">
            <h1 class="title has-text-centered">
              Run Simulation
            </h1>

            <form @submit.prevent="startSimulation">
              <div class="field">
                <label class="label">Number of Users</label>
                <div class="control">
                  <input class="input" type="number" v-model="form.users">
                </div>
              </div>

              <div class="field">
                <label class="label">Number of Requests</label>
                <div class="control">
                  <input class="input" type="number" v-model="form.requests">
                </div>
              </div>

              <div class="field">
                <div class="control">
                  <input class="button is-primary" type="submit">
                </div>
              </div>
            </form>

            <button
              class="button is-success is-fullwidth"
              v-if="simulationActive"
              style="margin-top: 1rem;">Simulation Running</button>

          </div>
        </div>
      </div>
    </div>

    <div class="container" style="margin-top: 3rem;">
      <div class="card">
        <div class="card-header">
          <p class="card-header-title">
            Logs
          </p>
        </div>
        <div class="card-content">
          <ul>
            <li v-for="log in logs">
              {{ log }}
            </li>
          </ul>
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
  name: "admin-page",

  components: {
    MyNavbar
  },

  data () {
    return {
      socket: null,
      channel: null,
      form: {
        users: 100,
        requests: 10
      },
      logs: [],
      simulationActive: false
    }
  },

  created () {
    this.socket = new Socket("/socket", {params: {token: window.userToken}})
      this.socket.connect()
      this.channel = this.socket.channel("room:lobby")

      this.channel.on("shout", data => {
        console.log(data)
      })

      this.channel.on("notification", data => {
        this.logs.unshift(data)
      })

      this.channel.on("feed", data => {
        this.logs.unshift(data)
      })

      this.channel.join()
        .receive("ok", resp => { console.log("Websocket connection to the server established", resp) })
        .receive("error", resp => { console.log("Could not establish websocket connection to the server", resp) })

      this.channel.push('shout', {status: "ok"});
  },

  methods: {
    startSimulation () {

      let payload = {
        users: this.form.users,
        requests: this.form.requests
      }

      this.channel.push("start_simulation", payload)

      this.simulationActive = true
    }
  }
}
</script>
