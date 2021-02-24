export const Share = {
  mounted () {
    if (navigator.canShare) {
      this.hideAlternatives()
      this.enableDirectSharing()
    }
  },

  updated () {
    if (navigator.canShare) {
      this.hideAlternatives()
      this.showElement()
    }
  },

  enableDirectSharing () {
    const element = this.el

    this.showElement()

    element.addEventListener('click', event => {
      event.preventDefault()

      navigator.share({
        title: element.dataset.title,
        text:  element.dataset.text,
        url:   element.dataset.url
      })
    })
  },

  showElement () {
    this.el.classList.remove('d-none')
  },

  hideAlternatives () {
    const elements = document.querySelectorAll('[data-hide-when-share]')

    for (const element of elements) {
      element.classList.add('d-none')
    }
  }
}
