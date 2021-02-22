export const UpdateSession = {
  mounted () {
    this.handleEvent('update-session', data => {
      const csrf     = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      const headers = {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrf
      }

      fetch(data.url, {method: 'put', headers: headers})
    })
  }
}
