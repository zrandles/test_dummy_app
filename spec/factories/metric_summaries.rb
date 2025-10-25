FactoryBot.define do
  factory :metric_summary do
    association :app
    scan_type { %w[security static_analysis rubocop test_coverage drift].sample }
    total_issues { rand(0..50) }
    high_severity { rand(0..10) }
    medium_severity { rand(0..20) }
    low_severity { rand(0..20) }
    scanned_at { Time.current }
    metadata { {} }

    trait :security do
      scan_type { 'security' }
    end

    trait :static_analysis do
      scan_type { 'static_analysis' }
    end

    trait :rubocop do
      scan_type { 'rubocop' }
    end

    trait :test_coverage do
      scan_type { 'test_coverage' }
    end

    trait :drift do
      scan_type { 'drift' }
    end

    trait :healthy do
      total_issues { 0 }
      high_severity { 0 }
      medium_severity { 0 }
      low_severity { 0 }
    end

    trait :critical do
      total_issues { rand(10..50) }
      high_severity { rand(5..15) }
      medium_severity { rand(5..20) }
    end

    trait :warning do
      total_issues { rand(6..15) }
      high_severity { 0 }
      medium_severity { rand(6..15) }
    end

    trait :recent do
      scanned_at { 1.day.ago }
    end

    trait :old do
      scanned_at { 30.days.ago }
    end
  end
end
