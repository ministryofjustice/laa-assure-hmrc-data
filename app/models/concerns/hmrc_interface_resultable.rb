require "active_support/concern"

module HmrcInterfaceResultable
  extend ActiveSupport::Concern

 included do
    # returns integer or nil
    def tax_credit_annual_award_amount
      @tax_credit_annual_award_amount ||= child_tax_credit_award_total_entitlements&.first \
                                            || working_tax_credit_award_total_entitlements&.first
    end

    # returns integer or zero
    def clients_income_from_employment
      @clients_income_from_employment ||= gross_earnings_for_nics_in_pay_period_1&.sum || 0
    end

    # returns decimal or zero
    def clients_ni_contributions_from_employment
      @clients_ni_contributions_from_employment ||= employee_nics_in_pay_period_1&.sum || 0
    end

    # returns [multiline] string or nil
    def start_and_end_dates_for_employments
      @start_and_end_dates_for_employments ||= employment_start_and_end_dates&.join_compact_blank("\n")
    end

    # returns string or nil
    def most_recent_payment
      return unless payment_dates&.first && gross_earnings_for_nics_in_pay_period_1&.first

      @most_recent_payment ||= "#{payment_dates&.first}: #{gross_earnings_for_nics_in_pay_period_1&.first}"
    end

    # returns [multiline] string or nil
    def clients_income_from_self_employment
      @clients_income_from_self_employment ||=
        self_assessment_summary_tax_return_total_incomes_by_year&.join_compact_blank("\n")
    end

    # returns decimal or zero
    def clients_income_from_other_sources
      @clients_income_from_other_sources ||= sum_taxable_pay - clients_income_from_employment
    end

     # returns string or nil
    def most_recent_payment_from_other_sources
      return unless payment_dates&.first && taxable_pay&.first

      @most_recent_payment_from_other_sources ||=
        "#{payment_dates&.first}: #{most_recent_taxable_pay - most_recent_gross_earnings_for_nics_in_pay_period_1}"
    end

    # returns string or nil
    def error
      @error ||= data&.second&.fetch("error", nil)
    end

    # returns array of hashes
    def data
      @data ||= hmrc_interface_result.with_indifferent_access["data"]
    end

  private

    # returns array of hashes
    def child_tax_credits
      @child_tax_credits ||=
        data&.fetch_first("benefits_and_credits/child_tax_credit/applications")
    end

    # returns array of hashes
    def child_tax_credit_awards
      @child_tax_credit_awards ||= child_tax_credits&.fetch_all("awards")
    end

    # returns array of decimals
    def child_tax_credit_award_total_entitlements
      @child_tax_credit_award_total_entitlements ||=
        child_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns array of hashes
    def working_tax_credits
      @working_tax_credits ||=
        data&.fetch_first("benefits_and_credits/working_tax_credit/applications")
    end

    # returns array of hashes
    def working_tax_credit_awards
      @working_tax_credit_awards ||= working_tax_credits&.fetch_all("awards")
    end

    # returns array of decimals
    def working_tax_credit_award_total_entitlements
      @working_tax_credit_award_total_entitlements ||=
        working_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns hash
    def income_paye_paye
      @income_paye_paye ||= data&.fetch_first("income/paye/paye")
    end

    # returns array of hashes
    def income
      @income ||= income_paye_paye&.fetch("income", nil)
    end

    # returns array of hashes
    def gross_earnings_for_nics
      @gross_earnings_for_nics ||= income&.fetch_all("grossEarningsForNics")
    end

    # returns array of decimals
    def taxable_pay
      @taxable_pay ||= income&.fetch_all("taxablePay")
    end

    # returns decimal or zero
    def most_recent_taxable_pay
      @most_recent_taxable_pay ||= taxable_pay&.first || 0
    end

    # returns decimal or zero
    def sum_taxable_pay
      @sum_taxable_pay ||= taxable_pay&.sum || 0
    end

    # returns array of decimals
    def gross_earnings_for_nics_in_pay_period_1
      @gross_earnings_for_nics_in_pay_period_1 ||=
        gross_earnings_for_nics&.fetch_all("inPayPeriod1")
    end

    # returns decimal or zero
    def most_recent_gross_earnings_for_nics_in_pay_period_1
      @most_recent_gross_earnings_for_nics_in_pay_period_1 ||= gross_earnings_for_nics_in_pay_period_1&.first || 0
    end

    # returns array of decimals
    def employee_nics_in_pay_period_1
      @employee_nics_in_pay_period_1 ||= employee_nics&.fetch_all("inPayPeriod1")
    end

    # returns array of hashes
    def employee_nics
      @employee_nics ||= income&.fetch_all("employeeNics")
    end

    # returns array of string dates
    def payment_dates
      income&.fetch_all("paymentDate")
    end

    # returns array of hashes
    def employments
      @employments ||= data&.fetch_first("employments/paye/employments")
    end

    # returns [multiline] string or ""
    def employment_start_and_end_dates
      @employment_start_and_end_dates ||=
        employments&.map do |emp|
          "#{emp&.fetch("startDate")} to #{emp&.fetch("endDate")}"
        end
    end

    # returns hash
    def self_assessment_summary
      @self_assessment_summary ||=
        data&.fetch_first("income/sa/summary/selfAssessment")
    end

    # returns array of hashes
    def self_assessment_summary_tax_returns
      @self_assessment_summary_tax_returns ||=
        self_assessment_summary&.fetch("taxReturns", nil)
    end

    # returns array of strings
    def self_assessment_summary_tax_return_total_incomes_by_year
      @self_assessment_summary_tax_return_total_incomes_by_year ||=
        self_assessment_summary_tax_returns&.map do |tax_return|
          tax_return_with_year(tax_return)
        end
    end

    # returns string
    def tax_return_with_year(tax_return)
      summaries = tax_return&.fetch("summary", nil)

      total_incomes = summaries.map do |summary|
        summary&.fetch("totalIncome", nil)
      end

      "#{tax_return&.fetch("taxYear", nil)}: #{total_incomes.join(", ")}"
    end
  end
end
