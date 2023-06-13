module ArrayExtension
  def fetch_first(key, default = nil)
    find { |el| el.key?(key) }&.fetch(key, default)
  end
end

