const helpers = {
  copyElementTextToClipboard (element) {
    navigator.clipboard.writeText(element.dataset.text).then(() => {
      if (element.dataset.target) {
        const target = document.querySelector(element.dataset.target)

        if (target) {
          target.classList.remove('d-none')
        }

        setTimeout(() => {
          target.classList.add('d-none')
        }, 5000)
      }
    })
  }
}

export const CopyToClipboard = {
  mounted () {
    const element = this.el

    if (navigator.clipboard) {
      element.classList.remove('d-none')

      element.addEventListener('click', event => {
        event.preventDefault()

        helpers.copyElementTextToClipboard(element)
      })
    }
  },

  updated () {
    if (navigator.clipboard) {
      this.el.classList.remove('d-none')
    }
  }
}
