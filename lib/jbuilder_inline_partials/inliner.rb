require 'jbuilder_inline_partials/processors'

module JbuilderInlinePartials
  class Inliner
    # resolver - The block that takes a String of partial name and returns its
    #            content as String.
    def initialize(&resolver)
      @resolver = resolver
    end

    # source - The String source of a template or partial.
    #
    # Returns the String of the inlined template.
    def inline(source)
      ast = parse(source)
      inlined = inline_template(ast)
      Unparser.unparse(inlined)
    end

    private

    def inline_template(ast)
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
        ast = parse(source)

        partials.each do |partial|
          # Rewrite locals first not to rewrite locals in nested partials.
          rewriter = LocalRewriter.new(partial.locals)
          rewritten = rewriter.process(ast)
          partial.content = inline_template(rewritten)
        end
      end
    end

    def replace(ast, partials)
      partial_by_node = partials.group_by(&:node).map { |k, v| [k, v.first] }.to_h
      rewriter = PartialRewriter.new(partial_by_node)
      rewriter.process(ast)
    end

    def parse(source)
      raw_ast = Parser::CurrentRuby.parse(source)
      LvarLikeRewriter.new.process(raw_ast)
    end
  end
end
