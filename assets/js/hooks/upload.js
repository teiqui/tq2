export const Upload = {
  mounted () {
    const target = document.querySelector(this.el.dataset.target)

    if (target) {
      this.el.addEventListener('click', () => {
        target.click()
      })
    }
  }
}
