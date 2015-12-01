require "histograms/version"

module Histograms
  Bin = Struct.new(:value, :count)

  class NumericHistogram
    attr_reader :max_bins
    attr_reader :bins
    attr_accessor :total

    def initialize(max_bins)
      @max_bins = max_bins
      @bins = []
      @total = 0
    end

    def add(new_value)
      self.total += 1
      create_new_bin(new_value)
      trim
    end

    def quantile(q)
      count = q.to_f * total.to_f

      bins.each_with_index do |bin, index|
        count -= bin.count

        if count <= 0
          return bin.value
        end
      end

      return -1
    end

    def mean
      if total == 0
        return 0
      end

      sum = bins.inject(0) { |s, bin| s + (bin.value * bin.count) }
      return sum.to_f / total.to_f
    end

    private

    # If we exactly match an existing bin, add to it, otherwise create a new bin holding a count for the new value.
    def create_new_bin(new_value)
      bins.each_with_index do |bin, index|
        # If it matches exactly, increment the bin's count
        if bin.value == new_value
          bin.count += 1
          return
        end

        # We've gone one bin too far, so insert before the current bin.
        if bin.value > new_value
          # Insert at this index
          new_bin = Bin.new(new_value, 1)
          bins.insert(index, new_bin)
          return
        end
      end

      # If we get to here, the bin needs to be added to the end.
      bins << Bin.new(new_value, 1)
    end

    def trim
      while bins.length > max_bins
        trim_one
      end
    end

    def trim_one
      minDelta = Float::MAX
      minDeltaIndex = 0

      # Which two bins should we merge?
      bins.each_with_index do |_, index|
        next if index == 0

        delta = bins[index].value - bins[index - 1].value
        if delta < minDelta
          minDelta = delta
          minDeltaIndex = index
        end
      end

      # Create the merged bin with summed count, and weighted value
      mergedCount = bins[minDeltaIndex - 1].count + bins[minDeltaIndex].count
      mergedValue = (
        bins[minDeltaIndex - 1].value * bins[minDeltaIndex - 1].count +
        bins[minDeltaIndex].value     * bins[minDeltaIndex].count
        ) / mergedCount

      mergedBin = Bin.new(mergedValue, mergedCount)

      # Remove the two bins we just merged together, then add the merged one
      bins.slice!(minDeltaIndex - 1, 2)
      bins.insert(minDeltaIndex - 1, mergedBin)
    end
  end
end
