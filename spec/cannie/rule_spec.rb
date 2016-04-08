require 'spec_helper'

RSpec.describe Cannie::Rule do
  let(:rule) { described_class.new :index, 'entries' }

  describe '#initialize' do
    it 'stores passed action' do
      expect(rule.action).to eq(:index)
    end

    it 'stores passed subject' do
      expect(rule.subject).to eq('entries')
    end
  end

  describe '#applies_to?' do
    let(:permissions) do
      Class.new do
        def initialize(is_admin=false, is_guest=false)
          @is_admin, @is_guest = is_admin, is_guest
        end

        def admin?
          !!@is_admin
        end

        def guest?
          !!@is_guest
        end
      end
    end

    it 'returns true if no conditions passed in initialize' do
      expect(rule.applies_to?(Array)).to eq(true)
    end

    it 'returns true if passed if-condition evaluated in scope of passed argument return true' do
      rule = described_class.new(:index, 'entries', if: -> { admin? })
      expect(rule.applies_to?(permissions.new(true))).to eq(true)
    end

    it 'returns false if passed if-condition evaluated in scope of passed argument return false' do
      rule = described_class.new(:index, 'entries', if: -> { admin? })
      expect(rule.applies_to?(permissions.new)).to eq(false)
    end

    it 'evaluates if-condition specified as symbol' do
      rule = described_class.new(:index, 'entries', if: :admin?)
      expect(rule.applies_to?(permissions.new(true))).to eq(true)
    end

    it 'evaluates if-condition specified as proc' do
      rule = described_class.new(:index, 'entries', if: proc { admin? })
      expect(rule.applies_to?(permissions.new(true))).to eq(true)
    end

    it 'returns true if passed unless-condition evaluated in scope of passed argument return false' do
      rule = described_class.new(:index, 'entries', unless: -> { admin? })
      expect(rule.applies_to?(permissions.new)).to eq(true)
    end

    it 'returns false if passed unless-condition evaluated in scope of passed argument return true' do
      rule = described_class.new(:index, 'entries', unless: -> { admin? })
      expect(rule.applies_to?(permissions.new(true))).to eq(false)
    end

    it 'evaluates unless-condition specified as symbol' do
      rule = described_class.new(:index, 'entries', unless: :admin?)
      expect(rule.applies_to?(permissions.new(false))).to eq(true)
    end

    it 'evaluates unless-condition specified as proc' do
      rule = described_class.new(:index, 'entries', unless: proc { admin? })
      expect(rule.applies_to?(permissions.new(false))).to eq(true)
    end

    it 'returns true if all conditions returned true' do
      rule = described_class.new(:index, 'entries', if: -> { admin? }, unless: -> { guest? })
      expect(rule.applies_to?(permissions.new(true))).to eq(true)
    end
  end
end
