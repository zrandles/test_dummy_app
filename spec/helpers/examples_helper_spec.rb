require 'rails_helper'

RSpec.describe ExamplesHelper, type: :helper do
  describe '#status_badge' do
    it 'returns blue badge for new status' do
      result = helper.status_badge('new')
      expect(result).to include('bg-blue-100 text-blue-700')
      expect(result).to include('New')
    end

    it 'returns yellow badge for in_progress status' do
      result = helper.status_badge('in_progress')
      expect(result).to include('bg-yellow-100 text-yellow-700')
      expect(result).to include('In Progress')
    end

    it 'returns green badge for completed status' do
      result = helper.status_badge('completed')
      expect(result).to include('bg-green-100 text-green-700')
      expect(result).to include('Completed')
    end

    it 'returns gray badge for archived status' do
      result = helper.status_badge('archived')
      expect(result).to include('bg-gray-100 text-gray-700')
      expect(result).to include('Archived')
    end

    it 'returns gray badge with titleized label for unknown status' do
      result = helper.status_badge('custom_status')
      expect(result).to include('bg-gray-100 text-gray-700')
      expect(result).to include('Custom Status')
    end

    it 'wraps content in span with appropriate classes' do
      result = helper.status_badge('new')
      expect(result).to match(/<span.*class=".*px-2 py-1 text-xs rounded.*"/)
    end
  end

  describe '#category_badge' do
    it 'returns purple badge for ui_pattern category' do
      result = helper.category_badge('ui_pattern')
      expect(result).to include('bg-purple-100 text-purple-700')
      expect(result).to include('UI')
    end

    it 'returns green badge for backend_pattern category' do
      result = helper.category_badge('backend_pattern')
      expect(result).to include('bg-green-100 text-green-700')
      expect(result).to include('Backend')
    end

    it 'returns blue badge for data_pattern category' do
      result = helper.category_badge('data_pattern')
      expect(result).to include('bg-blue-100 text-blue-700')
      expect(result).to include('Data')
    end

    it 'returns orange badge for deployment_pattern category' do
      result = helper.category_badge('deployment_pattern')
      expect(result).to include('bg-orange-100 text-orange-700')
      expect(result).to include('Deploy')
    end

    it 'returns gray badge with titleized label for unknown category' do
      result = helper.category_badge('custom_category')
      expect(result).to include('bg-gray-100 text-gray-700')
      expect(result).to include('Custom Category')
    end
  end

  describe '#format_score' do
    it 'returns dash for nil score' do
      result = helper.format_score(nil)
      expect(result).to include('-')
      expect(result).to include('text-gray-400')
    end

    it 'returns bold green for score >= 90' do
      result = helper.format_score(95.0)
      expect(result).to include('text-green-700 font-bold')
      expect(result).to include('95.0')
    end

    it 'returns yellow for score >= 75 and < 90' do
      result = helper.format_score(80.0)
      expect(result).to include('text-yellow-700')
      expect(result).to include('80.0')
    end

    it 'returns gray for score < 75' do
      result = helper.format_score(60.0)
      expect(result).to include('text-gray-600')
      expect(result).to include('60.0')
    end

    it 'rounds score to 1 decimal place' do
      result = helper.format_score(85.456)
      expect(result).to include('85.5')
    end

    it 'handles edge case of exactly 90' do
      result = helper.format_score(90.0)
      expect(result).to include('text-green-700 font-bold')
    end

    it 'handles edge case of exactly 75' do
      result = helper.format_score(75.0)
      expect(result).to include('text-yellow-700')
    end
  end

  describe '#format_priority' do
    it 'returns dash for nil priority' do
      result = helper.format_priority(nil)
      expect(result).to include('-')
      expect(result).to include('text-gray-400')
    end

    it 'returns red bold for priority 5' do
      result = helper.format_priority(5)
      expect(result).to include('text-red-700 font-bold')
      expect(result).to include('5')
    end

    it 'returns orange semibold for priority 4' do
      result = helper.format_priority(4)
      expect(result).to include('text-orange-700 font-semibold')
      expect(result).to include('4')
    end

    it 'returns yellow for priority 3' do
      result = helper.format_priority(3)
      expect(result).to include('text-yellow-700')
      expect(result).to include('3')
    end

    it 'returns blue for priority 2' do
      result = helper.format_priority(2)
      expect(result).to include('text-blue-700')
      expect(result).to include('2')
    end

    it 'returns gray for priority 1' do
      result = helper.format_priority(1)
      expect(result).to include('text-gray-600')
      expect(result).to include('1')
    end

    it 'returns gray for unknown priority' do
      result = helper.format_priority(99)
      expect(result).to include('text-gray-600')
      expect(result).to include('99')
    end
  end

  describe '#percentile_class' do
    let(:percentiles) do
      {
        'score' => {
          0 => 10.0,
          25 => 25.0,
          50 => 50.0,
          75 => 75.0,
          90 => 90.0,
          95 => 95.0,
          100 => 100.0
        }
      }
    end

    it 'returns empty string for nil value' do
      expect(helper.percentile_class(nil, 'score', percentiles)).to eq('')
    end

    it 'returns empty string for nil percentiles' do
      expect(helper.percentile_class(50, 'score', nil)).to eq('')
    end

    it 'returns empty string for missing column in percentiles' do
      expect(helper.percentile_class(50, 'missing_column', percentiles)).to eq('')
    end

    it 'returns bold green highlight for >= 95th percentile' do
      result = helper.percentile_class(96.0, 'score', percentiles)
      expect(result).to eq('bg-green-100 font-bold')
    end

    it 'returns green highlight for >= 90th percentile but < 95th' do
      result = helper.percentile_class(92.0, 'score', percentiles)
      expect(result).to eq('bg-green-50')
    end

    it 'returns yellow highlight for >= 75th percentile but < 90th' do
      result = helper.percentile_class(80.0, 'score', percentiles)
      expect(result).to eq('bg-yellow-50')
    end

    it 'returns empty string for < 75th percentile' do
      result = helper.percentile_class(50.0, 'score', percentiles)
      expect(result).to eq('')
    end
  end

  describe '#calculate_percentile (private)' do
    let(:percentile_hash) do
      {
        0 => 10.0,
        25 => 25.0,
        50 => 50.0,
        75 => 75.0,
        100 => 100.0
      }
    end

    it 'returns correct percentile for value in range' do
      # Value 30 should fall around 25th percentile (first value <= 30 is at 25%)
      result = helper.send(:calculate_percentile, 30.0, percentile_hash)
      expect(result).to eq(50)
    end

    it 'returns 0 for value below all percentiles' do
      result = helper.send(:calculate_percentile, 5.0, percentile_hash)
      expect(result).to eq(0)
    end

    it 'returns 100 for value above all percentiles' do
      result = helper.send(:calculate_percentile, 150.0, percentile_hash)
      expect(result).to eq(100)
    end

    it 'handles exact matches' do
      result = helper.send(:calculate_percentile, 50.0, percentile_hash)
      expect(result).to eq(50)
    end
  end
end
