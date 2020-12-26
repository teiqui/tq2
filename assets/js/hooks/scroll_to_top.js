export const ScrollToTop = {
  mounted () {
    this.el.addEventListener('click', () => {
      setTimeout(() => {
        window.scroll({
          top: 0,
          left: 0,
          behavior: 'smooth'
        })
      }, 50)
    })
  }
}
