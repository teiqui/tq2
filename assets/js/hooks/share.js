export const Share = {
  mounted () {
    const element = this.el

    if (navigator.canShare) {
      element.classList.remove('d-none')

      element.addEventListener('click', event => {
        event.preventDefault()

        navigator.share({
          title: element.dataset.title,
          text:  element.dataset.text,
          url:   element.dataset.url
        })
      })
    }
  }
}
