RSpec.shared_examples "discardable model" do
  it "is discardable" do
    expect(instance).to respond_to(:discarded_at, :discard, :discard!, :discarded?,
                                   :undiscard, :undiscard!, :undiscarded?, :kept?)

    expect(instance.class).to respond_to(:discarded, :undiscarded, :kept, :with_discarded)
  end
end
