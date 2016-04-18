module JbuilderInlinePartials
  class Handler
    def self.call(template)
      source = make_inliner.inline(template.source)
      # puts '**************'
      # puts source
      # puts '**************'
      # this juggling is required to keep line numbers right in the error
      %{__already_defined = defined?(json); json||=JbuilderTemplate.new(self); #{source}
        json.target! unless (__already_defined && __already_defined != "method")}
    end

    def self.make_inliner
      Inliner.new do |name|
        components = name.split('/')
        components[-1] = "_#{components[-1]}"
        partial_name = "#{components.join('/')}.json.jbuilder"
        path = Rails.root.join('app', 'views', partial_name)

        File.read(path)
      end
    end
  end
end
