require 'parser/current'
require 'unparser'

module JbuilderInlinePartials
  class Partial
    attr_accessor :name, :locals, :node, :content

    def initialize(name: nil, locals: nil, node: nil, content: nil)
      @name = name
      @locals = locals
      @node = node
      @content = content
    end
  end

  class PartialProcessor < Parser::AST::Processor
    private

    def json_partial?(node)
      children = node.children
      children && json?(children.first) && children.second == :partial! && children.third && children.third.type == :str
    end

    def json?(node)
      node && node.type == :lvar && node.children.first == :json
    end

    def partial_name(node)
      node.children.third.children.first
    end

    def partial_locals(node)
      hash = node.children[3]
      (hash && hash.children || []).map do |pair|
        key = pair.children.first.children.first
        value = pair.children.second
        [key, value]
      end.to_h
    end

    def lvar_like?(node)
      node && node.type == :send && node.children.size == 2 && node.children.first.nil?
    end
  end

  class LvarLikeRewriter < PartialProcessor
    def on_send(node)
      if lvar_like?(node)
        # (send nil :foo) -> (lvar :foo)
        node.updated(:lvar, [node.children.second])
      else
        super
      end
    end
  end

  class PartialFinder < PartialProcessor
    attr_reader :partials

    def initialize
      super
      @partials = []
    end

    def on_send(node)
      if json_partial?(node)
        name = partial_name(node)
        locals = partial_locals(node)
        @partials << Partial.new(name: name, locals: locals, node: node)
      end
      super
    end
  end

  class PartialRewriter < PartialProcessor
    def initialize(partial_by_node)
      super()
      @partial_by_node = partial_by_node
    end

    def on_send(node)
      if json_partial?(node)
        content = @partial_by_node[node].content
        node.updated(content.type, content.children)
      else
        super
      end
    end
  end

  class LocalRewriter < PartialProcessor
    def initialize(locals)
      super()
      @locals = locals
    end

    def on_lvar(node)
      local = @locals[node.children.first]
      if local
        node.updated(local.type, local.children)
      else
        super
      end
    end
  end
end
