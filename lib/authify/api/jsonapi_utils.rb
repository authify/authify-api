module Authify
  module API
    module JSONAPIUtils
      def jsonapi_serializer_class_name
        this_class = self.class.name.split('::').last
        new_class = "Authify::API::Serializers::#{this_class}Serializer"
        new_class.split('::').inject(Object) {|o,c| o.const_get c}
      end
    end
  end
end
