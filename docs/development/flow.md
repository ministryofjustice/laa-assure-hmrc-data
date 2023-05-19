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
        - HmrcInterfaceSubmissionService
         - HmrcInterfaceResultsWorker (retry upto x times)
          - HmrcInterfaceResultService
      - HmrcInterfaceSubmissionWorker (on uc-two-submission queue)
        - HmrcInterfaceSubmissionService
         - HmrcInterfaceResultsWorker (retry upto x times)
          - HmrcInterfaceResultService
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
  * container with processor for "default-my-branch-name" queue with concurrency of 5
  * container with processor for for "uc-one-submissions-my-branch-name" queue with concurrency of 1
  * container with processor for for "uc-two-submissions-my-branch-name" queue with concurrency of 1

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
  Uploading a bulk submission file and processing it via the app locally
  will not work because there are no queues (and therefore no processes) specified in the `config/sidekiq.yml`. However the `BulkSubmissionsWorker`
  job will be enqueued on the fallback `default` queue.

  Running `bundle exec sidekiq [-q default]` in another terminal will, however, create a single process for the `default` queue, with X threads. This processor will then process the `BulkSubmissionsWorker` job and thereby create uc-one-submissions and uc-two-submissions queues and enqueue jobs on them, namely the `HmrcInterfaceSubmissionWorker` job. Because there are no processes for those queues they will not be processed. However, If you run `bin/dev` later then processes for those queues will be created and they will be processed using any configured HMRC Interface host.

  Therefore you should
  - take note of settings in `env.development` related to HMRC_INTERFACE...
  - you should clear enqueued and scheduled jobs before running `bin/dev`

  ```ruby
  # delete all scheduled jobs
  Sidekiq::ScheduledSet.new.map(&:delete)

  # delete all jobs on named queue
  Sidekiq::Queue.new("default").map(&:delete)
  Sidekiq::Queue.new("uc-one-submissions").map(&:delete)
  Sidekiq::Queue.new("uc-two-submissions").map(&:delete)
  ```

- test
  Webmock disables all external requests so stubbing is needed. Warnings will be raised by tests that make actual requests. You can add `require sidekiq/testing` which defaults to enabling `Sidekiq::Testing.fake!`.

### Status change flow

- bulk_submissions
 - pending
 - preparing
 - prepared
 - processing (completing instead?!)
 - completed

- submissions
 - pending
 - submitting
 - submitted
 - completing
 - created || processing [temporary status from API]
 - completed || failed [finished status from API]

## Other options
- add a processed_at timestamp to bulk_submissions and update when appropriate
- add a processed_at timestamp to submissions and update when appropriate

## Possible refactoring
- [ ] dependency inversion (inject lib based hmrc interface request objects into submission and result services)
- [ ] "status" machine mixin (pending!, pending? etc) for bulk submissions and subdmissions
- [ ] extract SubmissionRecord struct to its own class and share with validator
- [ ] extract HmrcInterfaceBaseWorker sidekiq options to mixin in lib hmrc interface and include in current subclasses of HmrcInterfaceBaseWorker, then delete HmrcInterfaceBaseWorker
