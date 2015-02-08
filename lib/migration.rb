module ActiveRecord
  class Migration
    class << self
      def uses_db?
        true
      end
    end

    def method_missing(method, *arguments, &block)
      arg_list = arguments.map{ |a| a.inspect } * ', '

      say_with_time "#{method}(#{arg_list})" do
        unless arguments.empty? || method == :execute
          arguments[0] = proper_table_name(arguments.first)
        end
        return super unless connection.respond_to?(method)

        if (respond_to?(:database_model))
          write "Using custom database model's connection (#{database_model}) for this migration"
          eval("#{database_model}.connection.send(method, *arguments, &block)")
        else
          connection.send(method, *arguments, &block)
        end

      end
    end

  end
end
