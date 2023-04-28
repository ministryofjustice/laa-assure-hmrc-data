class NotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value && value > Date.current
      record.errors.add(attribute, (options[:message] || :in_future))
    end
  end
end
