require 'rails_helper'

RSpec.describe App, type: :model do
  describe 'associations' do
    it { should have_many(:quality_scans).dependent(:destroy) }
    it { should have_many(:metric_summaries).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:path) }
  end

  describe 'scopes' do
    let!(:recently_scanned_app) { create(:app, last_scanned_at: 1.hour.ago) }
    let!(:needs_scan_app) { create(:app, last_scanned_at: 2.days.ago) }
    let!(:never_scanned_app) { create(:app, last_scanned_at: nil) }

    describe '.recently_scanned' do
      it 'returns apps scanned within 24 hours' do
        expect(App.recently_scanned).to include(recently_scanned_app)
        expect(App.recently_scanned).not_to include(needs_scan_app)
        expect(App.recently_scanned).not_to include(never_scanned_app)
      end
    end

    describe '.needs_scan' do
      it 'returns apps not scanned in 24 hours or never scanned' do
        expect(App.needs_scan).to include(needs_scan_app)
        expect(App.needs_scan).to include(never_scanned_app)
        expect(App.needs_scan).not_to include(recently_scanned_app)
      end
    end
  end

  describe '#scan_status_color' do
    it 'returns green for healthy status' do
      app = build(:app, status: 'healthy')
      expect(app.scan_status_color).to eq('green')
    end

    it 'returns yellow for warning status' do
      app = build(:app, status: 'warning')
      expect(app.scan_status_color).to eq('yellow')
    end

    it 'returns red for critical status' do
      app = build(:app, status: 'critical')
      expect(app.scan_status_color).to eq('red')
    end

    it 'returns gray for unknown status' do
      app = build(:app, status: 'unknown')
      expect(app.scan_status_color).to eq('gray')
    end

    it 'returns gray for nil status' do
      app = build(:app, status: nil)
      expect(app.scan_status_color).to eq('gray')
    end
  end

  describe '#latest_summaries' do
    let(:app) { create(:app) }

    context 'with multiple summaries of different types' do
      let!(:security_summary_old) { create(:metric_summary, app: app, scan_type: 'security', scanned_at: 2.days.ago) }
      let!(:security_summary_new) { create(:metric_summary, app: app, scan_type: 'security', scanned_at: 1.day.ago) }
      let!(:rubocop_summary) { create(:metric_summary, app: app, scan_type: 'rubocop', scanned_at: 1.day.ago) }

      it 'returns most recent summary for each scan_type' do
        summaries = app.latest_summaries
        expect(summaries.keys).to contain_exactly('security', 'rubocop')
        expect(summaries['security']).to eq(security_summary_new)
        expect(summaries['rubocop']).to eq(rubocop_summary)
      end

      it 'does not include older summaries' do
        summaries = app.latest_summaries
        expect(summaries.values).not_to include(security_summary_old)
      end
    end

    context 'with no summaries' do
      it 'returns empty hash' do
        expect(app.latest_summaries).to eq({})
      end
    end

    context 'with single summary per type' do
      let!(:summary1) { create(:metric_summary, app: app, scan_type: 'drift') }
      let!(:summary2) { create(:metric_summary, app: app, scan_type: 'test_coverage') }

      it 'returns all summaries grouped by type' do
        summaries = app.latest_summaries
        expect(summaries.keys).to contain_exactly('drift', 'test_coverage')
        expect(summaries['drift']).to eq(summary1)
        expect(summaries['test_coverage']).to eq(summary2)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:app)).to be_valid
    end

    it 'creates apps with unique names' do
      app1 = create(:app)
      app2 = create(:app)
      expect(app1.name).not_to eq(app2.name)
    end

    describe 'traits' do
      it 'creates healthy apps' do
        app = create(:app, :healthy)
        expect(app.status).to eq('healthy')
      end

      it 'creates warning apps' do
        app = create(:app, :warning)
        expect(app.status).to eq('warning')
      end

      it 'creates critical apps' do
        app = create(:app, :critical)
        expect(app.status).to eq('critical')
      end

      it 'creates pending apps without scan date' do
        app = create(:app, :pending)
        expect(app.status).to eq('pending')
        expect(app.last_scanned_at).to be_nil
      end

      it 'creates apps with quality scans' do
        app = create(:app, :with_quality_scans)
        expect(app.quality_scans.count).to eq(3)
      end

      it 'creates apps with metric summaries' do
        app = create(:app, :with_metric_summaries)
        expect(app.metric_summaries.count).to eq(2)
      end
    end
  end
end
