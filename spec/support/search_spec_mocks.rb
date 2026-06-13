require "administrate/field/belongs_to"
require "administrate/field/string"
require "administrate/field/email"
require "administrate/field/has_many"
require "administrate/field/has_one"
require "administrate/field/number"
require "administrate/base_dashboard"

# standard:disable Lint/ConstantDefinitionInBlock
RSpec.shared_context "search spec mocks" do
  before :all do
    module Administrate
      module SearchSpecMocks
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
            class_name: "Administrate::SearchSpecMocks::Person"
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

          COLLECTION_FILTERS = {
            vip: ->(resource) { resource.where(kind: :vip) },
            kind: ->(resource, param) { resource.where(kind: param) }
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
              class_name: "Administrate::SearchSpecMocks::Person"
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
    Administrate.send(:remove_const, :SearchSpecMocks)
  end
end
# standard:enable Lint/ConstantDefinitionInBlock
