require "spec_helper"
require "administrate/search"

# standard:disable Lint/ConstantDefinitionInBlock
describe Administrate::Search::FilterResolver do
  before :all do
    module Administrate
      module FilterResolverSpecMocks
        class DashboardWithFilters
          COLLECTION_FILTERS = {
            vip: ->(resource) { resource.where(kind: :vip) },
            kind: ->(resource, param) { resource.where(kind: param) }
          }.freeze
        end

        class DashboardWithoutFilters
        end
      end
    end
  end

  after :all do
    Administrate.send(:remove_const, :FilterResolverSpecMocks)
  end

  describe "#valid_filters" do
    let(:resolver) do
      described_class.new(Administrate::FilterResolverSpecMocks::DashboardWithFilters.new)
    end

    it "returns stringified filter hash from dashboard" do
      expect(resolver.valid_filters.keys).to match_array(%w[vip kind])
    end

    it "returns the lambda values" do
      expect(resolver.valid_filters["vip"]).to be_a(Proc)
      expect(resolver.valid_filters["kind"]).to be_a(Proc)
    end

    context "when dashboard has no COLLECTION_FILTERS" do
      let(:resolver) do
        described_class.new(Administrate::FilterResolverSpecMocks::DashboardWithoutFilters.new)
      end

      it "returns an empty hash" do
        expect(resolver.valid_filters).to eq({})
      end
    end
  end

  describe "#apply" do
    let(:resolver) do
      described_class.new(Administrate::FilterResolverSpecMocks::DashboardWithFilters.new)
    end
    let(:relation) { double("relation") }

    it "applies a 1-argument filter lambda" do
      filtered = double("filtered")
      expect(relation).to receive(:where).with(kind: :vip).and_return(filtered)

      result = resolver.apply(relation, ["vip:"])
      expect(result).to eq(filtered)
    end

    it "applies a 2-argument filter lambda with the parameter" do
      filtered = double("filtered")
      expect(relation).to receive(:where).with(kind: "premium").and_return(filtered)

      result = resolver.apply(relation, ["kind:premium"])
      expect(result).to eq(filtered)
    end

    it "chains multiple filters sequentially" do
      intermediate = double("intermediate")
      final = double("final")

      expect(relation).to receive(:where).with(kind: :vip).and_return(intermediate)
      expect(intermediate).to receive(:where).with(kind: "premium").and_return(final)

      result = resolver.apply(relation, ["vip:", "kind:premium"])
      expect(result).to eq(final)
    end

    it "skips unknown filter names gracefully" do
      result = resolver.apply(relation, ["unknown:something"])
      expect(result).to eq(relation)
    end

    it "returns the relation unchanged when filters array is empty" do
      result = resolver.apply(relation, [])
      expect(result).to eq(relation)
    end
  end
end
# standard:enable Lint/ConstantDefinitionInBlock
