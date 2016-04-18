require 'spec_helper'

describe JbuilderInlinePartials::Inliner do
  it 'creates an instance' do
    expect(described_class.new).not_to be_nil
  end

  describe '#inline' do
    it 'does nothing if no partial' do
      source = <<-SOURCE
json.foo @foo
json.bar @foo.bar
      SOURCE

      expect(described_class.new.inline(source)).to eq(<<-RESULT.strip)
json.foo(@foo)
json.bar(@foo.bar)
      RESULT
    end

    it 'replaces json.partial! with its content' do
      inliner = described_class.new do |name|
        if name == 'bar'
          <<-PARTIAL
json.extract! bar, :id, :name
          PARTIAL
        end
      end
      source = <<-SOURCE
json.extract! foo, :id, :name
json.bar do
  json.partial! 'bar', bar: foo.bar
end
      SOURCE

      expect(inliner.inline(source)).to eq(<<-RESULT.strip)
json.extract!(foo, :id, :name)
json.bar do
  json.extract!(foo.bar, :id, :name)
end
      RESULT
    end
  end
end
