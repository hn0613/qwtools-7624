require "active_support/core_ext/hash/keys"

module Administrate
  class Search
    class FilterResolver
      def initialize(dashboard)
        @dashboard = dashboard
      end

      # Returns a hash of filter_name => lambda from the dashboard's
      # COLLECTION_FILTERS constant, with stringified keys.
      # Returns an empty hash if the constant is not defined.
      #
      # @return [Hash{String => Proc}]
      def valid_filters
        if @dashboard.class.const_defined?(:COLLECTION_FILTERS)
          @dashboard.class.const_get(:COLLECTION_FILTERS).stringify_keys
        else
          {}
        end
      end

      # Applies each named filter (from parsed filter strings like "vip:" or
      # "kind:premium") to the given relation, in sequence.
      #
      # @param relation [ActiveRecord::Relation]
      # @param filters [Array<String>] parsed filter tokens
      # @return [ActiveRecord::Relation]
      def apply(relation, filters)
        filters.each do |filter_query|
          filter_name, filter_param = filter_query.split(":")
          filter = valid_filters[filter_name]
          relation = apply_filter(filter, filter_param, relation)
        end
        relation
      end

      private

      def apply_filter(filter, filter_param, resources)
        return resources unless filter
        if filter.parameters.size == 1
          filter.call(resources)
        else
          filter.call(resources, filter_param)
        end
      end
    end
  end
end
