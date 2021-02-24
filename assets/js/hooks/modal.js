import jQuery from 'jquery'

export const Modal = {
  mounted () {
    jQuery(this.el).modal('show')
  }
}
