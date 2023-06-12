# Sidekiq flows - submission process notes

## Processing of requests to HmrcInterface

### Workers and services flow summary

The following is a summary of the flow from workers to nested workers and services.

The isolation of separate workers is intended to make each step capable of handling errors and retries as required. The use of two queues, uc-one..and uc-two..., is to emulate what hmrc
interface does itself, and ultimately reflects the throttling HMRC enforces on a per use
case basis.

```ruby
# Workers/jobs, services flows and nesting (including queues used where not `default`)
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
      - BulkSubmissionStatusWorker
        - BulkSubmissionResultWriterWorker
          - BulkSubmissionResultWriterService

```

## Processes, dynamic queue names and concurrency

Processes, dynamic queue names and concurrency are handled through a combination
of github deployment actions (helm) for hosted environments and creating processes
that only process specific queues with a specific concurrency. Local development
emulates this through use of `bin/dev` (which calls Procfile.dev).

### production (uat)
  creation of workers/processes for specific queues with specific concurrency is handled
  via `deployment-worker.yml`, the github deployment for uat action and codebase
  setting of queues for a uat environment's branch.

  This creates:
  * container with processor for "default-my-branch-name" queue with concurrency of 5
  * container with processor for for "uc-one-submissions-my-branch-name" queue with concurrency of 1
  * container with processor for for "uc-two-submissions-my-branch-name" queue with concurrency of 1
### production (staging and production)
  creation of workers for specific queues with specific concurrency is handled
  via deployment-worker.yml the github deployment action and codebase
  setting of queues for any non-uat environment.

  This creates:
  * container with processor for "default" queue with concurrency of 5
  * container with processor for "uc-one-submissions" queue with concurrency of 1
  * container with processor for "uc-two-submissions" queue with concurrency of 1

### development with `bin/dev`
  `bin/dev` executes `Procfile.dev` which emulates a production-like set of processes
  \- web, sidekiq-workers and queues

  This creates
  * process (worker) for "default" queue with concurrency of 5
  * process (worker) for "uc-one-submissions" queue with concurrency of 1
  * process (worker) for "uc-two-submissions" queue with concurrency of 1

### development with `rails server`
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

### test
  Webmock disables all external requests so stubbing is needed. Warnings will be raised by tests that make actual requests. Sidekiq testing's fake mode is enabled by default via a `require sidekiq/testing` in `rails_helper.rb`. see [sidekiq testing](https://github.com/sidekiq/sidekiq/wiki/Testing)

### Status change flow

#### Bulk submissions

| Status     | Description                                                                                                                           | Order |
|------------|---------------------------------------------------------------------------------------------------------------------------------------|-------|
| pending    | Initial status of bulk_submission once the original_file has been attached to it                                                      | 1     |
| preparing  | Submission records are being created 2 for each row in the original_file - one per use case (one and two)                             | 2     |
| prepared   | Submission records have been created                                                                                                  | 3     |
| processing | Requests for data from HMRC are being made for each of the created submission records                                                 | 4     |
| completed  | All requests made to HMRC have finished for this bulk_submission - each submission could have been completed, failed or exhausted     | 5     |
| writing    | Responses from HMRC for each submission are being written to a result_file                                                            | 6     |
| ready      | All response written to a file and the file has been attached to the bulk_submission  record                                          | 7a    |
| exhausted  | The bulk_submission job was unable to be completed within the given timeframe  - 6 checks over a period of approx 20 minutes in total | 7b    |
| purged  | The bulk_submission is more than 1 month old and has been purged | 8    |

#### Submissions
| Status     | Description                                                                                                                                                                | Order |
|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| pending    | Initial status of submission record on creation                                                                                                                            | 1     |
| submitting | Request for data from HMRC being made                                                                                                                                      | 2     |
| submitted  | Response received from HMRC indicating request was recieved and is being processed                                                                                         | 3     |
| completing | Request for result from HMRC being made                                                                                                                                    | 4     |
| created    | Response for result from HMRC informing us that they have created the request from the HMRC API                                                                            | 5a    |
| processing | Response for result from HMRC informing us that they are still processing the request via the HMRC API                                                                     | 5b    |
| completed  | Response for result from HMRC providing us with client details that they have found                                                                                        | 6a    |
| failed     | Response for result from HMRC informing us that client details were not found or possibly  that there has been an error that it has handled. The body contains the details | 6b    |
| exhausted  | Attempts to retrieve a result have been exhausted within a given timeframe - 5 checks over a period of approx 9 minutes in total                                           | 6c    |

