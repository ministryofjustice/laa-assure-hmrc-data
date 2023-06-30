module StatusSettable
  extend ActiveSupport::Concern

  class_methods do
    def has_status(*statuses)
      statuses.each do |a_status|
        define_method("#{a_status}!") { update!(status: a_status.to_s) }

        define_method("#{a_status}?") { status == a_status.to_s }
      end
    end
  end
end
