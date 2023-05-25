require 'csv'

class BulkSubmissionCsvParser
  attr_reader :content, :record_struct

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

  def self.call(*args)
    new(*args).call
  end

  def initialize(content, record_struct = SubmissionRecord)
    @content = content
    @record_struct = record_struct
  end

  def call
    raise InvalidHeader unless headers_valid?
    raise NoDataFound unless data?

    submission_records
  end

private

  def submission_records
    csv_table.map do |row|
      record_struct.new(**row)
    end
  end

  def headers_valid?
    (record_struct.members & csv_table.headers.map(&:to_sym)) == record_struct.members
  end

  def data?
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
