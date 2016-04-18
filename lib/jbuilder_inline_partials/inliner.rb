require 'jbuilder_inline_partials/processors'

module JbuilderInlinePartials
  class Inliner
    def initialize(&resolver)
      @resolver = resolver
    end

    def inline(source)
      inlined = inline_template(source)
      Unparser.unparse(inlined)
    end

    def inline_template(source)
      raw_ast = Parser::CurrentRuby.parse(source)
      ast = LvarLikeRewriter.new.process(raw_ast)
      partials = find_partials(ast)
      fill_partial_contents(partials)
      replace(ast, partials)
    end

    def find_partials(ast)
      finder = PartialFinder.new
      finder.process(ast)
      finder.partials
    end

    def fill_partial_contents(all_partials)
      partials_by_name = all_partials.group_by(&:name)
      partials_by_name.each do |name, partials|
        source = @resolver.call(name)
        ast = inline_template(source)

        partials.each do |partial|
          rewriter = LocalRewriter.new(partial.locals)
          partial.content = rewriter.process(ast)
        end
      end
    end

    def replace(ast, partials)
      partial_by_node = partials.group_by(&:node).map { |k, v| [k, v.first] }.to_h
      rewriter = PartialRewriter.new(partial_by_node)
      rewriter.process(ast)
    end
  end
end
