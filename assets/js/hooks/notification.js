export const Notification = {
  mounted () {
    this.handleSubscribe()

    if (this.el.dataset.skipSubscription === 'false') {
      this.getSubscription()
    }
  },

  handleSubscribe () {
    this.handleEvent('subscribe', () => {
      navigator.serviceWorker?.getRegistration().then(registration => {
        if (registration) {
          registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: this.encodeKey(this.el.dataset.serverKey)
          }).then(subscription => {
            this.pushEventTo(`#${this.el.id}`, 'register', subscription.toJSON())
          })
        }
      })
    })
  },

  getSubscription () {
    navigator.serviceWorker?.ready.then(registration => {
      registration.pushManager.getSubscription().then(subscription => {
        if (subscription) {
          this.pushEventTo(`#${this.el.id}`, 'register', subscription.toJSON())
        } else {
          this.pushEventTo(`#${this.el.id}`, 'ask-for-notifications')
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
