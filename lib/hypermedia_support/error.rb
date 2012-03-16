module HypermediaSupport
  class Error

    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    def attr_reader :message

    def initialize(message)
      @message = message
    end

    def attributes
      {"message" => message}
    end

    def as_json(*args)
      {error: message}
    end
  end
end