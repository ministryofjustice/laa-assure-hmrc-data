import Dropzone from 'dropzone'

import {
  addErrorMessage,
  removeErrorMessages
} from './govuk_errors_helper'

document.addEventListener('DOMContentLoaded', event => {
  const uploadForm = document.querySelector('.upload-file-form')
  const dropzoneElem = document.querySelector('#dropzone-form')
  const statusMessage = document.querySelector('#dropzone-upload-status-message')

  if (dropzoneElem) {
    const url = uploadForm.action
    const _method = uploadForm.querySelector("input[name='_method']")
    const method = _method ? _method.value : 'post'
    const chooseFilesBtn = document.querySelector('#dz-upload-button')
    const paramName = 'uploaded_file'

    chooseFilesBtn.addEventListener('click', (e) => {
      e.preventDefault() // prevent submitting form by default
      removeErrorMessages()
    })

    // use enter key to add files
    chooseFilesBtn.addEventListener('keydown', (e) => {
      const KEY_ENTER = 13
      if (e.keyCode === KEY_ENTER) {
        e.preventDefault() // prevent submitting form by default
        removeErrorMessages()
      }
    })

    // Note on error handling:
    // We do not use dropzone options such as accept, acceptedFiles
    // and maxFilesize, preferring instead to use rails/ruby
    // validation to enforce these rules.Rails validation
    // errors are then returned as JSON. This provides consistent
    // JS-disabled and JS-enabled error messaging.
    const dropzone = new Dropzone(dropzoneElem, {
      url,
      method,
      headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      paramName,
      disablePreviews: true,
      uploadMultiple: false,
      maxFiles: 1
    })
    dropzone.on('drop', (e) => {
      removeErrorMessages()
    })
    dropzone.on('addedfile', file => {
      statusMessage.innerHTML = 'Your file is being uploaded.'
    })
    dropzone.on('sending', (file, xhr, formData) => {
    })
    dropzone.on('success', (file) => {
      dropzone.removeFile(file.name)

      const redirectUrl = file.xhr.getResponseHeader('Location')
      window.location = redirectUrl
    })
    dropzone.on('complete', (file) => {
    })
    dropzone.on('error', (file, response) => {
      dropzone.removeFile(file)

      // dropzone errors, configurable using its options such as `acceptedFiles`,
      // are returned here as a response STRING, whereas the app returns the
      // bulk_submission_form object errors as a response JSON hash with an array for the
      // uploaded_file attribute (specified by paramName).
      //
      // also, update the screenreader message to alert the user of the error
      //
      statusMessage.innerHTML = 'There was a problem uploading the file. '

      if (typeof response === 'string' || response instanceof String) {
        addErrorMessage(response)
        statusMessage.innerHTML += response
      } else {
        response.errors[paramName].forEach(function (message) {
          addErrorMessage(message)
          statusMessage.innerHTML += ` ${message}.`
        })
      }
    })

    // aria-hide auto-generated dropzone input field so Wave doesn't complain
    const dzInput = document.querySelector('.dz-hidden-input')
    if (dzInput) {
      dzInput.style.display = 'none'
    }
  }
})
