module Administrate
  class Search
    class QueryBuilder
      def initialize(dashboard, scoped_resource)
        @dashboard = dashboard
        @scoped_resource = scoped_resource
      end

      def search(resources, term)
        resources
          .left_joins(tables_to_join)
          .where(query_template, *query_values(term))
      end

      private

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

      def query_values(term)
        fields_count = search_attributes.sum do |attr|
          searchable_fields(attr).count
        end
        ["%#{term.downcase}%"] * fields_count
      end

      def search_attributes
        @dashboard.search_attributes
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

      def attribute_types
        @dashboard.class.const_get(:ATTRIBUTE_TYPES)
      end
    end
  end
end
