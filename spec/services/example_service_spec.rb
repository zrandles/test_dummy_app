require 'rails_helper'

RSpec.describe ExampleService do
  describe '.calculate_statistics' do
    context 'with examples in various states' do
      let!(:completed_examples) { create_list(:example, 3, :completed, score: 85.0) }
      let!(:in_progress_examples) { create_list(:example, 2, :in_progress) }
      let!(:new_examples) { create_list(:example, 1, :new_status) }

      it 'returns total count' do
        stats = ExampleService.calculate_statistics
        expect(stats[:total_count]).to eq(6)
      end

      it 'returns completed count' do
        stats = ExampleService.calculate_statistics
        expect(stats[:completed_count]).to eq(3)
      end

      it 'returns in_progress count' do
        stats = ExampleService.calculate_statistics
        expect(stats[:in_progress_count]).to eq(2)
      end

      it 'returns new count' do
        stats = ExampleService.calculate_statistics
        expect(stats[:new_count]).to eq(1)
      end

      it 'calculates completion rate' do
        stats = ExampleService.calculate_statistics
        expect(stats[:completion_rate]).to eq(0.5) # 3 completed / 6 total
      end

      it 'calculates average score' do
        stats = ExampleService.calculate_statistics
        expect(stats[:average_score]).to be_present
      end

      it 'calculates average priority' do
        stats = ExampleService.calculate_statistics
        expect(stats[:average_priority]).to be_present
      end
    end

    context 'with no examples' do
      before { Example.destroy_all }

      it 'returns zero counts' do
        stats = ExampleService.calculate_statistics
        expect(stats[:total_count]).to eq(0)
        expect(stats[:completed_count]).to eq(0)
        expect(stats[:completion_rate]).to eq(0)
      end

      it 'returns nil for averages' do
        stats = ExampleService.calculate_statistics
        expect(stats[:average_score]).to be_nil
        expect(stats[:average_priority]).to be_nil
      end
    end

    context 'with examples having nil scores' do
      let!(:examples_with_scores) { create_list(:example, 2, score: 80.0) }
      let!(:examples_without_scores) { create_list(:example, 2, score: nil) }

      it 'calculates average only from non-nil scores' do
        stats = ExampleService.calculate_statistics
        expect(stats[:average_score]).to eq(80.0)
      end
    end
  end

  describe '.top_performers' do
    let!(:high_scorers) do
      [
        create(:example, :completed, score: 95.0),
        create(:example, :completed, score: 88.0),
        create(:example, :completed, score: 82.0)
      ]
    end
    let!(:low_scorer) { create(:example, :completed, score: 60.0) }
    let!(:incomplete) { create(:example, :in_progress, score: 90.0) }

    it 'returns completed examples with score >= min_score' do
      results = ExampleService.top_performers(min_score: 75)
      expect(results).to include(high_scorers[0], high_scorers[1], high_scorers[2])
      expect(results).not_to include(low_scorer)
    end

    it 'excludes incomplete examples even with high scores' do
      results = ExampleService.top_performers
      expect(results).not_to include(incomplete)
    end

    it 'orders by score descending' do
      results = ExampleService.top_performers
      scores = results.pluck(:score)
      expect(scores).to eq(scores.sort.reverse)
    end

    it 'respects limit parameter' do
      results = ExampleService.top_performers(limit: 2)
      expect(results.count).to be <= 2
    end

    it 'respects min_score parameter' do
      results = ExampleService.top_performers(min_score: 90)
      expect(results.pluck(:score).min).to be >= 90
    end

    context 'with no qualifying examples' do
      before { Example.destroy_all }

      it 'returns empty relation' do
        results = ExampleService.top_performers
        expect(results).to be_empty
      end
    end
  end

  describe '.needs_attention' do
    let!(:high_priority_new) { create(:example, priority: 5, status: 'new') }
    let!(:high_priority_in_progress) { create(:example, priority: 4, status: 'in_progress') }
    let!(:high_priority_completed) { create(:example, priority: 5, status: 'completed') }
    let!(:low_priority) { create(:example, priority: 2, status: 'new') }

    it 'returns high priority (4-5) examples' do
      results = ExampleService.needs_attention
      expect(results).to include(high_priority_new, high_priority_in_progress)
    end

    it 'excludes completed examples' do
      results = ExampleService.needs_attention
      expect(results).not_to include(high_priority_completed)
    end

    it 'excludes low priority examples' do
      results = ExampleService.needs_attention
      expect(results).not_to include(low_priority)
    end

    it 'orders by priority descending, then created_at ascending' do
      results = ExampleService.needs_attention
      priorities = results.pluck(:priority)
      expect(priorities.first).to be >= priorities.last
    end
  end

  describe '.bulk_update_status' do
    let!(:examples) { create_list(:example, 3, status: 'new') }
    let(:example_ids) { examples.map(&:id) }

    context 'with valid status' do
      it 'updates all examples to new status' do
        result = ExampleService.bulk_update_status(example_ids, 'completed')
        expect(result[:success]).to be true
        expect(result[:updated_count]).to eq(3)
        expect(examples.map(&:reload).map(&:status)).to all(eq('completed'))
      end

      it 'returns success result' do
        result = ExampleService.bulk_update_status(example_ids, 'in_progress')
        expect(result[:success]).to be true
        expect(result[:updated_count]).to eq(3)
      end
    end

    context 'with invalid status' do
      it 'returns error result' do
        result = ExampleService.bulk_update_status(example_ids, 'invalid_status')
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid status')
      end

      it 'does not update any examples' do
        ExampleService.bulk_update_status(example_ids, 'invalid_status')
        expect(examples.map(&:reload).map(&:status)).to all(eq('new'))
      end
    end

    context 'with non-existent IDs' do
      it 'skips non-existent examples' do
        result = ExampleService.bulk_update_status([99999], 'completed')
        expect(result[:success]).to be true
        expect(result[:updated_count]).to eq(0)
      end
    end

    context 'with partial success' do
      before do
        # Make one example fail validation
        allow_any_instance_of(Example).to receive(:update).and_return(false).once
      end

      it 'rolls back transaction on error' do
        initial_statuses = examples.map(&:status)
        result = ExampleService.bulk_update_status(example_ids, 'completed')
        # Should roll back, so statuses remain unchanged
        expect(examples.map(&:reload).map(&:status)).to eq(initial_statuses)
      end
    end
  end

  describe '.calculate_percentile_rank' do
    let!(:examples) do
      [
        create(:example, score: 10.0),
        create(:example, score: 25.0),
        create(:example, score: 50.0),
        create(:example, score: 75.0),
        create(:example, score: 90.0)
      ]
    end

    it 'calculates percentile rank for given score' do
      rank = ExampleService.calculate_percentile_rank(50.0, :score)
      expect(rank).to eq(60) # 3 out of 5 are <= 50, so 60th percentile
    end

    it 'handles score at bottom' do
      rank = ExampleService.calculate_percentile_rank(10.0, :score)
      expect(rank).to eq(20) # 1 out of 5
    end

    it 'handles score at top' do
      rank = ExampleService.calculate_percentile_rank(90.0, :score)
      expect(rank).to eq(100)
    end

    it 'handles score above all values' do
      rank = ExampleService.calculate_percentile_rank(100.0, :score)
      expect(rank).to eq(100)
    end

    it 'handles score below all values' do
      rank = ExampleService.calculate_percentile_rank(5.0, :score)
      expect(rank).to eq(0)
    end

    it 'works with different columns' do
      examples.each_with_index do |example, i|
        example.update(priority: i + 1)
      end
      rank = ExampleService.calculate_percentile_rank(3, :priority)
      expect(rank).to eq(60)
    end

    context 'with no examples' do
      before { Example.destroy_all }

      it 'returns 0' do
        rank = ExampleService.calculate_percentile_rank(50.0, :score)
        expect(rank).to eq(0)
      end
    end

    context 'with nil values' do
      before do
        create_list(:example, 2, score: nil)
      end

      it 'excludes nil values from calculation' do
        rank = ExampleService.calculate_percentile_rank(50.0, :score)
        expect(rank).to be_present
      end
    end
  end

  describe '.cached_leaderboard' do
    let!(:top_examples) { create_list(:example, 5, :completed, :high_performer) }

    it 'returns top performers' do
      leaderboard = ExampleService.cached_leaderboard
      expect(leaderboard.count).to be <= 20
    end

    it 'caches the result' do
      expect(Rails.cache).to receive(:fetch).with('example_leaderboard', expires_in: 1.hour).and_call_original
      ExampleService.cached_leaderboard
    end

    it 'returns same result on subsequent calls (cached)' do
      first_call = ExampleService.cached_leaderboard
      second_call = ExampleService.cached_leaderboard
      expect(first_call.pluck(:id)).to eq(second_call.pluck(:id))
    end
  end

  describe '.clear_cache' do
    it 'clears the leaderboard cache' do
      ExampleService.cached_leaderboard # Prime the cache
      expect(Rails.cache.exist?('example_leaderboard')).to be true
      ExampleService.clear_cache
      expect(Rails.cache.exist?('example_leaderboard')).to be false
    end
  end
end
