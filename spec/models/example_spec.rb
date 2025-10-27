require 'rails_helper'

RSpec.describe Example, type: :model do
  describe 'validations' do
    it 'requires a name' do
      example = Example.new(name: nil, status: 'new')
      expect(example).not_to be_valid
      expect(example.errors[:name]).to include("can't be blank")
    end

    it 'requires status to be one of the allowed values' do
      example = Example.new(name: 'Test', status: 'invalid_status')
      expect(example).not_to be_valid
      expect(example.errors[:status]).to include('is not included in the list')
    end

    it 'accepts valid statuses' do
      Example::STATUSES.each do |status|
        example = Example.new(name: 'Test', status: status)
        expect(example).to be_valid
      end
    end

    it 'requires category to be one of the allowed values when present' do
      example = Example.new(name: 'Test', status: 'new', category: 'invalid_category')
      expect(example).not_to be_valid
      expect(example.errors[:category]).to include('is not included in the list')
    end

    it 'accepts valid categories' do
      Example::CATEGORIES.each do |category|
        example = Example.new(name: 'Test', status: 'new', category: category)
        expect(example).to be_valid
      end
    end

    it 'allows nil category' do
      example = Example.new(name: 'Test', status: 'new', category: nil)
      expect(example).to be_valid
    end

    describe 'priority validation' do
      it 'rejects values less than 1' do
        example = Example.new(name: 'Test', status: 'new', priority: 0)
        expect(example).not_to be_valid
        expect(example.errors[:priority]).to include('must be greater than or equal to 1')
      end

      it 'rejects values greater than 5' do
        example = Example.new(name: 'Test', status: 'new', priority: 6)
        expect(example).not_to be_valid
        expect(example.errors[:priority]).to include('must be less than or equal to 5')
      end

      it 'accepts values from 1 to 5' do
        (1..5).each do |priority|
          example = Example.new(name: 'Test', status: 'new', priority: priority)
          expect(example).to be_valid
        end
      end

      it 'rejects non-integer values' do
        example = Example.new(name: 'Test', status: 'new', priority: 2.5)
        expect(example).not_to be_valid
        expect(example.errors[:priority]).to include('must be an integer')
      end
    end

    describe 'score validation' do
      it 'rejects values less than 0' do
        example = Example.new(name: 'Test', status: 'new', score: -1)
        expect(example).not_to be_valid
        expect(example.errors[:score]).to include('must be greater than or equal to 0')
      end

      it 'rejects values greater than 100' do
        example = Example.new(name: 'Test', status: 'new', score: 101)
        expect(example).not_to be_valid
        expect(example.errors[:score]).to include('must be less than or equal to 100')
      end

      it 'accepts decimal values' do
        example = Example.new(name: 'Test', status: 'new', score: 75.5)
        expect(example).to be_valid
      end

      it 'accepts boundary values' do
        [0, 100].each do |score|
          example = Example.new(name: 'Test', status: 'new', score: score)
          expect(example).to be_valid
        end
      end
    end

    describe 'complexity validation' do
      it 'requires integer values' do
        example = Example.new(name: 'Test', status: 'new', complexity: 2.5)
        expect(example).not_to be_valid
        expect(example.errors[:complexity]).to include('must be an integer')
      end

      it 'requires values between 1 and 5' do
        example = Example.new(name: 'Test', status: 'new', complexity: 0)
        expect(example).not_to be_valid

        example = Example.new(name: 'Test', status: 'new', complexity: 6)
        expect(example).not_to be_valid
      end
    end

    describe 'speed validation' do
      it 'requires integer values' do
        example = Example.new(name: 'Test', status: 'new', speed: 3.7)
        expect(example).not_to be_valid
        expect(example.errors[:speed]).to include('must be an integer')
      end

      it 'requires values between 1 and 5' do
        example = Example.new(name: 'Test', status: 'new', speed: 0)
        expect(example).not_to be_valid

        example = Example.new(name: 'Test', status: 'new', speed: 6)
        expect(example).not_to be_valid
      end
    end

    describe 'quality validation' do
      it 'requires integer values' do
        example = Example.new(name: 'Test', status: 'new', quality: 4.2)
        expect(example).not_to be_valid
        expect(example.errors[:quality]).to include('must be an integer')
      end

      it 'requires values between 1 and 5' do
        example = Example.new(name: 'Test', status: 'new', quality: 0)
        expect(example).not_to be_valid

        example = Example.new(name: 'Test', status: 'new', quality: 6)
        expect(example).not_to be_valid
      end
    end
  end

  describe '#average_metrics' do
    it 'returns nil when no metrics are present' do
      example = Example.new(name: 'Test', status: 'new')
      expect(example.average_metrics).to be_nil
    end

    it 'calculates average when all metrics are present' do
      example = Example.new(name: 'Test', status: 'new', complexity: 3, speed: 4, quality: 5)
      expect(example.average_metrics).to eq(4.0)
    end

    it 'calculates average when some metrics are present' do
      example = Example.new(name: 'Test', status: 'new', complexity: 2, speed: 4, quality: nil)
      expect(example.average_metrics).to eq(3.0)
    end

    it 'rounds to one decimal place' do
      example = Example.new(name: 'Test', status: 'new', complexity: 2, speed: 3, quality: 3)
      expect(example.average_metrics).to eq(2.7)
    end

    it 'handles single metric' do
      example = Example.new(name: 'Test', status: 'new', complexity: 5, speed: nil, quality: nil)
      expect(example.average_metrics).to eq(5.0)
    end
  end

  describe '#new?' do
    it 'returns true when status is new' do
      example = Example.new(name: 'Test', status: 'new')
      expect(example.new?).to be true
    end

    it 'returns false when status is not new' do
      example = Example.new(name: 'Test', status: 'completed')
      expect(example.new?).to be false
    end
  end

  describe '#completed?' do
    it 'returns true when status is completed' do
      example = Example.new(name: 'Test', status: 'completed')
      expect(example.completed?).to be true
    end

    it 'returns false when status is not completed' do
      example = Example.new(name: 'Test', status: 'new')
      expect(example.completed?).to be false
    end
  end

  describe 'creation' do
    it 'can be created with minimal attributes' do
      example = Example.create(name: 'Test Example', status: 'new')
      expect(example).to be_persisted
      expect(example.name).to eq('Test Example')
      expect(example.status).to eq('new')
    end

    it 'can be created with all attributes' do
      example = Example.create(
        name: 'Full Example',
        status: 'in_progress',
        category: 'ui_pattern',
        description: 'A detailed description',
        priority: 3,
        score: 75.5,
        complexity: 4,
        speed: 3,
        quality: 5
      )
      expect(example).to be_persisted
      expect(example.category).to eq('ui_pattern')
      expect(example.priority).to eq(3)
      expect(example.score).to eq(75.5)
      expect(example.complexity).to eq(4)
      expect(example.speed).to eq(3)
      expect(example.quality).to eq(5)
    end
  end
end
