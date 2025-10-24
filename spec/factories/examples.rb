FactoryBot.define do
  factory :example do
    sequence(:name) { |n| "Example Pattern #{n}" }
    status { Example::STATUSES.sample }
    category { Example::CATEGORIES.sample }
    priority { rand(1..5) }
    score { rand(0.0..100.0).round(1) }
    complexity { rand(1..5) }
    speed { rand(1..5) }
    quality { rand(1..5) }

    # Trait for creating examples with specific status
    trait :new_status do
      status { 'new' }
    end

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :completed do
      status { 'completed' }
    end

    trait :archived do
      status { 'archived' }
    end

    # Trait for creating examples with specific category
    trait :ui_pattern do
      category { 'ui_pattern' }
    end

    trait :backend_pattern do
      category { 'backend_pattern' }
    end

    trait :data_pattern do
      category { 'data_pattern' }
    end

    trait :deployment_pattern do
      category { 'deployment_pattern' }
    end

    # Trait for high-performing examples
    trait :high_performer do
      score { rand(80.0..100.0).round(1) }
      complexity { rand(1..2) }
      speed { rand(4..5) }
      quality { rand(4..5) }
    end

    # Trait for low-performing examples
    trait :low_performer do
      score { rand(0.0..20.0).round(1) }
      complexity { rand(4..5) }
      speed { rand(1..2) }
      quality { rand(1..2) }
    end

    # Trait for examples with all metrics
    trait :with_all_metrics do
      priority { rand(1..5) }
      score { rand(0.0..100.0).round(1) }
      complexity { rand(1..5) }
      speed { rand(1..5) }
      quality { rand(1..5) }
    end

    # Trait for examples with nil metrics
    trait :without_metrics do
      priority { nil }
      score { nil }
      complexity { nil }
      speed { nil }
      quality { nil }
    end
  end
end
