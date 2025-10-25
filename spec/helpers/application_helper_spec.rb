require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#status_badge_class' do
    it 'returns green classes for healthy status' do
      expect(helper.status_badge_class('healthy')).to eq('bg-green-100 text-green-800')
    end

    it 'returns yellow classes for warning status' do
      expect(helper.status_badge_class('warning')).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns red classes for critical status' do
      expect(helper.status_badge_class('critical')).to eq('bg-red-100 text-red-800')
    end

    it 'returns gray classes for unknown status' do
      expect(helper.status_badge_class('unknown')).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns gray classes for nil status' do
      expect(helper.status_badge_class(nil)).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns gray classes for pending status' do
      expect(helper.status_badge_class('pending')).to eq('bg-gray-100 text-gray-800')
    end
  end

  describe '#severity_badge_class' do
    it 'returns red classes for critical severity' do
      expect(helper.severity_badge_class('critical')).to eq('bg-red-100 text-red-800')
    end

    it 'returns red classes for high severity' do
      expect(helper.severity_badge_class('high')).to eq('bg-red-100 text-red-800')
    end

    it 'returns yellow classes for medium severity' do
      expect(helper.severity_badge_class('medium')).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns blue classes for low severity' do
      expect(helper.severity_badge_class('low')).to eq('bg-blue-100 text-blue-800')
    end

    it 'returns gray classes for unknown severity' do
      expect(helper.severity_badge_class('unknown')).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns gray classes for nil severity' do
      expect(helper.severity_badge_class(nil)).to eq('bg-gray-100 text-gray-800')
    end

    it 'returns gray classes for info severity' do
      expect(helper.severity_badge_class('info')).to eq('bg-gray-100 text-gray-800')
    end
  end
end
