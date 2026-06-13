require "administrate/search/query"
require "administrate/search/query_builder"
require "administrate/search/filter_resolver"

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
        results = query_builder.apply(@scoped_resource, query.terms)
        filter_resolver.apply(results, query.filters)
      end
    end

    def valid_filters
      filter_resolver.valid_filters
    end

    private

    def query_builder
      @query_builder ||= QueryBuilder.new(@dashboard, @scoped_resource)
    end

    def filter_resolver
      @filter_resolver ||= FilterResolver.new(@dashboard)
    end

    attr_reader :query
  end
end
