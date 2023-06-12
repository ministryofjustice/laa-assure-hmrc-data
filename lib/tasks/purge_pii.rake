namespace :purge do
  desc "Purge/anonymise records more than one month old"
  task anonymise: :environment do
    bulk_submissions = BulkSubmission.where(created_at: 1.hour.ago..)
    bulk_submissions.each do |bulk_submission|
      bulk_submission.original_file.purge
      bulk_submission.purged!
      bulk_submission.submissions.each do |submission|
        submission.update!(first_name: 'purged', last_name: 'purged', dob: '01/01/1970', nino: 'AB123456C')
      end
    end
  end
end
