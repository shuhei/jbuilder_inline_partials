require 'spec_helper'

describe JbuilderInlinePartials::LvarLikeRewriter do
  include AST::Sexp

  describe '#process' do
    it 'converts accessor to lvar' do
      source = Parser::CurrentRuby.parse(<<-SOURCE)
json.foo @foo
      SOURCE

      processed = described_class.new.process(source)

      expect(processed).to eq(s(:send, s(:lvar, :json), :foo, s(:ivar, :@foo)))
    end
  end
end

describe JbuilderInlinePartials::PartialFinder do
  include AST::Sexp

  describe '#process' do
    it 'picks up partial! calls' do
      lvar_rewriter = JbuilderInlinePartials::LvarLikeRewriter.new
      source = lvar_rewriter.process(Parser::CurrentRuby.parse(<<-SOURCE))
json.partial! 'foo', foo: @foo
json.bar do
  json.partial! "bar", bar: @foo.bar
end
json.bazs @foo.bazs do |baz|
  json.partial! 'baz', baz: baz
end
      SOURCE

      finder = described_class.new
      finder.process(source)
      partials = finder.partials

      expect(partials.size).to eq(3)
      expect(partials.first).to have_attributes(
        name: 'foo',
        locals: {
          foo: s(:ivar, :@foo)
        },
        node: source.children.first
      )
      expect(partials.second).to have_attributes(
        name: 'bar',
        locals: {
          bar: s(:send, s(:ivar, :@foo), :bar)
        },
        node: source.children.second.children.last
      )
      expect(partials.third).to have_attributes(
        name: 'baz',
        locals: {
          baz: s(:lvar, :baz)
        },
        node: source.children.third.children.last
      )
    end
  end
end

describe JbuilderInlinePartials::PartialRewriter do
  describe '#process' do
  end
end

describe JbuilderInlinePartials::LocalRewriter do
  describe '#process' do
  end
end
