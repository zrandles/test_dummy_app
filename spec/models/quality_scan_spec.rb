require 'rails_helper'

RSpec.describe QualityScan, type: :model do
  describe 'associations' do
    it { should belong_to(:app) }
  end

  describe 'validations' do
    it { should validate_inclusion_of(:scan_type).in_array(QualityScan::SCAN_TYPES) }
    it { should validate_inclusion_of(:severity).in_array(QualityScan::SEVERITIES).allow_nil }

    it 'allows nil severity' do
      scan = build(:quality_scan, severity: nil)
      expect(scan).to be_valid
    end

    it 'rejects invalid scan_type' do
      scan = build(:quality_scan, scan_type: 'invalid_type')
      expect(scan).not_to be_valid
      expect(scan.errors[:scan_type]).to be_present
    end

    it 'rejects invalid severity' do
      scan = build(:quality_scan, severity: 'invalid_severity')
      expect(scan).not_to be_valid
      expect(scan.errors[:severity]).to be_present
    end
  end

  describe 'constants' do
    it 'has correct SCAN_TYPES' do
      expect(QualityScan::SCAN_TYPES).to eq(%w[security static_analysis rubocop test_coverage js_complexity architecture drift])
    end

    it 'has correct SEVERITIES' do
      expect(QualityScan::SEVERITIES).to eq(%w[critical high medium low info])
    end
  end

  describe 'scopes' do
    let(:app) { create(:app) }
    let!(:recent_scan) { create(:quality_scan, app: app, scanned_at: 1.day.ago) }
    let!(:old_scan) { create(:quality_scan, app: app, scanned_at: 30.days.ago) }
    let!(:security_scan) { create(:quality_scan, app: app, scan_type: 'security') }
    let!(:rubocop_scan) { create(:quality_scan, app: app, scan_type: 'rubocop') }
    let!(:critical_scan) { create(:quality_scan, app: app, severity: 'critical') }
    let!(:high_scan) { create(:quality_scan, app: app, severity: 'high') }
    let!(:medium_scan) { create(:quality_scan, app: app, severity: 'medium') }

    describe '.recent' do
      it 'returns scans from last 7 days' do
        expect(QualityScan.recent).to include(recent_scan)
        expect(QualityScan.recent).not_to include(old_scan)
      end
    end

    describe '.by_type' do
      it 'returns scans of specified type' do
        expect(QualityScan.by_type('security')).to include(security_scan)
        expect(QualityScan.by_type('security')).not_to include(rubocop_scan)
      end
    end

    describe '.by_severity' do
      it 'returns scans of specified severity' do
        expect(QualityScan.by_severity('critical')).to include(critical_scan)
        expect(QualityScan.by_severity('critical')).not_to include(high_scan)
      end
    end

    describe '.critical_issues' do
      it 'returns critical and high severity scans' do
        expect(QualityScan.critical_issues).to include(critical_scan)
        expect(QualityScan.critical_issues).to include(high_scan)
        expect(QualityScan.critical_issues).not_to include(medium_scan)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:quality_scan)).to be_valid
    end

    describe 'traits' do
      it 'creates security scans' do
        scan = create(:quality_scan, :security)
        expect(scan.scan_type).to eq('security')
      end

      it 'creates static_analysis scans' do
        scan = create(:quality_scan, :static_analysis)
        expect(scan.scan_type).to eq('static_analysis')
      end

      it 'creates rubocop scans' do
        scan = create(:quality_scan, :rubocop)
        expect(scan.scan_type).to eq('rubocop')
      end

      it 'creates drift scans' do
        scan = create(:quality_scan, :drift)
        expect(scan.scan_type).to eq('drift')
      end

      it 'creates critical severity scans' do
        scan = create(:quality_scan, :critical)
        expect(scan.severity).to eq('critical')
      end

      it 'creates high severity scans' do
        scan = create(:quality_scan, :high)
        expect(scan.severity).to eq('high')
      end

      it 'creates medium severity scans' do
        scan = create(:quality_scan, :medium)
        expect(scan.severity).to eq('medium')
      end

      it 'creates low severity scans' do
        scan = create(:quality_scan, :low)
        expect(scan.severity).to eq('low')
      end

      it 'creates info severity scans' do
        scan = create(:quality_scan, :info)
        expect(scan.severity).to eq('info')
      end

      it 'creates recent scans' do
        scan = create(:quality_scan, :recent)
        expect(scan.scanned_at).to be >= 2.days.ago
      end

      it 'creates old scans' do
        scan = create(:quality_scan, :old)
        expect(scan.scanned_at).to be <= 29.days.ago
      end
    end
  end
end
