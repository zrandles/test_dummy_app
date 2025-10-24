require 'rails_helper'

RSpec.describe Example, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:status).in_array(Example::STATUSES) }
    it { should validate_inclusion_of(:category).in_array(Example::CATEGORIES).allow_nil }

    context 'priority validation' do
      it { should validate_numericality_of(:priority).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5).allow_nil }

      it 'allows nil priority' do
        example = build(:example, priority: nil)
        expect(example).to be_valid
      end

      it 'allows valid priority values' do
        (1..5).each do |priority|
          example = build(:example, priority: priority)
          expect(example).to be_valid
        end
      end

      it 'rejects priority below 1' do
        example = build(:example, priority: 0)
        expect(example).not_to be_valid
        expect(example.errors[:priority]).to be_present
      end

      it 'rejects priority above 5' do
        example = build(:example, priority: 6)
        expect(example).not_to be_valid
        expect(example.errors[:priority]).to be_present
      end
    end

    context 'score validation' do
      it { should validate_numericality_of(:score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100).allow_nil }

      it 'allows nil score' do
        example = build(:example, score: nil)
        expect(example).to be_valid
      end

      it 'allows valid score values' do
        [0, 25.5, 50, 75.3, 100].each do |score|
          example = build(:example, score: score)
          expect(example).to be_valid
        end
      end

      it 'rejects score below 0' do
        example = build(:example, score: -1)
        expect(example).not_to be_valid
        expect(example.errors[:score]).to be_present
      end

      it 'rejects score above 100' do
        example = build(:example, score: 101)
        expect(example).not_to be_valid
        expect(example.errors[:score]).to be_present
      end
    end

    context 'complexity validation' do
      it { should validate_numericality_of(:complexity).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5).allow_nil }

      it 'allows nil complexity' do
        example = build(:example, complexity: nil)
        expect(example).to be_valid
      end

      it 'allows valid complexity values' do
        (1..5).each do |complexity|
          example = build(:example, complexity: complexity)
          expect(example).to be_valid
        end
      end

      it 'rejects complexity below 1' do
        example = build(:example, complexity: 0)
        expect(example).not_to be_valid
      end

      it 'rejects complexity above 5' do
        example = build(:example, complexity: 6)
        expect(example).not_to be_valid
      end
    end

    context 'speed validation' do
      it { should validate_numericality_of(:speed).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5).allow_nil }
    end

    context 'quality validation' do
      it { should validate_numericality_of(:quality).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5).allow_nil }
    end
  end

  describe 'constants' do
    it 'has correct STATUSES' do
      expect(Example::STATUSES).to eq(%w[new in_progress completed archived])
    end

    it 'has correct CATEGORIES' do
      expect(Example::CATEGORIES).to eq(%w[ui_pattern backend_pattern data_pattern deployment_pattern])
    end
  end

  describe '#average_metrics' do
    context 'when all metrics are present' do
      it 'calculates the average correctly' do
        example = create(:example, complexity: 3, speed: 4, quality: 5)
        expect(example.average_metrics).to eq(4.0)
      end

      it 'rounds to one decimal place' do
        example = create(:example, complexity: 2, speed: 3, quality: 4)
        expect(example.average_metrics).to eq(3.0)
      end

      it 'handles uneven averages' do
        example = create(:example, complexity: 1, speed: 2, quality: 3)
        expect(example.average_metrics).to eq(2.0)
      end
    end

    context 'when some metrics are nil' do
      it 'calculates average from available metrics' do
        example = create(:example, complexity: 4, speed: nil, quality: 5)
        expect(example.average_metrics).to eq(4.5)
      end

      it 'works with only one metric' do
        example = create(:example, complexity: 3, speed: nil, quality: nil)
        expect(example.average_metrics).to eq(3.0)
      end
    end

    context 'when all metrics are nil' do
      it 'returns nil' do
        example = create(:example, complexity: nil, speed: nil, quality: nil)
        expect(example.average_metrics).to be_nil
      end
    end
  end

  describe '#new?' do
    it 'returns true when status is new' do
      example = create(:example, :new_status)
      expect(example.new?).to be true
    end

    it 'returns false when status is not new' do
      example = create(:example, :completed)
      expect(example.new?).to be false
    end
  end

  describe '#completed?' do
    it 'returns true when status is completed' do
      example = create(:example, :completed)
      expect(example.completed?).to be true
    end

    it 'returns false when status is not completed' do
      example = create(:example, :new_status)
      expect(example.completed?).to be false
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      example = build(:example)
      expect(example).to be_valid
    end

    it 'creates examples with different names' do
      example1 = create(:example)
      example2 = create(:example)
      expect(example1.name).not_to eq(example2.name)
    end

    context 'traits' do
      it 'creates high performer examples' do
        example = create(:example, :high_performer)
        expect(example.score).to be >= 80
        expect(example.quality).to be >= 4
      end

      it 'creates low performer examples' do
        example = create(:example, :low_performer)
        expect(example.score).to be <= 20
        expect(example.quality).to be <= 2
      end

      it 'creates examples without metrics' do
        example = create(:example, :without_metrics)
        expect(example.priority).to be_nil
        expect(example.score).to be_nil
        expect(example.complexity).to be_nil
      end
    end
  end
end
