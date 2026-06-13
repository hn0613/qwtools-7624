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

  context "when query includes a filter with a quoted multi-word value" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { 'kind:"premium customer" searchterm' }

    it "keeps the quoted value as a single filter" do
      expect(subject.filters).to eq(["kind:premium customer"])
      expect(subject.terms).to eq("searchterm")
    end
  end

  context "when query includes a quoted search term without a filter prefix" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { '"hello world" other' }

    it "treats the quoted phrase as a single search term" do
      expect(subject.filters).to eq([])
      expect(subject.terms).to eq("hello world other")
    end
  end

  context "when query has an unclosed quote" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { 'kind:"unclosed value' }

    it "closes the quote at the end of input" do
      expect(subject.filters).to eq(["kind:unclosed value"])
      expect(subject.terms).to eq("")
    end
  end

  context "when query includes a filter with colons in the value" do
    subject { described_class.new(query, ["time"]) }
    let(:query) { "time:10:30" }

    it "keeps the full value including colons" do
      expect(subject.filters).to eq(["time:10:30"])
      expect(subject.terms).to eq("")
    end
  end

  context "when query mixes quoted and unquoted filters" do
    subject { described_class.new(query, ["kind", "status"]) }
    let(:query) { 'kind:"premium customer" status:active term' }

    it "parses both filters correctly" do
      expect(subject.filters).to eq(["kind:premium customer", "status:active"])
      expect(subject.terms).to eq("term")
    end
  end

  context "when query has a filter with an empty quoted value" do
    subject { described_class.new(query, ["kind"]) }
    let(:query) { 'kind:"" term' }

    it "treats the filter as parameterless" do
      expect(subject.filters).to eq(["kind:"])
      expect(subject.terms).to eq("term")
    end
  end
end
