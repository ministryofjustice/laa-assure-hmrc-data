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
      @clients_income_from_employment ||= gross_earnings_for_nics_in_pay_period_1&.sum
    end

    # returns decimal or zero
    def clients_ni_contributions_from_employment
      @clients_ni_contributions_from_employment ||= employee_nics_in_pay_period_1&.sum
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
      key = "benefits_and_credits/child_tax_credit/applications"
      @child_tax_credits ||= data&.fetch_first(key, nil)
    end

    # returns array of hashes
    def child_tax_credit_awards
      @child_tax_credit_awards ||=
        child_tax_credits&.fetch_all("awards")
    end

    # returns array of decimals
    def child_tax_credit_award_total_entitlements
      @child_tax_credit_award_total_entitlements ||=
        child_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns array of hashes
    def working_tax_credits
      key = "benefits_and_credits/working_tax_credit/applications"
      @working_tax_credits ||= data&.fetch_first(key, nil)
    end

    # returns array of hashes
    def working_tax_credit_awards
      @working_tax_credit_awards ||=
        working_tax_credits&.fetch_all("awards")
    end

    # returns array of decimals
    def working_tax_credit_award_total_entitlements
      @working_tax_credit_award_total_entitlements ||=
        working_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns hash
    def income_paye_paye
      key = "income/paye/paye"
      @income_paye_paye ||= data&.fetch_first(key, nil)
    end

    # returns array of hashes
    def income
      @income ||= income_paye_paye&.fetch("income", nil)
    end

    # returns array of hashes
    def gross_earnings_for_nics
      @gross_earnings_for_nics ||= income&.fetch_all("grossEarningsForNics")
    end

    # returns array of integers
    def gross_earnings_for_nics_in_pay_period_1
      @gross_earnings_for_nics_in_pay_period_1 ||=
        gross_earnings_for_nics&.fetch_all("inPayPeriod1")
    end

    # returns array of decimals
    def employee_nics_in_pay_period_1
      @employee_nics_in_pay_period_1 ||= employee_nics&.fetch_all("inPayPeriod1")
    end

    # returns array of hashes
    def employee_nics
      @employee_nics ||= income&.fetch_all("employeeNics")
    end

  end
end
