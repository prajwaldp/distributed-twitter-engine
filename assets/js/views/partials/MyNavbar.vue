<template>
  <nav class="navbar" role="navigation" aria-label="main navigation">
  <div class="navbar-brand">
    <router-link to="/" class="navbar-item">
      <h1 class="title" v-if="$route.fullPath == '/admin'">
        Welcome, admin!
      </h1>
      <h1 class="title" v-else>
        Welcome, {{ $store.getters.currentUser }}!
      </h1>
    </router-link>

    <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="myNavbar">
      <span aria-hidden="true"></span>
      <span aria-hidden="true"></span>
      <span aria-hidden="true"></span>
    </a>
  </div>

  <div id="myNavbar" class="navbar-menu">
    <div class="navbar-end">
      <div class="navbar-item" v-if="$store.getters.isLoggedIn">
        <div class="buttons">
          <a @click="logOut" class="button is-light">
            Log out
          </a>
        </div>
      </div>
    </div>
  </div>
</nav>
</template>

<script>
import auth from "../../auth.js"

export default {
  name: "my-navbar",

  data () {
    return {}
  },

  methods: {
    logOut () {
      auth.logOut()
      this.$router.push("/")
    }
  },
}
</script>