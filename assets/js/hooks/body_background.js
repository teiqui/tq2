export const BodyBackground = {
  mounted () {
    const newBackgroundClass = this.el.dataset.bgClass
    const body = document.querySelector('body')

    body.classList.remove('bg-light')
    body.classList.add(newBackgroundClass)
  },

  destroyed () {
    const backgroundClass = this.el.dataset.bgClass
    const body = document.querySelector('body')

    body.classList.remove(backgroundClass)
    body.classList.add('bg-light')
  }
}
