export const UpdateSession = {
  destroyed () {
    const csrf    = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    const headers = {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf
    }

    fetch(this.el.dataset.url, {method: 'put', headers: headers})
  }
}
