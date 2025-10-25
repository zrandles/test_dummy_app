require 'rails_helper'

RSpec.describe SecurityScanner do
  let(:app) { create(:app, name: 'test_app', path: '/path/to/test_app') }
  let(:scanner) { SecurityScanner.new(app) }

  before do
    allow(File).to receive(:directory?).with(app.path).and_return(true)
  end

  describe '#scan' do
    context 'when app does not exist' do
      before do
        allow(File).to receive(:directory?).with(app.path).and_return(false)
      end

      it 'returns without scanning' do
        expect(scanner).not_to receive(:run_brakeman)
        scanner.scan
      end
    end

    context 'when app exists' do
      before do
        allow(scanner).to receive(:run_brakeman)
        allow(scanner).to receive(:save_results)
      end

      it 'runs brakeman and saves results' do
        expect(scanner).to receive(:run_brakeman)
        expect(scanner).to receive(:save_results)
        scanner.scan
      end
    end
  end

  describe '#run_brakeman' do
    let(:output_file) { Rails.root.join('tmp', 'brakeman_test_app.json') }
    let(:brakeman_output) do
      {
        'warnings' => [
          {
            'warning_type' => 'SQL Injection',
            'message' => 'Possible SQL injection',
            'file' => 'app/models/user.rb',
            'line' => 42,
            'confidence' => 'High'
          }
        ]
      }
    end

    before do
      allow(scanner).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).with(output_file).and_return(true)
      allow(File).to receive(:read).with(output_file).and_return(brakeman_output.to_json)
      allow(File).to receive(:delete).with(output_file)
    end

    it 'runs brakeman command' do
      expect(scanner).to receive(:system).with(/brakeman/)
      scanner.send(:run_brakeman)
    end

    it 'parses brakeman results' do
      scanner.send(:run_brakeman)
      expect(scanner.results).to include(
        hash_including(
          scan_type: 'security',
          severity: 'critical',
          message: /SQL Injection/
        )
      )
    end

    it 'deletes output file after parsing' do
      expect(File).to receive(:delete).with(output_file)
      scanner.send(:run_brakeman)
    end

    context 'when brakeman fails' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(false)
      end

      it 'returns without parsing' do
        scanner.send(:run_brakeman)
        expect(scanner.results).to be_empty
      end
    end

    context 'when parsing raises error' do
      before do
        allow(File).to receive(:read).with(output_file).and_raise(StandardError.new('Parse error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with(/Brakeman scan failed/)
        scanner.send(:run_brakeman)
      end
    end
  end

  describe '#severity_for_confidence' do
    it 'returns critical for high confidence' do
      expect(scanner.send(:severity_for_confidence, 'High')).to eq('critical')
    end

    it 'returns high for medium confidence' do
      expect(scanner.send(:severity_for_confidence, 'Medium')).to eq('high')
    end

    it 'returns medium for weak confidence' do
      expect(scanner.send(:severity_for_confidence, 'Weak')).to eq('medium')
    end

    it 'returns low for unknown confidence' do
      expect(scanner.send(:severity_for_confidence, 'Unknown')).to eq('low')
      expect(scanner.send(:severity_for_confidence, nil)).to eq('low')
    end

    it 'handles case-insensitive input' do
      expect(scanner.send(:severity_for_confidence, 'HIGH')).to eq('critical')
      expect(scanner.send(:severity_for_confidence, 'medium')).to eq('high')
    end
  end

  describe '#save_results' do
    let!(:old_scan) { create(:quality_scan, app: app, scan_type: 'security') }

    before do
      scanner.instance_variable_set(:@results, [
        { scan_type: 'security', severity: 'critical', message: 'Security issue', scanned_at: Time.current }
      ])
      allow(scanner).to receive(:create_summary)
    end

    it 'deletes old security scans' do
      expect { scanner.send(:save_results) }.to change {
        app.quality_scans.where(scan_type: 'security').count
      }.from(1).to(1)
    end

    it 'creates new quality scans' do
      scanner.send(:save_results)
      new_scan = app.quality_scans.where(scan_type: 'security').last
      expect(new_scan.message).to eq('Security issue')
    end

    it 'calls create_summary' do
      expect(scanner).to receive(:create_summary)
      scanner.send(:save_results)
    end
  end

  describe '#create_summary' do
    let!(:critical_scan) { create(:quality_scan, app: app, scan_type: 'security', severity: 'critical') }
    let!(:medium_scan) { create(:quality_scan, app: app, scan_type: 'security', severity: 'medium') }

    it 'creates metric summary with correct counts' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'security')
      expect(summary.total_issues).to eq(2)
      expect(summary.high_severity).to eq(1)
      expect(summary.medium_severity).to eq(1)
    end
  end
end
