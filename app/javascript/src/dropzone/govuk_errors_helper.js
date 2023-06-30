export function addErrorMessage (msg) {
  // this adds an error message to the gov uk error summary and shows the errors
  const errorSummary = document.querySelector('.govuk-error-summary')
  const ul = errorSummary.querySelector('ul')
  const li = document.createElement('li')
  const a = document.createElement('a')

  li.appendChild(a)
  ul.appendChild(li)

  // add text and link to field
  a.innerText += msg
  a.setAttribute('aria-label', msg)
  a.setAttribute('data-turbolinks', false)
  a.setAttribute('href', '#dz-upload-button')

  // show error message on the dropzone form field
  const dropzoneElem = document.querySelector('#dropzone-form-group')
  dropzoneElem.classList.add('govuk-form-group--error')
  const fieldErrorMsg = document.querySelector('#dropzone-file-error')
  const div = document.createElement('div')

  div.innerText = msg
  fieldErrorMsg.appendChild(div)
  fieldErrorMsg.classList.remove('hidden')

  // show the error summary and move focus to it
  errorSummary.classList.remove('hidden')
  errorSummary.scrollIntoView()
  errorSummary.focus()
}

export function removeErrorMessages () {
  document.querySelectorAll('.dropzone-error').forEach((dzError) => {
    if (dzError) {
      dzError.querySelectorAll('div').forEach((div) => {
        div.remove()
      })
    }
  })

  const errorSummary = document.querySelector('.govuk-error-summary')
  if (errorSummary) {
    errorSummary.querySelectorAll('li').forEach((listItem) => {
      listItem.remove()
    })
    errorSummary.classList.add('hidden') // toggle error-summary-hideable
  }

  document
    .querySelector('#dropzone-form-group')
    .classList.remove('govuk-form-group--error')
  document
    .querySelector('#dropzone-form-group > p.govuk-error-message')
    .classList.add('hidden')
}
