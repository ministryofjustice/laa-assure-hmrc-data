require "active_support/concern"

module HmrcInterfaceResultable
  extend ActiveSupport::Concern

 included do
    # returns integer or nil
    def tax_credit_annual_award_amount
      @tax_credit_annual_award_amount ||= child_tax_credit_award_total_entitlements&.first \
                                            || working_tax_credit_award_total_entitlements&.first
    end

    # Sum all of "income/paye/paye":"income":["grossEarningsForNics"]:"inPayPeriod1"
    def clients_income_from_employment
      gross_earnings_for_nics_in_pay_period_1&.sum
    end

    # returns string or nil
    def error
      @error ||= data&.second&.fetch("error", nil)
    end

    # returns array
    def data
      @data ||= hmrc_interface_result.with_indifferent_access["data"]
    end

  private

    # returns array
    def child_tax_credits
      key = "benefits_and_credits/child_tax_credit/applications"
      @child_tax_credits ||= data&.find { |el| el.key?(key) }&.fetch(key, nil)
    end

    # returns array
    def child_tax_credit_awards
      @child_tax_credit_awards ||= child_tax_credits
        &.find_all { |el| el.key?("awards") }
        &.flat_map { |el| el["awards"] }
    end

    # returns array
    def child_tax_credit_award_total_entitlements
      @child_tax_credit_award_total_entitlements ||=
        child_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns array
    def working_tax_credits
      key = "benefits_and_credits/working_tax_credit/applications"
      @working_tax_credits ||= data&.find { |el| el.key?(key) }&.fetch(key, nil)
    end

    # returns array
    def working_tax_credit_awards
      @working_tax_credit_awards ||= working_tax_credits
        &.find_all { |el| el.key?("awards") }
        &.flat_map { |el| el["awards"] }
    end

    # returns array
    def working_tax_credit_award_total_entitlements
      @working_tax_credit_award_total_entitlements ||=
        working_tax_credit_awards&.map { |el| el["totalEntitlement"] }
    end

    # returns hash
    def income_paye_paye
      key = "income/paye/paye"
      @income_paye_paye ||= data&.find { |el| el.key?(key) }&.fetch(key, nil)
    end

    # returns array of objects
    def income
      @income ||= income_paye_paye&.fetch("income", nil)
    end

    # returns array of objects
    def gross_earnings_for_nics
      key = "grossEarningsForNics"
      @gross_earnings_for_nics ||= income
        &.find_all { |el| el.key?(key) }
        &.flat_map { |el| el[key] }
    end

    # returns array of integers
    def gross_earnings_for_nics_in_pay_period_1
      @gross_earnings_for_nics_in_pay_period_1 ||= gross_earnings_for_nics
        &.find_all {|el| el.key?("inPayPeriod1") }
        &.flat_map { |el| el["inPayPeriod1"] }
    end
  end
end
