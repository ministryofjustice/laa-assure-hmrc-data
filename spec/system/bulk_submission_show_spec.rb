require "system_helper"

RSpec.describe "View bulk submission show page", type: :system do
  context "with unauthorised user" do
    before { bulk_submission }

    let(:bulk_submission) do
      create(:bulk_submission, :with_original_file, :pending)
    end

    it "redirects user back to landing page" do
      visit "/bulk_submissions/#{bulk_submission.id}"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user" do
    before do
      bulk_submission
      sign_in user
    end

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    context "with an existing pending bulk submission" do
      let(:bulk_submission) do
        create(:bulk_submission, :with_original_file, :pending)
      end

      it "user can view it" do
        visit "/bulk_submissions/#{bulk_submission.id}"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "About this file"
        )
        expect(page).to have_link("Back")

        within(".govuk-summary-list") do
          expect(page).to have_selector(
            ".govuk-summary-list__value",
            text: bulk_submission.user.full_name
          ).and have_selector(
                  ".govuk-summary-list__value",
                  text: bulk_submission.created_at.strftime("%d %b %Y")
                ).and have_selector(
                        ".govuk-summary-list__value",
                        text: "basic_bulk_submission.csv"
                      ).and have_selector(
                              ".govuk-summary-list__value .govuk-tag.govuk-tag--yellow",
                              text: /Pending/i
                            )
        end

        expect(page).not_to have_button("Confirm")
        expect(page).not_to have_link("Download")
      end

      it "user can cancel it" do
        visit "/bulk_submissions"

        click_link("Cancel", match: :one)
        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Are you sure you want to cancel this check?"
        )

        expect(page).to have_button(
          "Yes, cancel check on basic_bulk_submission.csv"
        )
        expect(page).not_to have_link("Download")

        click_button("Yes, cancel check on basic_bulk_submission.csv")

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Checked details"
        )
        expect(page).to have_selector(
          ".govuk-notification-banner__content",
          text: "You've cancelled the check on basic_bulk_submission.csv"
        )
        expect(page).not_to have_selector(".govuk-table__body tr")
      end
    end

    context "with an existing ready bulk submission" do
      let(:bulk_submission) do
        create(
          :bulk_submission,
          :with_original_file,
          :with_result_file,
          :ready,
          expires_at: Time.current.midnight + 1.day
        )
      end

      it "user can view it" do
        visit "/bulk_submissions/#{bulk_submission.id}"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "About this file"
        )
        expect(page).to have_link("Back")

        within(".govuk-summary-list") do
          expect(page).to have_selector(
            ".govuk-summary-list__value",
            text: bulk_submission.user.full_name
          ).and have_selector(
                  ".govuk-summary-list__value",
                  text: bulk_submission.created_at.strftime("%d %b %Y")
                ).and have_selector(
                        ".govuk-summary-list__value",
                        text: bulk_submission.expires_at.strftime("%d %b %Y")
                      ).and have_selector(
                              ".govuk-summary-list__value",
                              text: "basic_bulk_submission.csv"
                            ).and have_selector(
                                    ".govuk-summary-list__value .govuk-tag.govuk-tag--green",
                                    text: /Ready/i
                                  )
        end

        expect(page).not_to have_button("Confirm")
        expect(page).to have_link(
          "Download results file for basic_bulk_submission.csv"
        )
      end

      it "user can remove it" do
        visit "/bulk_submissions"

        click_link("Remove", match: :one)
        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Are you sure you want to remove this file?"
        )

        expect(page).to have_button(
          "Yes, remove file basic_bulk_submission.csv"
        )
        expect(page).to have_link(
          "Download results file for basic_bulk_submission.csv"
        )

        click_button("Yes, remove file basic_bulk_submission.csv")

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Checked details"
        )
        expect(page).to have_selector(
          ".govuk-notification-banner__content",
          text: "You've removed basic_bulk_submission.csv"
        )
        expect(page).not_to have_selector(".govuk-table__body tr")
      end

      it "user can download it", js: true do
        visit "/bulk_submissions/#{bulk_submission.id}"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "About this file"
        )
        expect(page).to have_link(
          "Download results file for basic_bulk_submission.csv"
        )

        click_link(
          "Download results file for basic_bulk_submission.csv",
          match: :one
        )
        wait_for_download

        expect(downloads.length).to eq(1)
        expect(download).to match(/basic_bulk_submission-result.csv/)
      end
    end

    context "with an existing processing bulk_submission" do
      let(:bulk_submission) do
        create(:bulk_submission, :with_original_file, :processing)
      end

      it "user can view it" do
        visit "/bulk_submissions/#{bulk_submission.id}"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "About this file"
        )

        within(".govuk-summary-list") do
          expect(page).to have_selector(
            ".govuk-summary-list__value",
            text: bulk_submission.user.full_name
          ).and have_selector(
                  ".govuk-summary-list__value",
                  text: bulk_submission.created_at.strftime("%d %b %Y")
                ).and have_selector(
                        ".govuk-summary-list__value",
                        text: "basic_bulk_submission.csv"
                      ).and have_selector(
                              ".govuk-summary-list__value .govuk-tag.govuk-tag--blue",
                              text: /Processing/i
                            )
        end

        expect(page).not_to have_button("Confirm")
        expect(page).not_to have_link("Download")
      end

      it "user can NOT remove it" do
        visit "/bulk_submissions/#{bulk_submission.id}?context=remove"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Are you sure you want to remove this file?"
        )
        expect(page).not_to have_button("Confirm")
        expect(page).not_to have_link("Download")
      end
    end

    context "with an existing exhausted bulk_submission" do
      let(:bulk_submission) do
        create(:bulk_submission, :with_original_file, :exhausted)
      end

      it "user can view it" do
        visit "/bulk_submissions/#{bulk_submission.id}"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "About this file"
        )

        within(".govuk-summary-list") do
          expect(page).to have_selector(
            ".govuk-summary-list__value",
            text: bulk_submission.user.full_name
          ).and have_selector(
                  ".govuk-summary-list__value",
                  text: bulk_submission.created_at.strftime("%d %b %Y")
                ).and have_selector(
                        ".govuk-summary-list__value",
                        text: "basic_bulk_submission.csv"
                      ).and have_selector(
                              ".govuk-summary-list__value .govuk-tag.govuk-tag--red",
                              text: /Exhausted/i
                            )
        end

        expect(page).not_to have_button("Confirm")
        expect(page).not_to have_link("Download")
      end

      it "user can remove it" do
        visit "/bulk_submissions/#{bulk_submission.id}?context=remove"

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Are you sure you want to remove this file?"
        )
        expect(page).to have_button(
          "Yes, remove file basic_bulk_submission.csv"
        )
        expect(page).not_to have_link("Download")

        click_button("Yes, remove file basic_bulk_submission.csv")

        expect(page).to have_selector(
          ".govuk-heading-xl",
          text: "Checked details"
        )
        expect(page).to have_selector(
          ".govuk-notification-banner__content",
          text: "You've removed basic_bulk_submission.csv"
        )
        expect(page).not_to have_selector(".govuk-table__body tr")
      end
    end
  end
end
