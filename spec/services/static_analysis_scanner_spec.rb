require 'rails_helper'

RSpec.describe StaticAnalysisScanner do
  let(:app) { create(:app, name: 'test_app', path: '/path/to/test_app') }
  let(:scanner) { StaticAnalysisScanner.new(app) }

  before do
    allow(File).to receive(:directory?).with(app.path).and_return(true)
  end

  describe '#scan' do
    context 'when app does not exist' do
      before do
        allow(File).to receive(:directory?).with(app.path).and_return(false)
      end

      it 'returns without scanning' do
        expect(scanner).not_to receive(:run_reek)
        scanner.scan
      end
    end

    context 'when app exists' do
      before do
        allow(scanner).to receive(:run_reek)
        allow(scanner).to receive(:run_flog)
        allow(scanner).to receive(:run_flay)
        allow(scanner).to receive(:save_results)
      end

      it 'runs all static analysis tools' do
        expect(scanner).to receive(:run_reek)
        expect(scanner).to receive(:run_flog)
        expect(scanner).to receive(:run_flay)
        expect(scanner).to receive(:save_results)
        scanner.scan
      end
    end
  end

  describe '#run_reek' do
    let(:output_file) { Rails.root.join('tmp', 'reek_test_app.json') }
    let(:reek_output) do
      [
        {
          'source' => 'app/models/user.rb',
          'smells' => [
            {
              'smell_type' => 'TooManyStatements',
              'message' => 'has too many statements',
              'lines' => [10, 20]
            }
          ]
        }
      ]
    end

    before do
      allow(scanner).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).with(output_file).and_return(true)
      allow(File).to receive(:read).with(output_file).and_return(reek_output.to_json)
      allow(File).to receive(:delete).with(output_file)
    end

    it 'runs reek command' do
      expect(scanner).to receive(:system).with(/reek/)
      scanner.send(:run_reek)
    end

    it 'parses reek results' do
      scanner.send(:run_reek)
      expect(scanner.results).to include(
        hash_including(
          scan_type: 'static_analysis',
          severity: 'medium',
          message: /TooManyStatements/
        )
      )
    end

    context 'when reek fails' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(false)
      end

      it 'returns without parsing' do
        scanner.send(:run_reek)
        expect(scanner.results).to be_empty
      end
    end
  end

  describe '#run_flog' do
    let(:flog_output) do
      <<~OUTPUT
        /path/to/app/models/user.rb: (flog total: 50.0)
           25.5: User#complex_method
           15.2: User#another_method
      OUTPUT
    end

    before do
      allow(scanner).to receive(:`).with(/flog/).and_return(flog_output)
    end

    it 'parses flog output for high complexity' do
      scanner.send(:run_flog)
      expect(scanner.results).to include(
        hash_including(
          scan_type: 'static_analysis',
          severity: 'high',
          message: /High complexity.*25.5/
        )
      )
    end

    it 'does not flag low complexity methods' do
      low_complexity_output = <<~OUTPUT
        /path/to/app/models/user.rb: (flog total: 10.0)
           5.0: User#simple_method
      OUTPUT
      allow(scanner).to receive(:`).with(/flog/).and_return(low_complexity_output)
      scanner.send(:run_flog)
      expect(scanner.results).to be_empty
    end

    context 'when flog raises error' do
      before do
        allow(scanner).to receive(:`).and_raise(StandardError.new('Flog error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with(/Flog scan failed/)
        scanner.send(:run_flog)
      end
    end
  end

  describe '#run_flay' do
    let(:flay_output) do
      <<~OUTPUT
        Similar code found in :defn (mass = 50)
          app/models/user.rb:42
          app/models/admin.rb:15
      OUTPUT
    end

    before do
      allow(scanner).to receive(:`).with(/flay/).and_return(flay_output)
    end

    it 'parses flay output for duplicated code' do
      scanner.send(:run_flay)
      expect(scanner.results).to include(
        hash_including(
          scan_type: 'static_analysis',
          severity: 'low',
          message: /Similar code found/
        )
      )
    end

    context 'when flay raises error' do
      before do
        allow(scanner).to receive(:`).and_raise(StandardError.new('Flay error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with(/Flay scan failed/)
        scanner.send(:run_flay)
      end
    end
  end

  describe '#save_results' do
    let!(:old_scan) { create(:quality_scan, app: app, scan_type: 'static_analysis') }

    before do
      scanner.instance_variable_set(:@results, [
        { scan_type: 'static_analysis', severity: 'medium', message: 'Code smell', metric_value: 25.5, scanned_at: Time.current }
      ])
      allow(scanner).to receive(:create_summary)
    end

    it 'deletes old static_analysis scans' do
      scanner.send(:save_results)
      expect(app.quality_scans.where(scan_type: 'static_analysis').count).to eq(1)
    end

    it 'creates new quality scans' do
      scanner.send(:save_results)
      new_scan = app.quality_scans.where(scan_type: 'static_analysis').last
      expect(new_scan.message).to eq('Code smell')
    end
  end

  describe '#create_summary' do
    let!(:high_scan) { create(:quality_scan, app: app, scan_type: 'static_analysis', severity: 'high', metric_value: 35.0) }
    let!(:medium_scan) { create(:quality_scan, app: app, scan_type: 'static_analysis', severity: 'medium', metric_value: 20.0) }

    it 'creates metric summary with correct counts and average' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'static_analysis')
      expect(summary.total_issues).to eq(2)
      expect(summary.high_severity).to eq(1)
      expect(summary.average_score).to eq(27.5)
    end
  end
end
