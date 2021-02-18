/* global Onepay */
export const TransbankModal = {
  init (data) {
    const s = document.createElement('script')

    s.type = 'text/javascript'
    s.src = 'https://unpkg.com/transbank-onepay-frontend-sdk@1/lib/merchant.onepay.min.js'
    s.onload = s.onreadystatechange = () => {
      if (!s.readyState || s.readyState === 'loaded') {
        Onepay.checkout(data)
      }
    }

    document.body.appendChild(s)
  },

  mounted () {
    this.handleEvent('openModal', data => this.init(data))
  }
}
