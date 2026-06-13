require "rails_helper"
require "spec_helper"
require "support/search_spec_mocks"
require "administrate/search/query_builder"

describe Administrate::Search::QueryBuilder do
  include_context "search spec mocks"

  describe "#search" do
    context "with plain field attributes" do
      let(:dashboard) { Administrate::SearchSpecMocks::UserDashboard.new }

      it "builds LOWER + LIKE clause for all searchable fields" do
        class User < ApplicationRecord; end
        scoped_object = User.default_scoped
        builder = described_class.new(dashboard, scoped_object)

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

        builder.search(scoped_object, "test")
      ensure
        Object.send(:remove_const, :User)
      end

      it "converts search term LOWER case for latin and cyrillic strings" do
        class User < ApplicationRecord; end
        scoped_object = User.default_scoped
        builder = described_class.new(dashboard, scoped_object)

        expected_query = [
          [
            'LOWER(CAST("users"."id" AS CHAR(256))) LIKE ?',
            'LOWER(CAST("users"."name" AS CHAR(256))) LIKE ?',
            'LOWER(CAST("users"."email" AS CHAR(256))) LIKE ?'
          ].join(" OR "),
          "%тест test%",
          "%тест test%",
          "%тест test%"
        ]
        expect(scoped_object).to receive(:where).with(*expected_query)

        builder.search(scoped_object, "Тест Test")
      ensure
        Object.send(:remove_const, :User)
      end
    end

    context "with association attributes" do
      let(:scoped_object) { Administrate::SearchSpecMocks::Foo }
      let(:dashboard) { Administrate::SearchSpecMocks::FooDashboard.new }

      let(:builder) { described_class.new(dashboard, scoped_object) }

      let(:expected_query) do
        [
          'LOWER(CAST("roles"."name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("people"."first_name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("people"."last_name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("addresses"."street" AS CHAR(256))) LIKE ?',
          "%тест test%",
          "%тест test%",
          "%тест test%",
          "%тест test%"
        ]
      end

      it "joins with the correct association tables" do
        allow(scoped_object).to receive(:where)
        allow(scoped_object).to receive(:left_joins).and_return(scoped_object)

        builder.search(scoped_object, "Тест Test")

        expect(scoped_object).to(
          have_received(:left_joins).with(%i[role author address])
        )
      end

      it "builds WHERE clause using the joined association tables" do
        allow(scoped_object).to receive(:where)
        allow(scoped_object).to receive(:left_joins).and_return(scoped_object)

        builder.search(scoped_object, "Тест Test")

        expect(scoped_object).to(
          have_received(:where).with(*expected_query)
        )
      end
    end
  end
end
