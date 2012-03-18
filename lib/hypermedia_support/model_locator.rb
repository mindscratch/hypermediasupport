module HypermediaSupport
  module ModelLocator
    def do_locate(type, id, format)
      result = nil
      status = :ok
      begin
        result = type.find(id)
      rescue Exception => ex
        # Trying to be generic here to catch
        #   ActiveRecord::RecordNotFound
        #   Mongoid::Errors::DocumentNotFound
        #   ...maybe others. this should be refactored, perhaps into a 'strategy', we'll see.
        if ex.class.name =~ /NotFound/
          result = Error.new "Unable to locate #{type.name.downcase} with id=#{id}"
          status = :not_found
        else
          result = Error.new("Problem trying to locate #{type.name.downcase} with id=#{id}: #{ex.message}")
          status = :internal_server_error
        end
      end
      {format => result, :status => status}
    end
  end
end