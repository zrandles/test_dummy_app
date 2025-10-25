require 'rails_helper'

RSpec.describe RubocopScanner do
  let(:app) { create(:app, name: 'test_app', path: '/path/to/test_app') }
  let(:scanner) { RubocopScanner.new(app) }

  before do
    allow(File).to receive(:directory?).with(app.path).and_return(true)
  end

  describe 'constants' do
    it 'defines HIGH_VALUE_COPS' do
      expect(RubocopScanner::HIGH_VALUE_COPS).to include('Lint/Debugger')
      expect(RubocopScanner::HIGH_VALUE_COPS).to include('Security/Eval')
      expect(RubocopScanner::HIGH_VALUE_COPS).to include('Rails/OutputSafety')
    end
  end

  describe '#scan' do
    context 'when app does not exist' do
      before do
        allow(File).to receive(:directory?).with(app.path).and_return(false)
      end

      it 'returns without scanning' do
        expect(scanner).not_to receive(:run_rubocop)
        scanner.scan
      end
    end

    context 'when app exists' do
      before do
        allow(scanner).to receive(:run_rubocop)
        allow(scanner).to receive(:save_results)
      end

      it 'runs rubocop and saves results' do
        expect(scanner).to receive(:run_rubocop)
        expect(scanner).to receive(:save_results)
        scanner.scan
      end
    end
  end

  describe '#run_rubocop' do
    let(:output_file) { Rails.root.join('tmp', 'rubocop_test_app.json') }
    let(:rubocop_output) do
      {
        'files' => [
          {
            'path' => 'app/models/user.rb',
            'offenses' => [
              {
                'severity' => 'error',
                'message' => 'Debugger statement detected',
                'cop_name' => 'Lint/Debugger',
                'location' => { 'start_line' => 10 }
              }
            ]
          }
        ]
      }
    end

    before do
      allow(scanner).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).with(output_file).and_return(true)
      allow(File).to receive(:read).with(output_file).and_return(rubocop_output.to_json)
      allow(File).to receive(:delete).with(output_file)
    end

    it 'runs rubocop with specific cops' do
      expect(scanner).to receive(:system).with(/rubocop.*--only/)
      scanner.send(:run_rubocop)
    end

    it 'parses rubocop results' do
      scanner.send(:run_rubocop)
      expect(scanner.results).to include(
        hash_including(
          scan_type: 'rubocop',
          severity: 'high',
          message: /Lint\/Debugger/
        )
      )
    end

    it 'deletes output file' do
      expect(File).to receive(:delete).with(output_file)
      scanner.send(:run_rubocop)
    end

    context 'when rubocop fails' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(false)
      end

      it 'returns without parsing' do
        scanner.send(:run_rubocop)
        expect(scanner.results).to be_empty
      end
    end
  end

  describe '#rubocop_severity' do
    it 'returns high for error' do
      expect(scanner.send(:rubocop_severity, 'error')).to eq('high')
    end

    it 'returns high for fatal' do
      expect(scanner.send(:rubocop_severity, 'fatal')).to eq('high')
    end

    it 'returns medium for warning' do
      expect(scanner.send(:rubocop_severity, 'warning')).to eq('medium')
    end

    it 'returns low for convention' do
      expect(scanner.send(:rubocop_severity, 'convention')).to eq('low')
    end

    it 'handles case-insensitive input' do
      expect(scanner.send(:rubocop_severity, 'ERROR')).to eq('high')
      expect(scanner.send(:rubocop_severity, 'Warning')).to eq('medium')
    end
  end

  describe '#save_results' do
    let!(:old_scan) { create(:quality_scan, app: app, scan_type: 'rubocop') }

    before do
      scanner.instance_variable_set(:@results, [
        { scan_type: 'rubocop', severity: 'high', message: 'RuboCop issue', scanned_at: Time.current }
      ])
      allow(scanner).to receive(:create_summary)
    end

    it 'deletes old rubocop scans' do
      scanner.send(:save_results)
      expect(app.quality_scans.where(scan_type: 'rubocop').count).to eq(1)
    end

    it 'creates new quality scans' do
      scanner.send(:save_results)
      new_scan = app.quality_scans.where(scan_type: 'rubocop').last
      expect(new_scan.message).to eq('RuboCop issue')
    end
  end

  describe '#create_summary' do
    let!(:high_scan) { create(:quality_scan, app: app, scan_type: 'rubocop', severity: 'high') }
    let!(:medium_scan) { create(:quality_scan, app: app, scan_type: 'rubocop', severity: 'medium') }

    it 'creates metric summary with correct counts' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'rubocop')
      expect(summary.total_issues).to eq(2)
      expect(summary.high_severity).to eq(1)
      expect(summary.medium_severity).to eq(1)
    end
  end
end
