/* global Stripe */
const helpers = {
  redirectToCheckout (params) {
    const stripe = Stripe(params.key)

    stripe.redirectToCheckout({sessionId: params.id})
  }
}

export const License = {
  mounted () {
    this.handleEvent('redirect-to-checkout', helpers.redirectToCheckout)
  }
}
