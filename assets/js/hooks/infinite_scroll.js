export const InfiniteScroll = {
  mounted () {
    this.observer = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          this.pushEvent('load-more')
        }
      }
    })

    this.observer.observe(this.el)
  },

  destroyed () {
    this.observer.disconnect()
  }
}
