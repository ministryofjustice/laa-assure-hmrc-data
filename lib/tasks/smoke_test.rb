module HmrcInterface
  class SmokeTest
    attr_reader :client, :filter

    def initialize(client, filter = {}, duration = 5.minutes, interval = 5.seconds)
      @client = client
      @filter = filter
      @duration = duration
      @interval = interval
    end

    def call
      submission_request = HmrcInterface::Request::Submission.new(client, :one, filter)
      response = submission_request.call
      submission_id = response[:id]

      result_request = HmrcInterface::Request::Result.new(client, submission_id)
      result = result_request.call

      time_iterate(duration: @duration, interval: @interval) do |time|
        result = result_request.call
        status = result[:status]
        puts "[#{time}]: #{status} #{result.dig(:data, 1)}"

        break if %w[completed failed].include?(status.downcase)
      end
    end

  private

    def time_iterate(duration:, interval:)
      while(Time.current <= duration.from_now)
        yield(Time.current)
        sleep(interval)
      end
    end
  end
end
