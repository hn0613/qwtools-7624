module Administrate
  class Search
    class FilterExecutor
      def initialize(valid_filters)
        @valid_filters = valid_filters
      end

      def apply(resources, filters)
        filters.each do |filter_query|
          filter_name, filter_param = filter_query.split(":")
          filter = @valid_filters[filter_name]
          resources = apply_filter(filter, filter_param, resources)
        end
        resources
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
