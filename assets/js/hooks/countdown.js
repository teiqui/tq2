const helpers = {
  pad (number) {
    return `0${number}`.slice(-2)
  },

  tick (element, distance) {
    const hours   = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((distance % (1000 * 60)) / 1000)

    element.innerHTML = `${this.pad(hours)}:${this.pad(minutes)}:${this.pad(seconds)}`
  },

  expired (element, intervalId) {
    const expiredTarget = document.querySelector(element.dataset.expiredTarget)

    element.innerHTML = '00:00:00'

    element.classList.add('text-danger')

    clearInterval(intervalId)

    if (expiredTarget) {
      element.classList.add('d-none')
      expiredTarget.classList.remove('d-none')
    }
  }
}

export const Countdown = {
  mounted () {
    const expiration = new Date(this.el.dataset.date).getTime()

    this.intervalId = setInterval(() => {
      const distance = expiration - new Date().getTime()

      if (distance >= 0) {
        helpers.tick(this.el, distance)
      } else {
        helpers.expired(this.el, this.intervalId)
      }
    }, 1000)
  },

  destroyed () {
    clearInterval(this.intervalId)
  }
}
