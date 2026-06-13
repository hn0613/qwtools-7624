require "spec_helper"
require "administrate/search"

describe Administrate::Search::Query do
  subject { described_class.new(query) }

  context "when query is nil" do
    let(:query) { nil }

    it "treats nil as a blank string" do
      expect(subject.terms).to eq("")
    end
  end

  context "when query is blank" do
    let(:query) { "" }

    it "returns true if blank" do
      expect(subject).to be_blank
    end
  end

  context "when given a query with only terms" do
    let(:query) { "foo bar" }

    it "returns the parsed search terms" do
      expect(subject.terms).to eq("foo bar")
    end
  end

  context "when query includes filters" do
    subject { described_class.new(query, ["vip", "active"]) }
    let(:query) { "vip: active:" }

    it "is not blank" do
      expect(subject).to_not be_blank
    end

    it "parses filter syntax" do
      expect(subject.filters).to eq(["vip:", "active:"])
    end
  end

  context "when query includes both filters and terms" do
    subject { described_class.new(query, ["vip"]) }
    let(:query) { "vip: order:id order:11 order term" }

    it "splits filters and terms and does not confuse filters and terms" do
      expect(subject.filters).to eq(["vip:"])
      expect(subject.terms).to eq("order:id order:11 order term")
    end
  end

  context "when query includes both filters with params and terms" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { "kind:standard example.com" }

    it "splits filters and terms" do
      expect(subject.filters).to eq(["kind:standard"])
      expect(subject.terms).to eq("example.com")
    end
  end

  context "when a filter value is double-quoted with spaces" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { 'kind:"super vip" john' }

    it "keeps the quoted value intact and preserves remaining terms" do
      expect(subject.filters).to eq(["kind:super vip"])
      expect(subject.terms).to eq("john")
    end
  end

  context "when a filter value contains colons (e.g. a URL)" do
    subject { described_class.new(query, ["url"]) }
    let(:query) { "url:https://example.com some term" }

    it "does not split the value on inner colons" do
      expect(subject.filters).to eq(["url:https://example.com"])
      expect(subject.terms).to eq("some term")
    end
  end

  context "when a token looks like a filter but is not a valid one" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { "unknown:value foo" }

    it "treats the entire token as a plain search term" do
      expect(subject.filters).to eq([])
      expect(subject.terms).to eq("unknown:value foo")
    end
  end

  context "when a token contains a colon but is not a filter (e.g. URL)" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { "https://example.com foo" }

    it "does not misinterpret it as a filter" do
      expect(subject.filters).to eq([])
      expect(subject.terms).to eq("https://example.com foo")
    end
  end

  context "when multiple filters and terms are mixed together" do
    subject { described_class.new(query, ["vip", "kind"]) }
    let(:query) { "vip: kind:premium john doe" }

    it "separates all filters from all terms" do
      expect(subject.filters).to eq(["vip:", "kind:premium"])
      expect(subject.terms).to eq("john doe")
    end
  end

  context "when input contains only whitespace" do
    let(:query) { "   " }

    it "treats the query as blank" do
      expect(subject).to be_blank
    end
  end

  context "when no valid_filters are provided" do
    subject { described_class.new(query) }
    let(:query) { "kind:vip foo" }

    it "treats everything as plain terms regardless of colon syntax" do
      expect(subject.filters).to eq([])
      expect(subject.terms).to eq("kind:vip foo")
    end
  end

  context "when a filter has an empty quoted value" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { 'kind:"" rest' }

    it "captures the empty value" do
      expect(subject.filters).to eq(["kind:"])
      expect(subject.terms).to eq("rest")
    end
  end

  context "when filters appear at the end of the query" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { "john kind:standard" }

    it "correctly identifies the trailing filter" do
      expect(subject.filters).to eq(["kind:standard"])
      expect(subject.terms).to eq("john")
    end
  end

  context "when terms use irregular spacing" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { "kind:vip  foo   bar" }

    it "preserves the original spacing in terms" do
      expect(subject.filters).to eq(["kind:vip"])
      expect(subject.terms).to eq("foo   bar")
    end
  end
end
