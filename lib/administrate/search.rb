require "administrate/search/query"
require "administrate/search/query_builder"
require "administrate/search/filter_executor"

module Administrate
  class Search
    def initialize(scoped_resource, dashboard, term)
      @dashboard = dashboard
      @scoped_resource = scoped_resource
      @query = Query.new(term, valid_filters.keys)
    end

    def run
      if query.blank?
        @scoped_resource.all
      else
        results = query_builder.search(@scoped_resource, query.terms)
        filter_executor.apply(results, query.filters)
      end
    end

    def valid_filters
      if @dashboard.class.const_defined?(:COLLECTION_FILTERS)
        @dashboard.class.const_get(:COLLECTION_FILTERS).stringify_keys
      else
        {}
      end
    end

    private

    attr_reader :query

    def query_builder
      @query_builder ||= QueryBuilder.new(@dashboard, @scoped_resource)
    end

    def filter_executor
      @filter_executor ||= FilterExecutor.new(valid_filters)
    end
  end
end
