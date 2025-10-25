FactoryBot.define do
  factory :app do
    sequence(:name) { |n| "app_#{n}" }
    sequence(:path) { |n| "/Users/zac/zac_ecosystem/apps/app_#{n}" }
    status { %w[healthy warning critical pending].sample }
    last_scanned_at { Time.current }

    trait :healthy do
      status { 'healthy' }
    end

    trait :warning do
      status { 'warning' }
    end

    trait :critical do
      status { 'critical' }
    end

    trait :pending do
      status { 'pending' }
      last_scanned_at { nil }
    end

    trait :recently_scanned do
      last_scanned_at { 1.hour.ago }
    end

    trait :needs_scan do
      last_scanned_at { 2.days.ago }
    end

    trait :with_quality_scans do
      after(:create) do |app|
        create_list(:quality_scan, 3, app: app)
      end
    end

    trait :with_metric_summaries do
      after(:create) do |app|
        create(:metric_summary, app: app, scan_type: 'security')
        create(:metric_summary, app: app, scan_type: 'rubocop')
      end
    end
  end
end
