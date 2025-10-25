require 'rails_helper'

RSpec.describe TestCoverageScanner do
  let(:app) { create(:app, name: 'test_app', path: '/path/to/test_app') }
  let(:scanner) { TestCoverageScanner.new(app) }

  before do
    allow(File).to receive(:directory?).with(app.path).and_return(true)
  end

  describe '#scan' do
    context 'when app does not exist' do
      before do
        allow(File).to receive(:directory?).with(app.path).and_return(false)
      end

      it 'returns without scanning' do
        expect(scanner).not_to receive(:run_tests_with_coverage)
        scanner.scan
      end
    end

    context 'when app exists' do
      before do
        allow(scanner).to receive(:run_tests_with_coverage)
        allow(scanner).to receive(:save_results)
      end

      it 'runs tests and saves results' do
        expect(scanner).to receive(:run_tests_with_coverage)
        expect(scanner).to receive(:save_results)
        scanner.scan
      end
    end
  end

  describe '#run_tests_with_coverage' do
    let(:coverage_file) { File.join(app.path, 'coverage', '.resultset.json') }

    context 'when coverage results already exist' do
      before do
        allow(File).to receive(:exist?).with(coverage_file).and_return(true)
        allow(scanner).to receive(:parse_coverage_results)
      end

      it 'parses existing coverage' do
        expect(scanner).to receive(:parse_coverage_results).with(coverage_file)
        scanner.send(:run_tests_with_coverage)
      end

      it 'does not run test suite' do
        expect(scanner).not_to receive(:run_test_suite)
        scanner.send(:run_tests_with_coverage)
      end
    end

    context 'when coverage results do not exist but test directory exists' do
      let(:test_dir) { File.join(app.path, 'test') }

      before do
        allow(File).to receive(:exist?).with(coverage_file).and_return(false)
        allow(File).to receive(:exist?).with(test_dir).and_return(true)
        allow(scanner).to receive(:run_test_suite)
        allow(scanner).to receive(:parse_coverage_results)
      end

      it 'runs test suite' do
        expect(scanner).to receive(:run_test_suite)
        scanner.send(:run_tests_with_coverage)
      end
    end

    context 'when error occurs' do
      before do
        allow(File).to receive(:exist?).and_raise(StandardError.new('File error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with(/Test coverage scan failed/)
        scanner.send(:run_tests_with_coverage)
      end
    end
  end

  describe '#run_test_suite' do
    it 'runs rails test with timeout' do
      expect(scanner).to receive(:system).with(/timeout.*bin\/rails test/)
      scanner.send(:run_test_suite)
    end
  end

  describe '#parse_coverage_results' do
    let(:coverage_data) do
      {
        'RSpec' => {
          'coverage' => {
            'app/models/user.rb' => [1, 1, nil, 1, 0, nil, 1, 1],
            'app/controllers/users_controller.rb' => [1, 1, 1, 1, 1],
            'test/user_test.rb' => [1, 1, 1] # Should be skipped
          }
        }
      }
    end
    let(:coverage_file) { '/path/to/coverage/.resultset.json' }

    before do
      allow(File).to receive(:read).with(coverage_file).and_return(coverage_data.to_json)
    end

    it 'parses coverage file' do
      scanner.send(:parse_coverage_results, coverage_file)
      expect(scanner.results).not_to be_empty
    end

    it 'flags files with low coverage' do
      scanner.send(:parse_coverage_results, coverage_file)
      low_coverage_result = scanner.results.find { |r| r[:message].include?('Low test coverage') }
      expect(low_coverage_result).to be_present
    end

    it 'stores overall coverage' do
      scanner.send(:parse_coverage_results, coverage_file)
      overall = scanner.results.find { |r| r[:message].include?('Overall test coverage') }
      expect(overall).to be_present
      expect(overall[:severity]).to eq('info')
    end

    it 'skips test files' do
      scanner.send(:parse_coverage_results, coverage_file)
      test_file_result = scanner.results.find { |r| r[:file_path]&.include?('test/') }
      expect(test_file_result).to be_nil
    end

    it 'assigns high severity for very low coverage' do
      low_coverage_data = {
        'RSpec' => {
          'coverage' => {
            'app/models/user.rb' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          }
        }
      }
      allow(File).to receive(:read).with(coverage_file).and_return(low_coverage_data.to_json)
      scanner.send(:parse_coverage_results, coverage_file)

      low_cov = scanner.results.find { |r| r[:severity] == 'high' }
      expect(low_cov).to be_present
    end
  end

  describe '#save_results' do
    let!(:old_scan) { create(:quality_scan, app: app, scan_type: 'test_coverage') }

    before do
      scanner.instance_variable_set(:@results, [
        { scan_type: 'test_coverage', severity: 'info', message: 'Overall: 85%', metric_value: 85.0, scanned_at: Time.current }
      ])
      allow(scanner).to receive(:create_summary)
    end

    it 'deletes old test_coverage scans' do
      scanner.send(:save_results)
      expect(app.quality_scans.where(scan_type: 'test_coverage').count).to eq(1)
    end

    it 'creates new quality scans' do
      scanner.send(:save_results)
      new_scan = app.quality_scans.where(scan_type: 'test_coverage').last
      expect(new_scan.message).to eq('Overall: 85%')
    end
  end

  describe '#create_summary' do
    let!(:info_scan) { create(:quality_scan, app: app, scan_type: 'test_coverage', severity: 'info', metric_value: 85.5) }
    let!(:high_scan) { create(:quality_scan, app: app, scan_type: 'test_coverage', severity: 'high') }

    it 'creates metric summary with overall coverage' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'test_coverage')
      expect(summary.average_score).to eq(85.5)
      expect(summary.metadata['overall_coverage']).to eq(85.5)
    end

    it 'excludes info scans from issue count' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'test_coverage')
      expect(summary.total_issues).to eq(1) # Only high_scan, not info_scan
    end
  end
end
