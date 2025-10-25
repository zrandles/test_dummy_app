require 'rails_helper'

RSpec.describe MetricSummary, type: :model do
  describe 'associations' do
    it { should belong_to(:app) }
  end

  describe 'validations' do
    it { should validate_presence_of(:scan_type) }
  end

  describe 'scopes' do
    let(:app) { create(:app) }
    let!(:recent_summary) { create(:metric_summary, app: app, scanned_at: 1.day.ago) }
    let!(:old_summary) { create(:metric_summary, app: app, scanned_at: 30.days.ago) }
    let!(:security_summary) { create(:metric_summary, app: app, scan_type: 'security') }
    let!(:rubocop_summary) { create(:metric_summary, app: app, scan_type: 'rubocop') }

    describe '.recent' do
      it 'returns summaries from last 7 days' do
        expect(MetricSummary.recent).to include(recent_summary)
        expect(MetricSummary.recent).not_to include(old_summary)
      end
    end

    describe '.by_type' do
      it 'returns summaries of specified type' do
        expect(MetricSummary.by_type('security')).to include(security_summary)
        expect(MetricSummary.by_type('security')).not_to include(rubocop_summary)
      end
    end
  end

  describe '#status' do
    it 'returns healthy when total_issues is zero' do
      summary = build(:metric_summary, total_issues: 0)
      expect(summary.status).to eq('healthy')
    end

    it 'returns critical when high_severity is greater than 0' do
      summary = build(:metric_summary, total_issues: 10, high_severity: 1, medium_severity: 5)
      expect(summary.status).to eq('critical')
    end

    it 'returns warning when medium_severity is greater than 5' do
      summary = build(:metric_summary, total_issues: 10, high_severity: 0, medium_severity: 6)
      expect(summary.status).to eq('warning')
    end

    it 'returns healthy when medium_severity is 5 or less' do
      summary = build(:metric_summary, total_issues: 5, high_severity: 0, medium_severity: 5, low_severity: 0)
      expect(summary.status).to eq('healthy')
    end

    it 'returns healthy when only low severity issues exist' do
      summary = build(:metric_summary, total_issues: 10, high_severity: 0, medium_severity: 0, low_severity: 10)
      expect(summary.status).to eq('healthy')
    end
  end

  describe '#status_color' do
    it 'returns green for healthy status' do
      summary = build(:metric_summary, total_issues: 0)
      expect(summary.status_color).to eq('green')
    end

    it 'returns red for critical status' do
      summary = build(:metric_summary, total_issues: 10, high_severity: 1)
      expect(summary.status_color).to eq('red')
    end

    it 'returns yellow for warning status' do
      summary = build(:metric_summary, total_issues: 10, high_severity: 0, medium_severity: 6)
      expect(summary.status_color).to eq('yellow')
    end

    it 'returns gray for unknown status' do
      summary = build(:metric_summary, total_issues: 0)
      allow(summary).to receive(:status).and_return('unknown')
      expect(summary.status_color).to eq('gray')
    end
  end

  describe 'metadata serialization' do
    it 'serializes metadata as JSON' do
      summary = create(:metric_summary, metadata: { coverage: 85.5, files: 42 })
      summary.reload
      expect(summary.metadata).to eq({ 'coverage' => 85.5, 'files' => 42 })
    end

    it 'handles nil metadata' do
      summary = create(:metric_summary, metadata: nil)
      summary.reload
      expect(summary.metadata).to be_nil
    end

    it 'handles empty hash metadata' do
      summary = create(:metric_summary, metadata: {})
      summary.reload
      expect(summary.metadata).to eq({})
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:metric_summary)).to be_valid
    end

    describe 'traits' do
      it 'creates security summaries' do
        summary = create(:metric_summary, :security)
        expect(summary.scan_type).to eq('security')
      end

      it 'creates static_analysis summaries' do
        summary = create(:metric_summary, :static_analysis)
        expect(summary.scan_type).to eq('static_analysis')
      end

      it 'creates rubocop summaries' do
        summary = create(:metric_summary, :rubocop)
        expect(summary.scan_type).to eq('rubocop')
      end

      it 'creates test_coverage summaries' do
        summary = create(:metric_summary, :test_coverage)
        expect(summary.scan_type).to eq('test_coverage')
      end

      it 'creates drift summaries' do
        summary = create(:metric_summary, :drift)
        expect(summary.scan_type).to eq('drift')
      end

      it 'creates healthy summaries' do
        summary = create(:metric_summary, :healthy)
        expect(summary.total_issues).to eq(0)
        expect(summary.status).to eq('healthy')
      end

      it 'creates critical summaries' do
        summary = create(:metric_summary, :critical)
        expect(summary.status).to eq('critical')
      end

      it 'creates warning summaries' do
        summary = create(:metric_summary, :warning)
        expect(summary.status).to eq('warning')
      end

      it 'creates recent summaries' do
        summary = create(:metric_summary, :recent)
        expect(summary.scanned_at).to be >= 2.days.ago
      end

      it 'creates old summaries' do
        summary = create(:metric_summary, :old)
        expect(summary.scanned_at).to be <= 29.days.ago
      end
    end
  end
end
