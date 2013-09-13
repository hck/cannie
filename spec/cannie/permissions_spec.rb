require 'spec_helper'

describe Cannie::Permissions do
  subject { Class.new { include Cannie::Permissions } }

  describe '#allow' do
    before do
      subject.class_eval do
        def initialize
          allow :read, :update, on: Array
        end
      end
    end

    let(:rules) { subject.new.send(:rules) }

    it 'creates only one rule for each call of allow method' do
      expect(rules.size).to eq(1)
    end

    it 'creates and stores Rule object with passed actions' do
      expect(rules.first.actions).to eq([:read, :update])
    end

    it 'creates and stores Rule object with passed subject' do
      expect(rules.first.subject).to eq(Array)
    end

    it 'creates and stores Rule object with passed condition block' do
      expect(rules.first.condition).to be_nil
    end
  end

  describe '#can?' do
    before do
      subject.class_eval do
        def initialize
          allow :read, on: Array

          allow(:read, on: Array) do |*args|
            args.all?{|v| v % 2 == 0}
          end
        end
      end
    end

    let(:permissions) { subject.new }

    it 'returns false if no rules for action exists' do
      permissions.stub(:rules).and_return([])
      expect(permissions.can? :read, on: [2, 4, 8]).to be_false
    end

    it 'returns true if all rules for action & subject are permitted' do
      expect(permissions.can? :read, on: [2, 4, 8]).to be_true
    end

    it 'returns false if not all rules for action & subject are permitted' do
      expect(permissions.can? :read, on: [1, 2, 3]).to be_false
    end
  end

  describe '#permit!' do
    before do
      subject.class_eval do
        def initialize
          allow :read, on: Array do |*args|
            args.all?{|v| v % 2 == 0}
          end
        end
      end
    end

    let(:permissions) { subject.new }

    it 'raises AccessDenied error if permission checking failed' do
      expect { permissions.permit! :read, on: [1, 2, 3] }.to raise_error
    end

    it 'does not raise AccessDenied error if permission checking was successfull' do
      expect { permissions.permit! :read, on: [2, 4, 6] }.not_to raise_error
    end
  end

end