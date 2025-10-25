FactoryBot.define do
  factory :quality_scan do
    association :app
    scan_type { QualityScan::SCAN_TYPES.sample }
    severity { QualityScan::SEVERITIES.sample }
    message { "Test quality scan issue" }
    file_path { "app/models/example.rb" }
    line_number { rand(1..100) }
    scanned_at { Time.current }

    trait :security do
      scan_type { 'security' }
    end

    trait :static_analysis do
      scan_type { 'static_analysis' }
    end

    trait :rubocop do
      scan_type { 'rubocop' }
    end

    trait :drift do
      scan_type { 'drift' }
    end

    trait :critical do
      severity { 'critical' }
    end

    trait :high do
      severity { 'high' }
    end

    trait :medium do
      severity { 'medium' }
    end

    trait :low do
      severity { 'low' }
    end

    trait :info do
      severity { 'info' }
    end

    trait :recent do
      scanned_at { 1.day.ago }
    end

    trait :old do
      scanned_at { 30.days.ago }
    end
  end
end
