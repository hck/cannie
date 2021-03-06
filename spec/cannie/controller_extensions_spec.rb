require 'spec_helper'

RSpec.describe Cannie::ControllerExtensions do
  let(:klass) do
    Class.new(ActionController::Base) do
      def action
        render nothing: true
      end

      def index
        @entries = [1, 2, 3, 4, 5]
        render text: @entries.to_s
      end

      def self.controller_path
        'entries'
      end
    end
  end

  subject { klass.new }

  let(:permissions) do
    Class.new do
      include Cannie::Permissions

      allow :index, on: :entries
    end
  end

  describe '.check_permissions' do
    before do
      allow(subject).to receive(:current_permissions).and_return(permissions.new('User'))
    end

    describe 'without conditions' do
      before { klass.check_permissions }

      it 'raises exception if no rules for action & subject exist' do
        block = -> { subject.dispatch(:action, ActionDispatch::TestRequest.new) }
        expect(&block).to raise_error(Cannie::ActionForbidden)
      end

      it 'does not raise exception rules match action & subject' do
        block = -> { subject.dispatch(:index, ActionDispatch::TestRequest.new) }
        expect(&block).not_to raise_error
      end
    end

    describe 'with if condition' do
      before { klass.check_permissions if: :condition? }

      it 'raises exception if :if block executed in controller scope returns true and no rules for action/subject' do
        allow(subject).to receive(:condition?).and_return(true)
        block = -> { subject.dispatch(:action, ActionDispatch::TestRequest.new) }
        expect(&block).to raise_error(Cannie::ActionForbidden)
      end

      it 'does not raise exception if :if block executed in controller scope returns false' do
        allow(subject).to receive(:condition?).and_return(false)
        block = -> { subject.dispatch(:action, ActionDispatch::TestRequest.new) }
        expect(&block).not_to raise_error
      end
    end

    describe 'with unless condition' do
      before { klass.check_permissions unless: :condition? }

      it 'raises exception if :unless block executed in controller scope returns false' do
        allow(subject).to receive(:condition?).and_return(false)
        block = -> { subject.dispatch(:action, ActionDispatch::TestRequest.new) }
        expect(&block).to raise_error(Cannie::ActionForbidden)
      end

      it 'does not raise exception if :unless block executed in controller scope returns false' do
        allow(subject).to receive(:condition?).and_return(true)
        block = -> { subject.dispatch(:action, ActionDispatch::TestRequest.new) }
        expect(&block).not_to raise_error
      end
    end
  end

  describe '.skip_check_permissions' do
    it 'bypasses permissions checking' do
      klass.skip_check_permissions
      subject.run_callbacks(:process_action)
      expect(subject.permitted?).to eq(true)
    end
  end

  describe '#can?' do
    it 'raises SubjectNotSetError if value of :on param is nil' do
      expect { subject.can? :action, on: nil }.to raise_error(Cannie::SubjectNotSetError)
    end

    it 'returns true if action allowed on subject' do
      allow(subject).to receive(:current_permissions).and_return permissions.new('user')
      expect(subject.can?(:index, on: klass)).to eq(true)
    end

    it 'returns false if action not allowed on subject' do
      allow(subject).to receive(:current_permissions).and_return permissions.new('user')
      expect(subject.can?(:action, on: klass)).to eq(false)
    end
  end

  describe '#current_permissions' do
    before(:all) do
      Permissions = Class.new do
        include Cannie::Permissions
      end
    end

    before { allow(subject).to receive(:current_user).and_return 'User' }

    it 'creates new Permissions object' do
      expect(subject.current_permissions).to be_instance_of(Permissions)
    end

    it 'passes current_user to Permissions::new' do
      allow(subject).to receive(:current_user).and_return 'User'
      expect(subject.current_permissions.user).to eq('User')
    end
  end
end
