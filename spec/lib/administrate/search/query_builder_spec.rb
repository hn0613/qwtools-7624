require "rails_helper"
require "spec_helper"
require "support/constant_helpers"
require "administrate/field/belongs_to"
require "administrate/field/string"
require "administrate/field/email"
require "administrate/field/has_many"
require "administrate/field/has_one"
require "administrate/field/number"
require "administrate/base_dashboard"
require "administrate/search"

# standard:disable Lint/ConstantDefinitionInBlock
describe Administrate::Search::QueryBuilder do
  before :all do
    module Administrate
      module QueryBuilderSpecMocks
        class MockRecord < ApplicationRecord
          def self.table_name
            name.demodulize.underscore.pluralize
          end
        end

        class Role < MockRecord; end

        class Person < MockRecord; end

        class Address < MockRecord; end

        class Foo < MockRecord
          belongs_to :role
          belongs_to(
            :author,
            class_name: "Administrate::QueryBuilderSpecMocks::Person"
          )
          has_one :address
        end

        class UserDashboard < Administrate::BaseDashboard
          ATTRIBUTE_TYPES = {
            id: Administrate::Field::Number.with_options(searchable: true),
            name: Administrate::Field::String,
            email: Administrate::Field::Email,
            phone: Administrate::Field::Number
          }.freeze
        end

        class FooDashboard < Administrate::BaseDashboard
          ATTRIBUTE_TYPES = {
            role: Administrate::Field::BelongsTo.with_options(
              searchable: true,
              searchable_fields: ["name"]
            ),
            author: Administrate::Field::BelongsTo.with_options(
              searchable: true,
              searchable_fields: ["first_name", "last_name"],
              class_name: "Administrate::QueryBuilderSpecMocks::Person"
            ),
            address: Administrate::Field::HasOne.with_options(
              searchable: true,
              searchable_fields: ["street"]
            )
          }.freeze
        end
      end
    end
  end

  after :all do
    Administrate.send(:remove_const, :QueryBuilderSpecMocks)
  end

  describe "#apply" do
    context "with plain fields only" do
      it "builds LOWER+LIKE clauses for all searchable fields" do
        class User < ApplicationRecord; end
        scoped_object = User.default_scoped
        builder = described_class.new(
          Administrate::QueryBuilderSpecMocks::UserDashboard.new,
          scoped_object
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
        expect(scoped_object).to receive(:left_joins).with([]).and_return(scoped_object)
        expect(scoped_object).to receive(:where).with(*expected_query)

        builder.apply(scoped_object, "test")
      ensure
        remove_constants :User
      end

      it "downcases search terms for latin and cyrillic strings" do
        class User < ApplicationRecord; end
        scoped_object = User.default_scoped
        builder = described_class.new(
          Administrate::QueryBuilderSpecMocks::UserDashboard.new,
          scoped_object
        )

        expect(scoped_object).to receive(:left_joins).and_return(scoped_object)
        expect(scoped_object).to receive(:where).with(
          anything, "%тест test%", "%тест test%", "%тест test%"
        )

        builder.apply(scoped_object, "Тест Test")
      ensure
        remove_constants :User
      end
    end

    context "with association fields" do
      let(:scoped_object) { Administrate::QueryBuilderSpecMocks::Foo }

      let(:builder) do
        described_class.new(
          Administrate::QueryBuilderSpecMocks::FooDashboard.new,
          scoped_object
        )
      end

      it "joins the correct association tables" do
        allow(scoped_object).to receive(:where)
        allow(scoped_object).to receive(:left_joins).and_return(scoped_object)

        builder.apply(scoped_object, "test")

        expect(scoped_object).to(
          have_received(:left_joins).with(%i[role author address])
        )
      end

      it "builds WHERE clauses using joined table names" do
        allow(scoped_object).to receive(:where)
        allow(scoped_object).to receive(:left_joins).and_return(scoped_object)

        expected_template =
          'LOWER(CAST("roles"."name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("people"."first_name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("people"."last_name" AS CHAR(256))) LIKE ?' \
          ' OR LOWER(CAST("addresses"."street" AS CHAR(256))) LIKE ?'

        builder.apply(scoped_object, "test")

        expect(scoped_object).to(
          have_received(:where).with(
            expected_template, "%test%", "%test%", "%test%", "%test%"
          )
        )
      end
    end
  end
end
# standard:enable Lint/ConstantDefinitionInBlock
