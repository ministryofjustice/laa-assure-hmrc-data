module WorkerErrors
   class TryAgain < StandardError
    def initialize(message = "still processing...")
      super
    end
  end
end

