require 'rails_helper'

RSpec.describe DriftScanner do
  let(:app) { create(:app, name: 'test_app', path: '/path/to/test_app') }
  let(:scanner) { DriftScanner.new(app) }

  before do
    # Mock file system checks
    allow(File).to receive(:directory?).with(app.path).and_return(true)
  end

  describe '#scan' do
    context 'when app directory does not exist' do
      before do
        allow(File).to receive(:directory?).with(app.path).and_return(false)
      end

      it 'returns without scanning' do
        expect(scanner).not_to receive(:check_deployment_config)
        scanner.scan
      end
    end

    context 'when app is golden_deployment' do
      let(:app) { create(:app, name: 'golden_deployment') }

      it 'skips scanning itself' do
        expect(scanner).not_to receive(:check_deployment_config)
        scanner.scan
      end
    end

    context 'when app exists and is not golden_deployment' do
      before do
        allow(scanner).to receive(:check_deployment_config)
        allow(scanner).to receive(:check_gem_versions)
        allow(scanner).to receive(:check_tailwind_setup)
        allow(scanner).to receive(:check_path_based_routing)
        allow(scanner).to receive(:save_results)
      end

      it 'runs all checks' do
        expect(scanner).to receive(:check_deployment_config)
        expect(scanner).to receive(:check_gem_versions)
        expect(scanner).to receive(:check_tailwind_setup)
        expect(scanner).to receive(:check_path_based_routing)
        expect(scanner).to receive(:save_results)
        scanner.scan
      end
    end
  end

  describe '#check_deployment_config' do
    let(:deploy_file) { File.join(app.path, 'config', 'deploy.rb') }

    context 'when deploy.rb does not exist' do
      before do
        allow(File).to receive(:exist?).with(deploy_file).and_return(false)
      end

      it 'adds critical result for missing deployment config' do
        scanner.send(:check_deployment_config)
        expect(scanner.results).to include(
          hash_including(
            scan_type: 'drift',
            severity: 'critical',
            message: 'Missing config/deploy.rb - deployment not configured'
          )
        )
      end
    end

    context 'when deploy.rb exists but missing application setting' do
      before do
        allow(File).to receive(:exist?).with(deploy_file).and_return(true)
        allow(File).to receive(:read).with(deploy_file).and_return('# empty config')
      end

      it 'adds high severity result' do
        scanner.send(:check_deployment_config)
        expect(scanner.results).to include(
          hash_including(
            scan_type: 'drift',
            severity: 'high',
            message: 'Deployment config missing :application setting'
          )
        )
      end
    end

    context 'when deploy.rb is properly configured' do
      before do
        allow(File).to receive(:exist?).with(deploy_file).and_return(true)
        allow(File).to receive(:read).with(deploy_file).and_return('set :application, "test_app"')
      end

      it 'does not add any results' do
        scanner.send(:check_deployment_config)
        expect(scanner.results).to be_empty
      end
    end

    context 'when file read raises error' do
      before do
        allow(File).to receive(:exist?).with(deploy_file).and_return(true)
        allow(File).to receive(:read).with(deploy_file).and_raise(StandardError.new('Read error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and continues' do
        expect(Rails.logger).to receive(:error).with(/Drift check failed/)
        scanner.send(:check_deployment_config)
      end
    end
  end

  describe '#check_gem_versions' do
    let(:app_gemfile_lock) { File.join(app.path, 'Gemfile.lock') }
    let(:golden_gemfile_lock) { File.join(DriftScanner::GOLDEN_PATH, 'Gemfile.lock') }

    context 'when Gemfile.lock files exist' do
      before do
        allow(File).to receive(:exist?).with(app_gemfile_lock).and_return(true)
        allow(File).to receive(:exist?).with(golden_gemfile_lock).and_return(true)
      end

      context 'when Rails versions differ' do
        before do
          app_content = "    rails (7.0.0)"
          golden_content = "    rails (8.0.0)"
          allow(File).to receive(:read).with(app_gemfile_lock).and_return(app_content)
          allow(File).to receive(:read).with(golden_gemfile_lock).and_return(golden_content)
        end

        it 'adds medium severity result' do
          scanner.send(:check_gem_versions)
          expect(scanner.results).to include(
            hash_including(
              scan_type: 'drift',
              severity: 'medium',
              message: /Rails version .* differs from golden_deployment/
            )
          )
        end
      end

      context 'when Rails versions match' do
        before do
          content = "    rails (8.0.0)"
          allow(File).to receive(:read).with(app_gemfile_lock).and_return(content)
          allow(File).to receive(:read).with(golden_gemfile_lock).and_return(content)
        end

        it 'does not add any results' do
          scanner.send(:check_gem_versions)
          expect(scanner.results).to be_empty
        end
      end
    end

    context 'when Gemfile.lock files do not exist' do
      before do
        allow(File).to receive(:exist?).with(app_gemfile_lock).and_return(false)
        allow(File).to receive(:exist?).with(golden_gemfile_lock).and_return(false)
      end

      it 'returns without checking' do
        scanner.send(:check_gem_versions)
        expect(scanner.results).to be_empty
      end
    end
  end

  describe '#parse_gemfile_lock' do
    it 'extracts gem versions from Gemfile.lock content' do
      content = <<~GEMFILE
        GEM
          remote: https://rubygems.org/
          specs:
            rails (8.0.0)
            rspec (3.12.0)
            capybara (3.39.0)
      GEMFILE

      gems = scanner.send(:parse_gemfile_lock, content)
      expect(gems['rails']).to eq('8.0.0')
      expect(gems['rspec']).to eq('3.12.0')
      expect(gems['capybara']).to eq('3.39.0')
    end

    it 'handles empty content' do
      gems = scanner.send(:parse_gemfile_lock, '')
      expect(gems).to eq({})
    end
  end

  describe '#check_tailwind_setup' do
    let(:production_rb) { File.join(app.path, 'config', 'environments', 'production.rb') }

    context 'when production.rb exists and has tailwindcss:build' do
      before do
        allow(File).to receive(:exist?).with(production_rb).and_return(true)
        allow(File).to receive(:read).with(production_rb).and_return('before "deploy:assets:precompile", "tailwindcss:build"')
      end

      it 'does not add any results' do
        scanner.send(:check_tailwind_setup)
        expect(scanner.results).to be_empty
      end
    end

    context 'when production.rb exists but missing tailwindcss:build' do
      before do
        allow(File).to receive(:exist?).with(production_rb).and_return(true)
        allow(File).to receive(:read).with(production_rb).and_return('# no tailwind config')
      end

      it 'adds medium severity result' do
        scanner.send(:check_tailwind_setup)
        expect(scanner.results).to include(
          hash_including(
            scan_type: 'drift',
            severity: 'medium',
            message: /Tailwind CSS build task may not be configured/
          )
        )
      end
    end

    context 'when production.rb does not exist' do
      before do
        allow(File).to receive(:exist?).with(production_rb).and_return(false)
      end

      it 'returns without checking' do
        scanner.send(:check_tailwind_setup)
        expect(scanner.results).to be_empty
      end
    end
  end

  describe '#check_path_based_routing' do
    let(:production_rb) { File.join(app.path, 'config', 'environments', 'production.rb') }

    context 'when relative_url_root is configured' do
      before do
        allow(File).to receive(:exist?).with(production_rb).and_return(true)
        allow(File).to receive(:read).with(production_rb).and_return('config.relative_url_root = "/test_app"')
      end

      it 'does not add any results' do
        scanner.send(:check_path_based_routing)
        expect(scanner.results).to be_empty
      end
    end

    context 'when relative_url_root is missing' do
      before do
        allow(File).to receive(:exist?).with(production_rb).and_return(true)
        allow(File).to receive(:read).with(production_rb).and_return('# no url root config')
      end

      it 'adds high severity result' do
        scanner.send(:check_path_based_routing)
        expect(scanner.results).to include(
          hash_including(
            scan_type: 'drift',
            severity: 'high',
            message: /Path-based routing .* not configured/
          )
        )
      end
    end
  end

  describe '#save_results' do
    let!(:old_scan) { create(:quality_scan, app: app, scan_type: 'drift') }

    before do
      scanner.instance_variable_set(:@results, [
        { scan_type: 'drift', severity: 'high', message: 'Test issue', scanned_at: Time.current }
      ])
      allow(scanner).to receive(:create_summary)
    end

    it 'deletes old drift scans' do
      expect { scanner.send(:save_results) }.to change {
        app.quality_scans.where(scan_type: 'drift').count
      }.from(1).to(1) # Old deleted, new created
    end

    it 'creates new quality scans from results' do
      scanner.send(:save_results)
      new_scan = app.quality_scans.where(scan_type: 'drift').last
      expect(new_scan.message).to eq('Test issue')
      expect(new_scan.severity).to eq('high')
    end

    it 'calls create_summary' do
      expect(scanner).to receive(:create_summary)
      scanner.send(:save_results)
    end
  end

  describe '#create_summary' do
    let!(:critical_scan) { create(:quality_scan, app: app, scan_type: 'drift', severity: 'critical') }
    let!(:high_scan) { create(:quality_scan, app: app, scan_type: 'drift', severity: 'high') }
    let!(:medium_scan) { create(:quality_scan, app: app, scan_type: 'drift', severity: 'medium') }
    let!(:low_scan) { create(:quality_scan, app: app, scan_type: 'drift', severity: 'low') }

    it 'creates or updates metric summary' do
      expect {
        scanner.send(:create_summary)
      }.to change { app.metric_summaries.where(scan_type: 'drift').count }.by(1)
    end

    it 'calculates total issues' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'drift')
      expect(summary.total_issues).to eq(4)
    end

    it 'calculates high severity count' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'drift')
      expect(summary.high_severity).to eq(2) # critical + high
    end

    it 'calculates medium severity count' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'drift')
      expect(summary.medium_severity).to eq(1)
    end

    it 'calculates low severity count' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'drift')
      expect(summary.low_severity).to eq(1)
    end

    it 'sets scanned_at to current time' do
      scanner.send(:create_summary)
      summary = app.metric_summaries.find_by(scan_type: 'drift')
      expect(summary.scanned_at).to be_within(1.second).of(Time.current)
    end
  end
end
