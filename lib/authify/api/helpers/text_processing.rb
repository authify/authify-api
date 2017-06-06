module Authify
  module API
    module Helpers
      # Helper methods for working with different text formats
      module TextProcessing
        def valid_formats
          [:base64]
        end

        def decoded_hash(hash)
          hash.update(hash) { |_, v| v.is_a?(String) ? human_readable(v) : v }
        end

        # Interpolates handlebars-style templates
        # OPTIMIZE: this can probably be faster
        def dehandlebar(text, data = {})
          text.gsub(/{{([a-z0-9_-]+)}}/) { data[Regexp.last_match[1].to_sym] }
        end

        def human_readable(text)
          if text =~ /^\{([a-zA-Z0-9]+)\}([^\n]+)$/
            form, data = text.match(/^\{([a-zA-Z0-9]+)\}([^\n]+)$/)[1, 2]

            raise "Invalid Conversion: #{form}" unless valid_formats.include?(form.downcase.to_sym)
            send("from_#{form.downcase}".to_sym, data)
          else
            text
          end
        end

        def from_base64(text)
          Base64.decode64 text
        end
      end
    end
  end
end
