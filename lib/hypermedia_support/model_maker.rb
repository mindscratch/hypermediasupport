module HypermediaSupport

  module ModelMaker

    def do_make(type, params, format)
      result = nil
      status = :created
      location = nil

      begin
         result = type.new params
         if result.invalid?
           result = Error.new("invalid #{type.name.downcase} parameters: #{result.errors.full_messages}")
           status = :bad_request
         else
           result.save!
           location = controller.url_for(result)
         end
      rescue Exception => ex
        result = Error.new "Problem creating #{type.name.downcase}: #{ex.message}"
        status = :internal_server_error
      end
      resp = {format => result, :status => status}
      resp[:location] = location unless location.nil?
      resp
    end

  end

end