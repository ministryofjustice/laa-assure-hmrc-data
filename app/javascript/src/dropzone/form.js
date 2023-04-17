import Dropzone from 'dropzone'

import {
  addErrorMessage,
  removeErrorMessages,
} from "./govuk_errors_helper";

const screenReaderMessageDelay = 1000 // wait before updating the screenreader message, to avoid interrupting queue

const ERR_GENERIC = 'There was a problem uploading FILENAME - try again'
const FILE_SIZE_ERR = 'FILENAME is larger than 7MB'
const ZERO_BYTE_ERR = 'FILENAME has no content'
const ERR_CONTENT_TYPE = 'FILENAME is not a valid file type'

// dropzone checks both the mimetype and the file extension so this list covers everything
const ACCEPTED_FILES = [
  '.csv',
  'text/csv',
]

document.addEventListener('DOMContentLoaded', event => {
  const dropzoneElem = document.querySelector('#dropzone-form')
  const statusMessage = document.querySelector(('#dropzone-upload-status-message'))

  if (dropzoneElem) {
    const url = document.querySelector('#dropzone-url').getAttribute('data-url')
    const chooseFilesBtn = document.querySelector('#dz-upload-button')

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

    const dropzone = new Dropzone(dropzoneElem, {
      url,
      headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      maxFilesize: 7,
      acceptedFiles: ACCEPTED_FILES.join(', '),
      disablePreviews: true,
      accept: function (file, done) {
        if (file.size === 0) {
          done('Empty files will not be uploaded.')
        } else { done() }
      }
    })
    dropzone.on('drop', () => {
      removeErrorMessages()
    })
    dropzone.on('addedfile', file => {
      setTimeout(() => { statusMessage.innerHTML = 'Your files are being uploaded.' }, screenReaderMessageDelay)
    })
    dropzone.on('sending', (file, xhr, formData) => {
      // Not needed?!
      // formData.append('bulk_submission_id', bulkSubmissionId)
    })
    dropzone.on('success', (file) => {
      dropzone.removeFile(file)
    })
    dropzone.on('queuecomplete', () => {
      // reload the partial to see the uploaded files
      const fileSection = document.querySelector('#uploaded-files-table-container')
      const url = window.location.pathname + '/list'
      const xmlHttp = new XMLHttpRequest() // eslint-disable-line no-undef
      xmlHttp.open('GET', url, false) // false for synchronous request
      xmlHttp.send(null)
      fileSection.innerHTML = xmlHttp.responseText
      setTimeout(() => { statusMessage.innerText = 'Your files have been uploaded successfully.' }, screenReaderMessageDelay)
    })
    dropzone.on('error', (file, response) => {
      let errorMsg = ''
      if (!ACCEPTED_FILES.includes(file.type)) {
        errorMsg = ERR_CONTENT_TYPE.replace('FILENAME', file.name)
      } else if (file.size >= 7000000) {
        errorMsg = FILE_SIZE_ERR.replace('FILENAME', file.name)
      } else if (file.size === 0) {
        errorMsg = ZERO_BYTE_ERR.replace('FILENAME', file.name)
      } else if (response.error !== '') {
        errorMsg = response.error
      } else {
        errorMsg = ERR_GENERIC.replace('FILENAME', file.name)
      }
      dropzone.removeFile(file)// add an error message to the error summary component
      addErrorMessage(errorMsg)
      if (errorMsg !== ERR_GENERIC) {
        errorMsg = ERR_GENERIC + errorMsg // make error message more informative for screenreaders
      }
      // update the screenreader message to alert the user of the error
      statusMessage.innerHTML = errorMsg
    })

    // aria-hide auto-generated dropzone input field so Wave doesn't complain
    const dzInput = document.querySelector('.dz-hidden-input')
    if (dzInput) {
      dzInput.style.display = 'none'
    }
  }
})
