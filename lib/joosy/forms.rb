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
          joosy_fail(entity.errors, entity.class.name)
        end
      end

      def joosy_fail(errors, entity=false)
        errors = Hash[*errors.map {|x| [x, nil]}.flatten] if errors.is_a?(Array)
        joosy_respond errors, :unprocessable_entity
      end

      def joosy_succeed(data, entity=nil, &block)
        block.call(entity) if block_given?
        joosy_respond (data.is_a?(Proc) ? data.call(entity) : (data || entity))
      end

      def joosy_respond(data, status=200)
        unless request.xhr?
          @data = { :status => status, :json => data }
          self.class.layout 'json_wrapper'
          render :text => result.to_json, :status => status
        else
          render :json => data, :status => status
        end
      end
    end
  end
end
