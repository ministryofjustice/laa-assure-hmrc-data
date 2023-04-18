// Note on error handling:
// We do not use dropzone options such as accept, acceptedFiles
// and maxFilesize, preferring instead to use rails/ruby
// validation to enforce these rules.Rails validation
// errors are then returned as JSON. This provides consistent
// JS-disabled and JS-enabled error messaging.

// Dropzone errors, configurable using its options, are returned to the `error`
// event via the response argument. These errors are simple STRINGs, whereas
// the app returns the bulk_submission_form object errors JSON with an array for
// the `uploaded_file`` attribute (specified by paramName). Therefore the
// `error` event handles both these possible response types.
//
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
    })

    const dropzone = new Dropzone(dropzoneElem, {
      url,
      method,
      headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
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
      removeErrorMessages()
    })
    dropzone.on('sending', (file, xhr, formData) => {
    })
    dropzone.on('success', (file) => {
      dropzone.removeFile(file.name)

      const redirectUrl = file.xhr.getResponseHeader('Location')
      window.location = redirectUrl
    })
    dropzone.on('error', (file, response) => {
      dropzone.removeFile(file)
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
