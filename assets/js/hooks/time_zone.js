export const TimeZone = {
  mounted () {
    this.el.value = window.Intl.DateTimeFormat().resolvedOptions().timeZone
  }
}
