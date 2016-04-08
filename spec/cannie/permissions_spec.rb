require 'spec_helper'

RSpec.describe Cannie::Permissions do
  subject do
    Class.new do
      include Cannie::Permissions
    end
  end

  let(:permissions) do
    subject.class_exec do
      controller :entries do
        allow :index
        allow :show
      end

      allow :new, on: :all
    end

    subject.new('user')
  end

  let(:klass) do
    Class.new(ActionController::Base) do
      def index; end
      def self.controller_path
        'entries'
      end
    end
  end

  describe '.namespace' do
    it 'executes block with changed scope' do
      expect(subject.namespace('test_namespace') { subject('entries') }).to eq('test_namespace/entries')
    end

    it 'allows nesting of namespaces' do
      expect(
        subject.namespace('test_namespace') do
          namespace 'namespace_2' do
            subject('entries')
          end
        end
      ).to eq('test_namespace/namespace_2/entries')
    end
  end

  describe '.controller' do
    it 'executes block with changed controller' do
      subject.controller('entries') { allow :index }
      expect(subject.rules.map(&:subject)).to eq(['entries'])
    end

    it 'allows nesting into namespaces' do
      subject.namespace(:namespace) do
        controller(:entries) { allow :index }
      end
      expect(subject.rules.map(&:subject)).to eq(['namespace/entries'])
    end
  end

  describe '.allow' do
    it 'creates Rule object for specified controller and action' do
      subject.allow :index, on: :entries
      rule = subject.rules.last
      rule_data = [rule.class, rule.action, rule.subject]
      expect(rule_data).to eq([Cannie::Rule, :index, 'entries'])
    end

    it 'creates Rule object for each of specified actions and controllers' do
      subject.allow [:index, :show], on: [:entries, :comments]
      expected = [
        [:index, 'entries'],
        [:index, 'comments'],
        [:show, 'entries'],
        [:show, 'comments']
      ]
      expect(subject.rules.map { |rule| [rule.action, rule.subject] }).to eq(expected)
    end

    it 'allows nesting into controllers' do
      subject.class_exec do
        allow :index, on: :entries

        controller :entries do
          allow :show
        end

        allow :show, on: :comments
      end

      expected = [
        [:index, 'entries'],
        [:show, 'entries'],
        [:show, 'comments']
      ]
      expect(subject.rules.map { |rule| [rule.action, rule.subject] }).to eq(expected)
    end
  end

  describe '#can?' do
    describe 'when passed as class' do
      it 'returns true if it has at least one rule for corresponding action & subject' do
        expect(permissions.can?(:index, klass)).to eq(true)
      end

      it 'returns true for any subject if rule subject set to :all' do
        expect(permissions.can?(:new, klass)).to eq(true)
      end

      it 'returns false if no rules found for corresponding action & subject' do
        expect(permissions.can?(:edit, klass)).to eq(false)
      end
    end

    describe 'when passed as string' do
      it 'returns true if it has at least one rule for corresponding action & subject' do
        expect(permissions.can?(:index, klass.controller_path)).to eq(true)
      end

      it 'returns true for any subject if rule subject set to :all' do
        expect(permissions.can?(:new, klass.controller_path)).to eq(true)
      end

      it 'returns false if no rules found for corresponding action & subject' do
        expect(permissions.can?(:edit, klass.controller_path)).to eq(false)
      end
    end
  end

  describe '#permit!' do
    it 'raises ActionForbidden error if can? returns false' do
      expect { permissions.permit!(:edit, klass) }.to raise_error(Cannie::ActionForbidden)
    end

    it 'does not raise ActionForbidden error if can? returns true' do
      expect { permissions.permit!(:index, klass) }.not_to raise_error
    end
  end
end
