import jQuery from 'jquery'

export const Modal = {
  mounted () {
    const $dialog = jQuery(this.el)

    if (this.el.dataset.show) {
      $dialog.modal('show')
    } else {
      this.handleShowModal($dialog)
      this.handleHideModal($dialog)
    }
  },

  handleShowModal ($dialog) {
    this.handleEvent('showModal', () => {
      $dialog.modal('show')
    })
  },

  handleHideModal ($dialog) {
    this.handleEvent('hideModal', () => {
      $dialog.on('hidden.bs.modal', _event => {
        this.pushEvent('redirect')
      })

      $dialog.modal('hide')
    })
  }
}
