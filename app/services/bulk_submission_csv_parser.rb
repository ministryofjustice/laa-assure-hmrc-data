require 'csv'

class BulkSubmissionCsvParser
  attr_reader :content, :records

  class ParserError < StandardError
  end

  class InvalidHeader < ParserError
    def initialize(message="invalid or missing headers")
      super(message)
    end
  end

  class NoDataFound < ParserError
    def initialize(message="no data found")
      super(message)
    end
  end

  # TODO: fix "warning: redefining constant Struct::SubmissionRecord" - use dry-struct or a plain class
  SubmissionRecord = Struct.new('SubmissionRecord',
                                :start_date,
                                :end_date,
                                :first_name,
                                :last_name,
                                :date_of_birth,
                                :nino) do
    def period_start_at
      @period_start_at ||= Date.parse(start_date)
    rescue Date::Error => e
      raise Date::Error, "#{e.message} for #{__method__}"
    end

    def period_end_at
      @period_end_at ||= Date.parse(end_date)
    rescue Date::Error => e
      raise Date::Error, "#{e.message} for #{__method__}"
    end

    def dob
      @dob ||= Date.parse(date_of_birth)
    rescue Date::Error => e
      raise Date::Error, "#{e.message} for #{__method__}"
    end
  end

  def self.call(*args)
    new(*args).call
  end

  def initialize(content)
    @content = content
  end

  def call
    raise InvalidHeader unless headers_valid?
    raise NoDataFound unless data_present?

    submission_records
  end

private

  def submission_records
    csv_table.map do |row|
      SubmissionRecord.new(**row)
    end
  end

  def headers_valid?
    (SubmissionRecord.members & csv_table.headers.map(&:to_sym)) == SubmissionRecord.members
  end

  def data_present?
    csv_table.size.positive?
  end

  def csv_table
    @csv_table ||= CSV.parse(
                      content,
                      headers: :first_row,
                      header_converters: lambda { |f| f.strip },
                      converters: lambda { |f| f ? f.strip : nil }
                    )
  end
end
