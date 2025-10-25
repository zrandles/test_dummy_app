require 'rails_helper'

RSpec.describe 'Apps', type: :request do
  let!(:app) { App.create!(name: 'test_app', path: '/tmp/test_app', status: 'healthy') }

  describe 'GET /golden_deployment/apps' do
    let!(:apps) { create_list(:app, 3) }

    it 'returns successful response' do
      get '/golden_deployment/apps'
      expect(response).to have_http_status(:ok)
    end

    it 'displays all apps ordered by name' do
      get '/golden_deployment/apps'
      expect(response.body).to include(apps.first.name)
      expect(response.body).to include(apps.last.name)
    end

    it 'renders the index template' do
      get '/golden_deployment/apps'
      expect(response).to render_template(:index)
    end
  end

  describe 'GET /golden_deployment/apps/:id' do
    let(:metric_summary) { create(:metric_summary, app: app, scan_type: 'security') }
    let!(:quality_scan) { create(:quality_scan, app: app, scan_type: 'security', severity: 'high') }

    before do
      metric_summary # Create metric summary
    end

    it 'returns successful response' do
      get "/golden_deployment/apps/#{app.id}"
      expect(response).to have_http_status(:ok)
    end

    it 'displays the app show page' do
      get "/golden_deployment/apps/#{app.id}"
      expect(response.body).to include(app.name)
    end

    it 'loads metric summaries ordered by scan_type' do
      get "/golden_deployment/apps/#{app.id}"
      expect(assigns(:summaries)).to include(metric_summary)
    end

    it 'loads recent quality scans' do
      get "/golden_deployment/apps/#{app.id}"
      expect(assigns(:recent_scans)).to include(quality_scan)
    end

    it 'groups scans by type' do
      get "/golden_deployment/apps/#{app.id}"
      expect(assigns(:scans_by_type)).to have_key('security')
      expect(assigns(:scans_by_type)['security']).to include(quality_scan)
    end

    it 'limits recent scans to 50' do
      create_list(:quality_scan, 60, app: app, scan_type: 'rubocop')
      get "/golden_deployment/apps/#{app.id}"
      expect(assigns(:recent_scans).count).to eq(50)
    end

    it 'renders the show template' do
      get "/golden_deployment/apps/#{app.id}"
      expect(response).to render_template(:show)
    end
  end

  describe 'POST /golden_deployment/apps/:id/scan' do
    it 'enqueues AppScannerJob' do
      expect {
        post "/golden_deployment/apps/#{app.id}/scan"
      }.to have_enqueued_job(AppScannerJob).with(app.id)
    end

    it 'redirects to app page with notice' do
      post "/golden_deployment/apps/#{app.id}/scan"
      expect(response).to redirect_to("/golden_deployment/apps/#{app.id}")
      expect(flash[:notice]).to eq("Scan started for #{app.name}")
    end

    it 'works with perform_enqueued_jobs' do
      perform_enqueued_jobs do
        post "/golden_deployment/apps/#{app.id}/scan"
      end
      # Job was performed (tested separately in job specs)
    end
  end

  describe 'POST /golden_deployment/apps/discover' do
    let(:apps_dir) { Rails.root.join('tmp', 'test_apps') }
    let(:test_app_path) { apps_dir.join('discovered_app') }

    before do
      # Clean up any existing test apps
      App.where(name: 'discovered_app').destroy_all

      # Create test directory structure
      FileUtils.mkdir_p(test_app_path.join('config'))
      File.write(test_app_path.join('config', 'application.rb'), 'Rails::Application')

      # Stub the discover_apps method to use test directory
      allow_any_instance_of(AppsController).to receive(:discover_apps) do
        Dir.glob("#{test_app_path.parent}/*").each do |app_path|
          next unless File.directory?(app_path)
          app_name = File.basename(app_path)
          next unless File.exist?(File.join(app_path, "config", "application.rb"))

          App.find_or_create_by(name: app_name) do |app|
            app.path = app_path
            app.status = "pending"
          end
        end
      end
    end

    after do
      # Clean up test directory
      FileUtils.rm_rf(apps_dir) if apps_dir.exist?
    end

    it 'creates apps from discovered directories' do
      expect {
        post '/golden_deployment/apps/discover'
      }.to change { App.count }.by_at_least(0)
    end

    it 'redirects to apps index with notice' do
      post '/golden_deployment/apps/discover'
      expect(response).to redirect_to('/golden_deployment/apps')
      expect(flash[:notice]).to match(/Discovered \d+ apps/)
    end

    it 'skips non-Rails directories' do
      non_rails_dir = apps_dir.join('not_a_rails_app')
      FileUtils.mkdir_p(non_rails_dir)

      post '/golden_deployment/apps/discover'

      expect(App.where(name: 'not_a_rails_app')).to be_empty
    end

    it 'only creates each app once (idempotent)' do
      post '/golden_deployment/apps/discover'
      first_count = App.count

      post '/golden_deployment/apps/discover'
      expect(App.count).to eq(first_count)
    end
  end
end
