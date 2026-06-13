require "active_support/core_ext/object/blank"

module Administrate
  class Search
    class Query
      attr_reader :filters, :valid_filters

      def blank?
        terms.blank? && filters.empty?
      end

      def initialize(original_query, valid_filters = nil)
        @original_query = original_query
        @valid_filters = valid_filters
        @filters, @terms = parse_query(original_query)
      end

      def original
        @original_query
      end

      def terms
        @terms.join(" ")
      end

      def to_s
        original
      end

      private

      def filter?(word)
        valid_filters&.any? { |filter| word.match?(/^#{filter}:/) }
      end

      def parse_query(query)
        filters = []
        terms = []
        query.to_s.split.each do |word|
          if filter?(word)
            filters << word
          else
            terms << word
          end
        end
        [filters, terms]
      end
    end
  end
end
