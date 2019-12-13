<template>
  <div class="columns">
    <div class="column is-6" id="hero-container">
      <h1 class="title">Twitter<sup><small>ati</small></sup></h1>

      <p>Hello there,</p>

      <br>
      <p>This is our attempt at building the core Twitter service from scratch.</p>

      <br>
      <p>The idea behind this implementation was to simulate the load actual Twitter handles as a distributed system.</p>

      <br>
      <p>Built with <span class="icon"><i class="fa fa-heart"></i></span> using Elixir and Phoenix!</p>
    </div>

    <div class="column" id="join-form-container">

      <h2 class="title">Get Started</h2>

      <form v-on:submit.prevent="logIn">
        <div class="field">
          <label class="label">Username</label>
          <div class="control">
            <input class="input" type="text" placeholder="Username" v-model="logInForm.username" required>
          </div>
        </div>

        <div class="field">
          <label class="label">Password</label>
          <div class="control">
            <input class="input" type="password" placeholder="Password" v-model="logInForm.password" required>
          </div>
        </div>

        <div class="field">
          <div class="control">
            <label class="checkbox">
              <input type="checkbox" required>
              I agree to the <a href="#">terms and conditions</a>
            </label>
          </div>
        </div>

        <div class="field is-grouped">
          <div class="control">
            <button class="button is-link">Join Now</button>
          </div>
          <div class="control">
            <button class="button is-link is-light">Cancel</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import * as axios from 'axios'

export default {
  name: "home-page",

  data () {
    return {
      logInForm: {
        username: '',
        password: ''
      }
    }
  },

  created () {
    // if (this.$store.getters.isLoggedIn) {
    //   console.log("Logged in. Redirecting to feed")
    //   this.$router.push("/feed")
    // }
  },

  methods: {
    logIn () {
      let params = this.logInForm

      axios.post("/join", params)
      .then(resp => {
        this.$store.commit("logIn", resp.data["username"])
        this.$router.push("/feed")
      })
      .catch(err => {
        console.log("Request failed", err)
      })
    }
  }
}
</script>
