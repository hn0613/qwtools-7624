require "active_support/core_ext/module/delegation"
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
        @terms.join("")
      end

      def to_s
        original
      end

      private

      FILTER_VALUE_REGEX = /\A"([^"]*)"(.*)\z/

      def parse_query(query)
        filters = []
        terms = []
        remainder = query.to_s

        until remainder.empty?
          # Skip whitespace and record it as a term separator
          if (ws_match = remainder.match(/\A(\s+)/))
            terms << ws_match[1]
            remainder = ws_match.post_match
            next
          end

          # Try to match "filter_name:" at the current position
          filter_name = try_extract_filter_name(remainder)

          if filter_name
            after_colon = remainder[(filter_name.length + 1)..]

            # Quoted value: kind:"some value with spaces"
            if (quoted_match = after_colon.match(FILTER_VALUE_REGEX))
              value = quoted_match[1]
              filters << "#{filter_name}:#{value}"
              remainder = quoted_match[2]
            else
              # Unquoted value: extends to the next whitespace.
              # Use index-based slicing to preserve all original spacing.
              ws_pos = after_colon.index(/\s/)
              if ws_pos
                value = after_colon[0...ws_pos]
                filters << "#{filter_name}:#{value}"
                remainder = after_colon[ws_pos..]
              else
                filters << "#{filter_name}:#{after_colon}"
                remainder = ""
              end
            end
          else
            # Not a filter — consume one whitespace-delimited token as a term.
            # Use index-based slicing to preserve all original spacing.
            ws_pos = remainder.index(/\s/)
            if ws_pos
              terms << remainder[0...ws_pos]
              remainder = remainder[ws_pos..]
            else
              terms << remainder
              remainder = ""
            end
          end
        end

        [filters, compact_terms(terms)]
      end

      def try_extract_filter_name(text)
        return nil if @valid_filters.nil? || @valid_filters.empty?

        colon_pos = text.index(":")
        return nil unless colon_pos && colon_pos > 0

        candidate = text[0...colon_pos]
        # Filter names must be plain word-char identifiers — this avoids
        # mis-matching tokens like "https:" inside URLs.
        return nil unless candidate.match?(/\A\w+\z/)

        @valid_filters.any? { |f| f == candidate } ? candidate : nil
      end

      # Strip leading and trailing whitespace entries so the reconstructed
      # terms string preserves the original interior spacing exactly.
      def compact_terms(terms)
        return terms if terms.empty?

        start_idx = 0
        start_idx += 1 while start_idx < terms.length && terms[start_idx].match?(/\A\s+\z/)

        end_idx = terms.length - 1
        end_idx -= 1 while end_idx >= start_idx && terms[end_idx].match?(/\A\s+\z/)

        terms[start_idx..end_idx]
      end
    end

    def initialize(scoped_resource, dashboard, term)
      @dashboard = dashboard
      @scoped_resource = scoped_resource
      @query = Query.new(term, valid_filters.keys)
    end

    def run
      if query.blank?
        @scoped_resource.all
      else
        results = search_results(@scoped_resource)
        filter_results(results)
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

    def apply_filter(filter, filter_param, resources)
      return resources unless filter
      if filter.parameters.size == 1
        filter.call(resources)
      else
        filter.call(resources, filter_param)
      end
    end

    def filter_results(resources)
      query.filters.each do |filter_query|
        filter_name, filter_param = filter_query.split(":", 2)
        filter = valid_filters[filter_name]
        resources = apply_filter(filter, filter_param, resources)
      end
      resources
    end

    def query_template
      search_attributes.map do |attr|
        table_name = query_table_name(attr)
        searchable_fields(attr).map do |field|
          column_name = column_to_query(field)
          "LOWER(CAST(#{table_name}.#{column_name} AS CHAR(256))) LIKE ?"
        end.join(" OR ")
      end.join(" OR ")
    end

    def searchable_fields(attr)
      return [attr] unless association_search?(attr)

      attribute_types[attr].searchable_fields
    end

    def query_values
      fields_count = search_attributes.sum do |attr|
        searchable_fields(attr).count
      end
      ["%#{term.downcase}%"] * fields_count
    end

    def search_attributes
      @dashboard.search_attributes
    end

    def search_results(resources)
      resources
        .left_joins(tables_to_join)
        .where(query_template, *query_values)
    end

    def attribute_types
      @dashboard.class.const_get(:ATTRIBUTE_TYPES)
    end

    def query_table_name(attr)
      if association_search?(attr)
        provided_class_name = attribute_types[attr].options[:class_name]
        unquoted_table_name =
          if provided_class_name
            provided_class_name.constantize.table_name
          else
            @scoped_resource.reflect_on_association(attr).klass.table_name
          end
        ActiveRecord::Base.connection.quote_table_name(unquoted_table_name)
      else
        ActiveRecord::Base.connection
          .quote_table_name(@scoped_resource.table_name)
      end
    end

    def column_to_query(attr)
      ActiveRecord::Base.connection.quote_column_name(attr)
    end

    def tables_to_join
      attribute_types.keys.select do |attribute|
        attribute_types[attribute].searchable? && association_search?(attribute)
      end
    end

    def association_search?(attribute)
      attribute_types[attribute].associative?
    end

    def term
      query.terms
    end

    attr_reader :resolver, :query
  end
end
