export const Notification = {
  mounted () {
    this.handleSubscribe()
    this.getSubscription()
  },

  handleSubscribe () {
    this.handleEvent('subscribe', () => {
      navigator.serviceWorker?.getRegistration().then(registration => {
        if (registration) {
          registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: this.encodeKey(this.el.dataset.serverKey)
          }).then(subscription => {
            this.pushEvent('register', subscription.toJSON())
          })
        }
      })
    })
  },

  getSubscription () {
    navigator.serviceWorker?.ready.then(registration => {
      registration.pushManager.getSubscription().then(subscription => {
        if (subscription) {
          this.pushEvent('register', subscription.toJSON())
        } else {
          this.pushEvent('ask-for-notifications')
        }
      })
    })
  },

  encodeKey (key) {
    const padding     = '='.repeat((4 - key.length % 4) % 4)
    const base64      = `${key}${padding}`.replace(/\-/g, '+').replace(/_/g, '/')
    const rawData     = atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
  }
}
