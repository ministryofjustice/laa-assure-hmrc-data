module ArrayExtension
  def fetch_first(key, default = nil)
    find { |el| el.key?(key) }&.fetch(key, default)
  end

  def fetch_all(key)
    find_all { |el| el.key?(key) }
      &.flat_map { |el| el[key] }
  end

  def join_compact_blank(args)
    joined = join(*args)

    return if joined.blank?
    joined
  end
end

