export default {
  logIn (username) {
    localStorage.setItem("username", username)
  },

  logOut () {
    localStorage.removeItem("username")
  },

  isLoggedIn() {
    if (localStorage.getItem("username")) {
      return true
    }

    return false
  },

  currentUser () {
    return localStorage.getItem("username")
  }
}
