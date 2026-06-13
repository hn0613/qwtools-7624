require "rails_helper"
require "spec_helper"
require "support/constant_helpers"
require "support/search_spec_mocks"
require "administrate/search"

# standard:disable Lint/ConstantDefinitionInBlock
describe Administrate::Search do
  include_context "search spec mocks"

  describe "#run" do
    it "returns all records when no search term" do
      class User < ApplicationRecord; end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        nil
      )
      expect(scoped_object).to receive(:all)

      search.run
    ensure
      remove_constants :User
    end

    it "returns all records when search is empty" do
      class User < ApplicationRecord; end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        "   "
      )
      expect(scoped_object).to receive(:all)

      search.run
    ensure
      remove_constants :User
    end

    it "searches using LOWER + LIKE for all searchable fields" do
      class User < ApplicationRecord; end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        "test"
      )
      expected_query = [
        [
          'LOWER(CAST("users"."id" AS CHAR(256))) LIKE ?',
          'LOWER(CAST("users"."name" AS CHAR(256))) LIKE ?',
          'LOWER(CAST("users"."email" AS CHAR(256))) LIKE ?'
        ].join(" OR "),
        "%test%",
        "%test%",
        "%test%"
      ]
      expect(scoped_object).to receive(:where).with(*expected_query)

      search.run
    ensure
      remove_constants :User
    end

    context "when searching through associations" do
      let(:scoped_object) { Administrate::SearchSpecMocks::Foo }

      let(:search) do
        Administrate::Search.new(
          scoped_object,
          Administrate::SearchSpecMocks::FooDashboard.new,
          "Тест Test"
        )
      end

      it "joins and queries across association tables" do
        allow(scoped_object).to receive(:where)
        allow(scoped_object).to receive(:left_joins).and_return(scoped_object)

        search.run

        expect(scoped_object).to(
          have_received(:left_joins).with(%i[role author address])
        )
      end
    end

    it "applies a filter from COLLECTION_FILTERS" do
      class User < ApplicationRecord
        scope :vip, -> { where(kind: :vip) }
      end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        "vip:"
      )
      expect(scoped_object).to \
        receive(:where)
        .with(kind: :vip)
        .and_return(scoped_object)
      expect(scoped_object).to receive(:where).and_return(scoped_object)

      search.run
    ensure
      remove_constants :User
    end

    it "applies text search and filter together" do
      class User < ApplicationRecord
        scope :vip, -> { where(kind: :vip) }
      end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        "test vip:"
      )
      expect(scoped_object).to \
        receive(:where)
        .with(kind: :vip)
        .and_return(scoped_object)
      expect(scoped_object).to receive(:where).and_return(scoped_object)

      search.run
    ensure
      remove_constants :User
    end
  end

  describe "#valid_filters" do
    it "returns COLLECTION_FILTERS from the dashboard" do
      class User < ApplicationRecord; end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::UserDashboard.new,
        nil
      )

      expect(search.valid_filters).to include("vip", "kind")
    ensure
      remove_constants :User
    end

    it "returns an empty hash when dashboard has no COLLECTION_FILTERS" do
      class User < ApplicationRecord; end
      scoped_object = User.default_scoped
      search = Administrate::Search.new(
        scoped_object,
        Administrate::SearchSpecMocks::FooDashboard.new,
        nil
      )

      expect(search.valid_filters).to eq({})
    ensure
      remove_constants :User
    end
  end
end
# standard:enable Lint/ConstantDefinitionInBlock
