require 'spec_helper'

class TestController < ActionController::Base
  check_permissions

  def action
  end
end

describe Cannie::ControllerExtensions do
  subject { TestController.new }

  let(:before_filters) do
    subject.class._process_action_callbacks.select{|f| f.kind == :before}.map(&:raw_filter)
  end

  let(:after_filters) do
    subject.class._process_action_callbacks.select{|f| f.kind == :after}.map(&:raw_filter)
  end

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

  describe '.check_permissions' do
    it 'raises exception if controller.permitted? evaluates to false' do
      expect { after_filters.first.call(subject) }.to raise_error(Cannie::CheckPermissionsNotPerformed)
    end

    it 'does not raise exception if controller.permitted? evaluates to true' do
      subject.stub(:permitted?).and_return(true)
      expect { after_filters.first.call(subject) }.not_to raise_error
    end

    it 'raises exception if :if block executed in controller scope returns false' do
      pending
    end

    it 'raises exception if :if block executed in controller scope returns true' do
      pending
    end
  end

  describe '.skip_check_permissions' do
    it 'sets @_permitted to true to bypass permissions checking' do
      subject.class.instance_eval do
        skip_check_permissions
      end

      before_filters.first.call(subject)
      expect(subject.permitted?).to be_true
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
end