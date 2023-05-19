# Submission process notes


## Processing of requests to HmrcInterface

* BulkSubmissionsWorker (plural) called by scheduled job
    This finds all pending bulk submissions and calls the BulkSubmissionWorker (singular) for each

* BulkSubmissionsWorker (plural) calls BulkSubmissionWorker (singular) for all pending bulk submissions

* BulkSubmissionWorker (singular) calls BulkSubmissionService.call for each bulk_submission

* BulkSubmissionService performs the following:
  - updates bulk submission status as :preparing
  - for each record in bulk submission's attached original_file
    - create use case one submission record with client details, start and end date, status: pending
    - create use case two submission record with client details, start and end date, status: pending
 - updates bulk submission status as :prepared
 - enqueues HmrcInterfaceBulkSubmissionWorker for the bulk_submission

* HmrcInterfaceBulkSubmissionWorker job , is performed at 9pm, calling HmrcInterfaceBulkSubmissionWorker (note the singular) for each bulk submission in a pending state.

* HmrcInterfaceBulkSubmissionWorker (singular) identifies pending submissions associated with that bulk submission and calls HmrcInterfaceSubmissionWorker for each submission

* HmrcInterfaceSubmissionWorker

 - enqueues HmrcInterfaceSubmissionService on uc-one-submission
 - enqueues HmrcInterfaceSubmissionService on uc-two-submission

* HmrcInterfaceSubmissionService
 - updates submission status to :processing
 - calls `HmrcInterface::Request::Submission` for that submission.
 - awaits the response and updates the submissions hmrc_interface_id with the response's id
 - enqueues/calls an HmrcInterfaceResultsWorker to be performed in 10 seconds, passing the submission record id (or hmrc_interface_id)

* HmrcInterfaceResultWorker calls HmrcInterfaceResultsService

* HmrcInterfaceResultsService performs the following:
  - calls HmrcInterface::Request::Result
  - updates submission.hmrc_interface_result with response
  - updates submission.status to that of response ("completed", "created", "processing" or "failed")
  - succeeds if response status is "failed" or "completed"
  - retries if "processing" or "created" by rausing TryAgain error


```text
# workers and services summary
- BulkSubmissionsWorker (plural)
  - BulkSubmissionWorker (singular)
   - BulkSubmissionService
    - HmrcInterfaceBulkSubmissionWorker (singular)
      - HmrcInterfaceSubmissionWorker (on uc-one-submission queue)
        - HmrcInterfaceSubmissionService (uses HmrcInterface::Request::Submission)
         - HmrcInterfaceResultsWorker (retry upto x times)
          - HmrcInterfaceResultService (HmrcInterface::Request::Result)
      - HmrcInterfaceSubmissionWorker (on uc-two-submission queue)
        - HmrcInterfaceSubmissionService
         - HmrcInterfaceResultsWorker (retry upto x times)
          - HmrcInterfaceResultService (HmrcInterface::Request::Result)
```

## Processes, dynamic queue names and concurrency

Processes, dynamic queue names and concurrency are handled through a combination
of github deployment actions (helm) for hosted environments and creating processes
that only process specific queues with a specific concurrency. Local development
emulates this through use of `bin/dev` (which calls Procfile.dev).

- production (uat)
  creation of workers/processes for specific queues with specific concurrency is handled
  via deployment-worker.yml the github deployment for uat action and codebase
  setting of queues for a uat environment's branch.

  This creates:
  * container with processor for "default-<branch-name>" queue with concurrency of 5
  * container with processor for for "uc-one-submissions-<branch-name>" queue with concurrency of 1
  * container with processor for for "uc-two-submissions-<branch-name>" queue with concurrency of 1

- production (staging and production)
  creation of workers for specific queues with specific concurrency is handled
  via deployment-worker.yml the github deployment action and codebase
  setting of queues for any non-uat environment.

  This creates:
  * container with processor for "default" queue with concurrency of 5
  * container with processor for "uc-one-submissions" queue with concurrency of 1
  * container with processor for "uc-two-submissions" queue with concurrency of 1

 - development with `bin/dev`
  `bin/dev` calls Procfile.dev which creates:
  * process (worker) for "default" queue with concurrency of 5
  * process (worker) for "uc-one-submissions" queue with concurrency of 1
  * process (worker) for "uc-two-submissions" queue with concurrency of 1

- development with `rails server`
 won't work??

- test
 ??


### Status change flow

- bulk_submissions
 - pending
 - preparing
 - prepared
 - processing (completing instead?!)
 - completed

- submissions
 - pending
 - preparing
 - prepared
 - submitting
 - submitted
 - completing
 - created || processing [temporary status from API]
 - completed || failed [finished status from API]

## Other options
- add a processed_at timestamp to bulk_submissions
- add a processed_at timestamp to submissions
- mixin for status "machine" to include in BulkSubmission and Submission models?
