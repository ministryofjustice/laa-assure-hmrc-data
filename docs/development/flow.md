# Submission process notes


## Processing of a bulk submission file after upload

1. user uploads file
2. use hits save and continue
3. BulkSubmissionWorker.perform_async(bulk_submission_id) called
4. BulkSubmissionWorker job enqueued with arguments including bulk_submission_id
5. BulkSubmissionWorker job performed, calling BulkSubmissionService.call with bulk_submission object
6. BulkSubmissionService processing commences, marking the status as preparing

7. BulkSubmissionService perform the following:
  - updates bulk submission status as :preparing
  - for each record in bulk submission's attached original_file
    - create use case one submission record with client details, start and end date, status: pending
    - create use case two submission record with client details, start and end date, status: pending
 - updates bulk submission status as :pending


```text
# workers and services summary
- BulkSubmissionWorker
  - BulkSubmissionService
```

## Processing of requests to HmrcInterface

8. A scheduled job, HmrcInterfaceBulkSubmissionsWorker (note the plural) job , is performed at 9pm, calling HmrcInterfaceBulkSubmissionWorker (note the singular) for each bulk submission in a pending state.

9. HmrcInterfaceBulkSubmissionWorker (singular) identifies pending submissions associated with that bulk submission and calls HmrcInterfaceSubmissionWorker for each submission

10. HmrcInterfaceSubmissionWorker

 - enqueues HmrcInterfaceSubmissionService on uc-one-submission
 - enqueues HmrcInterfaceSubmissionService on uc-two-submission

11. HmrcInterfaceSubmissionService
 - updates submission status to :processing
 - calls HmrcInterface::Request::Submission for that submission.
 - awaits the response and updates the submissions hmrc_interface_id with the response's id
 - enqueues/calls an HmrcInterfaceResultsWorker to be performed in 5 seconds, passing the submission record id (or hmrc_interface_id )
 `HmrcInterfaceResultsWorker.perform_in(5.seconds, id)`

12. HmrcInterfaceResultsWorker calls HmrcInterfaceResultsService for the submission rec id (or hmrc_interface_id)

13. HmrcInterfaceResultsService performs the following:
  - calls HmrcInterface::Request::Result
  - updates submission.hmrc_interface_result with response
  - updates submission.status to that of response ("completed", "processing" or "failed")
  - marks worker to cease trying if "failed" or "completed"
  - marks worker to retry if "processing", upto


```text
# workers and services summary
- HmrcInterfaceBulkSubmissionsWorker (plural)
  - HmrcInterfaceBulkSubmissionWorker (singular)
    - HmrcInterfaceSubmissionWorker
      - HmrcInterfaceSubmissionService (on uc-one-submission queue)??
       - HmrcInterfaceResultsWorker (on uc-one-submission queue)??
    - HmrcInterfaceSubmissionWorker
      - HmrcInterfaceSubmissionService (on uc-two-submission queue)??
       - HmrcInterfaceResultsWorker (on uc-one-submission queue)??

```

## Other options
- nest workers
- add a processed_at timestamp to bulk_submissions
- add a processed_at timestamp to submissions


## Naming options

- process a single new bulk submission's submission records?
 - BulkSubmissionWorker
 - BulkSubmissionsProcessor
 - ProcessBulkSubmissionWorker
 - PrepareBulkSubmissionsWorker **
 - PendingBulkSubmissionsWorker

Purpose:
 - for each submission record in csv/file, create:
     - use case one submission record with client details, start and end date, status: pending
     - use case two submission record with client details, start and end date, status: pending

### other (future) workers?

- Validate new bulk submission
  - ValidatePendingBulkSubmissionWorker
  - ValidateNewBulkSubmissionWorker

- Process pending submissions
  - ProcessPendingSubmissionsWorker
  - ProcessPendingSubmissionsWorker

- Purge sensitive data
 - PurgeBulkSubmissionsWorker
 - PurgePIIWorker
 - PurgeExpiredDataWorker
