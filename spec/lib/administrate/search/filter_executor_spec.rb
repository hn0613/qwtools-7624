require "spec_helper"
require "administrate/search/filter_executor"

describe Administrate::Search::FilterExecutor do
  describe "#apply" do
    it "returns resources unchanged when filters are empty" do
      resources = double("resources")
      executor = described_class.new({})

      result = executor.apply(resources, [])

      expect(result).to eq(resources)
    end

    it "applies a filter without parameters" do
      filtered = double("filtered")
      resources = double("resources")
      filter_lambda = ->(res) { filtered }
      executor = described_class.new({"vip" => filter_lambda})

      result = executor.apply(resources, ["vip:"])

      expect(result).to eq(filtered)
    end

    it "applies a filter with a parameter" do
      filtered = double("filtered")
      resources = double("resources")
      filter_lambda = ->(res, param) { filtered }
      executor = described_class.new({"kind" => filter_lambda})

      result = executor.apply(resources, ["kind:standard"])

      expect(result).to eq(filtered)
    end

    it "passes the parameter value to the filter lambda" do
      resources = double("resources")
      filter_lambda = ->(res, param) { [res, param] }
      executor = described_class.new({"kind" => filter_lambda})

      result = executor.apply(resources, ["kind:standard"])

      expect(result).to eq([resources, "standard"])
    end

    it "chains multiple filters in order" do
      resources = double("resources")
      step1 = double("step1")
      step2 = double("step2")
      vip_filter = ->(res) { step1 }
      kind_filter = ->(res, param) { step2 }
      executor = described_class.new({
        "vip" => vip_filter,
        "kind" => kind_filter
      })

      result = executor.apply(resources, ["vip:", "kind:standard"])

      expect(result).to eq(step2)
    end

    it "skips unknown filter names" do
      resources = double("resources")
      executor = described_class.new({"vip" => ->(res) { :never_called }})

      result = executor.apply(resources, ["unknown:"])

      expect(result).to eq(resources)
    end
  end
end
