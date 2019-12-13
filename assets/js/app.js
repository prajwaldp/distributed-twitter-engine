import "../css/app.scss"

import {Socket} from "phoenix"

import Vue from "vue"
import VueRouter from "vue-router"
import Vuex from "vuex"

Vue.use(VueRouter)
Vue.use(Vuex)

import HomePage from './views/HomePage.vue'
import FeedPage from './views/FeedPage.vue'
import AdminPage from './views/AdminPage.vue'
import auth from "./auth.js"

const routes = [
  { path: '/', component: HomePage },
  { path: '/feed', component: FeedPage },
  { path: '/admin', component: AdminPage }
]

const router = new VueRouter({
  routes
})

const store = new Vuex.Store({
  state: {},

  mutations: {
    logIn (state, username) {
      auth.logIn(username)
    }
  },

  getters: {
    isLoggedIn: () => auth.isLoggedIn(),
    currentUser: () => auth.currentUser()
  }
})

new Vue({
  el: '#app',

  router,

  store,

  components: {
    HomePage,
    FeedPage
  },

  data () {
    return {
      logInForm: {
        username: '',
        password: ''
      },

      socket: null,
      channel: null,
    }
  },
})
