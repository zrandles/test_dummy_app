require 'rails_helper'

RSpec.describe 'Dashboard', type: :request do
  describe 'GET /golden_deployment/dashboard' do
    let!(:healthy_apps) { create_list(:app, 2, :healthy) }
    let!(:warning_app) { create(:app, :warning) }
    let!(:critical_app) { create(:app, :critical) }
    let!(:quality_scans) do
      [
        create(:quality_scan, app: critical_app, severity: 'critical'),
        create(:quality_scan, app: warning_app, severity: 'high'),
        create(:quality_scan, app: healthy_apps.first, severity: 'medium')
      ]
    end

    it 'returns successful response' do
      get '/golden_deployment/dashboard'
      expect(response).to have_http_status(:ok)
    end

    it 'renders the index template' do
      get '/golden_deployment/dashboard'
      expect(response).to render_template(:index)
    end

    it 'loads all apps ordered by name' do
      get '/golden_deployment/dashboard'
      expect(assigns(:apps).pluck(:name)).to eq(App.order(:name).pluck(:name))
    end

    it 'calculates total app count' do
      get '/golden_deployment/dashboard'
      expect(assigns(:total_apps)).to eq(5)
    end

    it 'calculates critical app count' do
      get '/golden_deployment/dashboard'
      expect(assigns(:critical_apps)).to eq(1)
    end

    it 'calculates warning app count' do
      get '/golden_deployment/dashboard'
      expect(assigns(:warning_apps)).to eq(1)
    end

    it 'calculates total issues count' do
      get '/golden_deployment/dashboard'
      expect(assigns(:total_issues)).to eq(QualityScan.count)
    end

    it 'calculates critical issues count' do
      get '/golden_deployment/dashboard'
      expect(assigns(:critical_issues)).to eq(2) # critical + high severity
    end

    it 'loads recent scans' do
      get '/golden_deployment/dashboard'
      expect(assigns(:recent_scans)).to be_present
      expect(assigns(:recent_scans).count).to be <= 10
    end

    it 'orders recent scans by scanned_at descending' do
      get '/golden_deployment/dashboard'
      scans = assigns(:recent_scans)
      expect(scans.first.scanned_at).to be >= scans.last.scanned_at if scans.count > 1
    end

    it 'includes associated apps in recent scans' do
      get '/golden_deployment/dashboard'
      expect(assigns(:recent_scans).first.app).to be_present
    end

    context 'with many scans' do
      before do
        create_list(:quality_scan, 20, app: healthy_apps.first)
      end

      it 'limits recent scans to 10' do
        get '/golden_deployment/dashboard'
        expect(assigns(:recent_scans).count).to eq(10)
      end
    end

    context 'with no apps' do
      before do
        App.destroy_all
      end

      it 'handles empty state gracefully' do
        get '/golden_deployment/dashboard'
        expect(response).to have_http_status(:ok)
        expect(assigns(:total_apps)).to eq(0)
        expect(assigns(:critical_apps)).to eq(0)
        expect(assigns(:warning_apps)).to eq(0)
      end
    end
  end
end
