import NProgress from 'nprogress'
import {Socket} from 'phoenix'
import {LiveSocket} from 'phoenix_live_view'
import {Hooks} from './hooks'

const csrfToken  = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
window.addEventListener('phx:page-loading-start', () => NProgress.start())
window.addEventListener('phx:page-loading-stop', () => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
