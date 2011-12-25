module Joosy
  module Forms
    def self.included base
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def joosy_store(entity, data=nil, &block)
        if entity.save
          joosy_succeed(data, entity, &block)
        else
          joosy_fail(entity.errors.messages, entity.class.name)
        end
      end

      def joosy_fail(errors, entity=false)
        errors = Hash[*errors.map {|x| [x, nil]}.flatten] if errors.is_a?(Array)

        if !entity
          notifications = errors
        else
          notifications = {}
          errors.each do |k, v|
            notifications["#{entity.underscore}[#{k}]"] = v
          end
        end

        joosy_respond notifications, :unprocessable_entity
      end

      def joosy_succeed(data, entity=nil, &block)
        block.call(entity) if block_given?
        joosy_respond (data.is_a?(Proc) ? data.call(entity) : data)
      end

      def joosy_respond(json, status=200)
        result = {}
        result[:json]   = json
        result[:status] = status if status

        if params['joosy-iframe']
          render :text => "<textarea>#{result.to_json}</textarea>"
        else
          render result
        end
      end
    end
  end
end