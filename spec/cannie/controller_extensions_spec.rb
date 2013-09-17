require 'spec_helper'

describe Cannie::ControllerExtensions do
  let(:klass) {
    Class.new(ActionController::Base) do
      def action; end
      def index
        @entries = [1,2,3,4,5]
        render text: @entries.to_s
      end

      %i(show new create edit update destroy).each do |action|
        define_method action do
          @entry = 123
          render text: @entry.to_s
        end
      end
    end
  }

  subject { klass.new }

  let(:permissions) do
    Class.new do
      include Cannie::Permissions

      def initialize
        allow :update, on: Array do |*attrs|
          attrs.all?{|v| v % 3 == 0}
        end
      end
    end
  end

  let(:resource_permissions) do
    Class.new do
      include Cannie::Permissions

      def initialize
        allow :list, on: Array
        %i(read create update destroy).each{ |v| allow v, on: Fixnum }
      end
    end
  end

  describe '.check_permissions' do
    describe 'without conditions' do
      before { klass.check_permissions }

      it 'raises exception if controller.permitted? evaluates to false' do
        expect { subject.run_callbacks(:process_action) }.to raise_error(Cannie::CheckPermissionsNotPerformed)
      end

      it 'does not raise exception if controller.permitted? evaluates to true' do
        subject.stub(:permitted?).and_return(true)
        expect { subject.run_callbacks(:process_action) }.not_to raise_error
      end
    end

    describe 'with if condition' do
      before { klass.check_permissions if: :condition? }

      it 'raises exception if :if block executed in controller scope returns true' do
        subject.stub(:condition?).and_return(true)
        expect { subject.run_callbacks(:process_action) }.to raise_error(Cannie::CheckPermissionsNotPerformed)
      end

      it 'does not raise exception if :if block executed in controller scope returns false' do
        subject.stub(:condition?).and_return(false)
        expect { subject.run_callbacks(:process_action) }.not_to raise_error
      end
    end

    describe 'with unless condition' do
      before { klass.check_permissions unless: :condition? }

      it 'raises exception if :unless block executed in controller scope returns false' do
        subject.stub(:condition?).and_return(false)
        expect { subject.run_callbacks(:process_action) }.to raise_error(Cannie::CheckPermissionsNotPerformed)
      end

      it 'does not raise exception if :unless block executed in controller scope returns false' do
        subject.stub(:condition?).and_return(true)
        expect { subject.run_callbacks(:process_action) }.not_to raise_error
      end
    end
  end

  describe '.skip_check_permissions' do
    it 'sets @_permitted to true to bypass permissions checking' do
      klass.skip_check_permissions
      subject.run_callbacks(:process_action)
      expect(subject.permitted?).to be_true
    end
  end

  describe 'permit_resource_actions' do
    before do
      klass.permit_resource_actions
      subject.stub(:controller_name).and_return('test/entries')
      subject.stub(:current_permissions).and_return resource_permissions.new
    end

    it 'calls permit! for index with valid params' do
      expect(subject).to receive(:permit!).with(Cannie::ControllerExtensions::RESOURCE_ACTIONS[:index], on: [1,2,3,4,5])
      subject.dispatch(:index, ActionDispatch::TestRequest.new)
    end

    it 'calls permit! for show with valid params' do
      expect(subject).to receive(:permit!).with(Cannie::ControllerExtensions::RESOURCE_ACTIONS[:show], on: 123)
      subject.dispatch(:show, ActionDispatch::TestRequest.new)
    end

    %i(index show).each do |action|
      it "permits #{action} action" do
        subject.dispatch(action, ActionDispatch::TestRequest.new)
        expect(subject.permitted?).to be_true
      end
    end

    it 'raises Cannie::ActionForbidden error up the stack' do
      expect(subject).to receive(:index).and_raise(Cannie::ActionForbidden)
      expect { subject.dispatch(:index, ActionDispatch::TestRequest.new) }.to raise_error(Cannie::ActionForbidden)
      expect(subject.response_body).to be_nil
    end
  end

  describe '#can?' do
    it 'raises SubjectNotSetError if value of :on param is nil' do
      expect { subject.can? :action }.to raise_error(Cannie::SubjectNotSetError)
    end

    it 'returns true if action allowed on subject' do
      subject.stub(:current_permissions).and_return permissions.new
      expect(subject.can? :update, on: [3,6,9]).to be_true
    end

    it 'returns false if action not allowed on subject' do
      subject.stub(:current_permissions).and_return permissions.new
      expect(subject.can? :update, on: [3,7,9]).to be_false
    end
  end

  describe '#permit!' do
    it 'raises SubjectNotSetError if value of :on param is nil' do
      expect { subject.permit! :action }.to raise_error(Cannie::SubjectNotSetError)
    end

    it 'assigns @_permitted to true if action is allowed on subject' do
      subject.stub(:current_permissions).and_return permissions.new
      subject.permit! :update, on: [3,6,9]
      expect(subject.permitted?).to be_true
    end

    it 'raises AccessDenied error if action is not allowed on subject' do
      subject.stub(:current_permissions).and_return permissions.new
      expect { subject.permit! :update, on: [3,6,11] }.to raise_error(Cannie::ActionForbidden)
    end
  end

  describe '#current_permissions' do
    before(:all) do
      Permissions = Class.new do
        attr_reader :user
        def initialize(user)
          @user = user
        end
      end
    end

    before { subject.stub(:current_user).and_return 'User' }

    it 'creates new Permissions object' do
      expect(subject.current_permissions).to be_instance_of(Permissions)
    end

    it 'passes current_user to Permissions::new' do
      subject.stub(:current_user).and_return 'User'
      expect(subject.current_permissions.user).to eq('User')
    end
  end
end