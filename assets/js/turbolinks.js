/* global require */

const Turbolinks = require('turbolinks')

Turbolinks.start()
Turbolinks.setProgressBarDelay(300)

document.addEventListener('turbolinks:load', () => {
  if (typeof liveSocket === 'object') {
    liveSocket.connect()
  }
})
