export const ShrinkOnScroll = {
  mounted () {
    window.onscroll = () => {
      const scrollTop = document.body.scrollTop || document.documentElement.scrollTop

      if (scrollTop > 80) {
        this.el.classList.add('nav-shrink')
      } else {
        this.el.classList.remove('nav-shrink')
      }
    }
  }
}
