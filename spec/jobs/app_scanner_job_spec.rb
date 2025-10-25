require 'rails_helper'

RSpec.describe AppScannerJob, type: :job do
  let(:app) { create(:app) }

  describe '#perform' do
    before do
      allow(Rails.logger).to receive(:info)
      allow(SecurityScanner).to receive_message_chain(:new, :scan)
      allow(StaticAnalysisScanner).to receive_message_chain(:new, :scan)
      allow(RubocopScanner).to receive_message_chain(:new, :scan)
      allow(DriftScanner).to receive_message_chain(:new, :scan)
    end

    it 'logs scan start' do
      expect(Rails.logger).to receive(:info).with("Starting quality scan for #{app.name}")
      AppScannerJob.perform_now(app.id)
    end

    it 'runs security scanner' do
      security_scanner = instance_double(SecurityScanner)
      expect(SecurityScanner).to receive(:new).with(app).and_return(security_scanner)
      expect(security_scanner).to receive(:scan)
      AppScannerJob.perform_now(app.id)
    end

    it 'runs static analysis scanner' do
      static_scanner = instance_double(StaticAnalysisScanner)
      expect(StaticAnalysisScanner).to receive(:new).with(app).and_return(static_scanner)
      expect(static_scanner).to receive(:scan)
      AppScannerJob.perform_now(app.id)
    end

    it 'runs rubocop scanner' do
      rubocop_scanner = instance_double(RubocopScanner)
      expect(RubocopScanner).to receive(:new).with(app).and_return(rubocop_scanner)
      expect(rubocop_scanner).to receive(:scan)
      AppScannerJob.perform_now(app.id)
    end

    it 'runs drift scanner' do
      drift_scanner = instance_double(DriftScanner)
      expect(DriftScanner).to receive(:new).with(app).and_return(drift_scanner)
      expect(drift_scanner).to receive(:scan)
      AppScannerJob.perform_now(app.id)
    end

    it 'updates app status' do
      expect(app).to receive(:update!)
      allow(App).to receive(:find).with(app.id).and_return(app)
      AppScannerJob.perform_now(app.id)
    end

    it 'logs scan completion' do
      expect(Rails.logger).to receive(:info).with("Completed quality scan for #{app.name}")
      AppScannerJob.perform_now(app.id)
    end

    context 'when app does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          AppScannerJob.perform_now(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update_app_status' do
    let(:job) { AppScannerJob.new }

    context 'with critical issues' do
      before do
        create(:quality_scan, app: app, severity: 'critical')
      end

      it 'sets status to critical' do
        job.send(:update_app_status, app)
        expect(app.reload.status).to eq('critical')
      end

      it 'updates last_scanned_at' do
        job.send(:update_app_status, app)
        expect(app.reload.last_scanned_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'with high severity issues' do
      before do
        create(:quality_scan, app: app, severity: 'high')
      end

      it 'sets status to critical' do
        job.send(:update_app_status, app)
        expect(app.reload.status).to eq('critical')
      end
    end

    context 'with many medium severity issues' do
      before do
        create_list(:quality_scan, 6, app: app, severity: 'medium')
      end

      it 'sets status to warning' do
        job.send(:update_app_status, app)
        expect(app.reload.status).to eq('warning')
      end
    end

    context 'with few medium severity issues' do
      before do
        create_list(:quality_scan, 3, app: app, severity: 'medium')
      end

      it 'sets status to healthy' do
        job.send(:update_app_status, app)
        expect(app.reload.status).to eq('healthy')
      end
    end

    context 'with no issues' do
      it 'sets status to healthy' do
        job.send(:update_app_status, app)
        expect(app.reload.status).to eq('healthy')
      end
    end
  end

  describe '#determine_status' do
    let(:job) { AppScannerJob.new }

    it 'returns critical when critical_count > 0' do
      expect(job.send(:determine_status, 1, 0)).to eq('critical')
    end

    it 'returns warning when medium_count > 5' do
      expect(job.send(:determine_status, 0, 6)).to eq('warning')
    end

    it 'returns healthy when medium_count <= 5' do
      expect(job.send(:determine_status, 0, 5)).to eq('healthy')
    end

    it 'returns healthy when no issues' do
      expect(job.send(:determine_status, 0, 0)).to eq('healthy')
    end

    it 'prioritizes critical over warning' do
      expect(job.send(:determine_status, 1, 10)).to eq('critical')
    end
  end

  describe 'job configuration' do
    it 'is queued on default queue' do
      expect(AppScannerJob.new.queue_name).to eq('default')
    end
  end

  describe 'enqueuing' do
    it 'enqueues the job' do
      expect {
        AppScannerJob.perform_later(app.id)
      }.to have_enqueued_job(AppScannerJob).with(app.id)
    end

    it 'can be performed immediately' do
      allow(Rails.logger).to receive(:info)
      allow(SecurityScanner).to receive_message_chain(:new, :scan)
      allow(StaticAnalysisScanner).to receive_message_chain(:new, :scan)
      allow(RubocopScanner).to receive_message_chain(:new, :scan)
      allow(DriftScanner).to receive_message_chain(:new, :scan)

      expect {
        AppScannerJob.perform_now(app.id)
      }.not_to raise_error
    end
  end
end
