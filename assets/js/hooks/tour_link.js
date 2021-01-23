export const TourLink = {
  mounted () {
    setTimeout(() => {
      const params = new URLSearchParams(location.search)
      const tourStep = params.get('tour')

      if (tourStep) {
        this.links = document.querySelectorAll(`a[data-tour-step="${tourStep}"]`)

        for (const link of this.links) {
          link.dataset.originalUrl = link.href
          link.href = link.dataset.tourUrl

          link.classList.add('tour-target')
        }
      }
    })
  },

  destroyed () {
    if (this.links) {
      for (const link of this.links) {
        link.href = link.dataset.originalUrl

        link.classList.remove('tour-target')
      }
    }
  }
}
