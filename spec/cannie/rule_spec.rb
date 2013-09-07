require 'spec_helper'

describe Cannie::Rule do
  describe '#initialize' do
    it 'stores passed actions' do
      actions = %i(read create update delete)
      rule = described_class.new *actions, Array
      expect(rule.actions).to eq(actions)
    end

    it 'stores passed subject' do
      rule = described_class.new :read, Array
      expect(rule.subject).to eq(Array)
    end

    it 'scores passed block' do
      rule = described_class.new(:read, Array){ |*attrs| attrs.all?{ |v| v % 2 == 0 } }
      expect(rule.condition.call(2,4,8)).to be_true
    end
  end

  describe '#permits?' do
    let(:rule) do
      described_class.new(:read, Array) do |*attrs|
        attrs.all?{ |v| v % 2 == 0 }
      end
    end

    it 'returns true if result of executing condition is true' do
      expect(rule.permits?(2,4,8)).to be_true
    end

    it 'returns false if result of executing condition is false' do
      expect(rule.permits?(1,4,8)).to be_false
    end

    it 'returns true for any subject if rule subject is :all' do
      rule = described_class.new(:read, :all)
      expect(rule.permits?(1,2,3)).to be_true
    end
  end
end