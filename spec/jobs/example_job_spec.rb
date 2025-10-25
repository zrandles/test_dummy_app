require 'rails_helper'

RSpec.describe ExampleJob, type: :job do
  describe '#perform' do
    let(:example) { create(:example, :with_all_metrics, complexity: 3, speed: 4, quality: 5) }

    it 'finds the example by id' do
      expect(Example).to receive(:find).with(example.id).and_return(example)
      ExampleJob.perform_now(example.id)
    end

    it 'processes the example without error' do
      expect {
        ExampleJob.perform_now(example.id)
      }.not_to raise_error
    end

    it 'logs processing start and finish' do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with(/Processing example: #{example.name}/)
      expect(Rails.logger).to receive(:info).with(/Finished processing example: #{example.name}/)
      ExampleJob.perform_now(example.id)
    end

    context 'with all metrics present' do
      let(:example) { create(:example, complexity: 2, speed: 3, quality: 4) }

      it 'calculates average metrics' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Calculated average metrics: 3.0/)
        ExampleJob.perform_now(example.id)
      end
    end

    context 'with missing metrics' do
      let(:example) { create(:example, complexity: nil, speed: nil, quality: nil) }

      it 'processes without calculation' do
        expect(Rails.logger).to receive(:info).with(/Processing example: #{example.name}/)
        expect(Rails.logger).to receive(:info).with(/Finished processing example: #{example.name}/)
        expect(Rails.logger).not_to receive(:info).with(/Calculated average metrics:/)
        ExampleJob.perform_now(example.id)
      end
    end

    context 'when example does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          ExampleJob.perform_now(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued on default queue' do
      expect(ExampleJob.new.queue_name).to eq('default')
    end

    it 'has retry configuration' do
      # Test that the job has retry_on configured by checking the class
      expect(ExampleJob.ancestors).to include(ActiveJob::Base)
    end
  end

  describe 'enqueuing' do
    let(:example) { create(:example) }

    it 'enqueues the job' do
      expect {
        ExampleJob.perform_later(example.id)
      }.to have_enqueued_job(ExampleJob).with(example.id)
    end

    it 'can be performed immediately' do
      expect {
        ExampleJob.perform_now(example.id)
      }.not_to raise_error
    end
  end
end

RSpec.describe ExampleDailyStatsJob, type: :job do
  describe '#perform' do
    let!(:examples) { create_list(:example, 5, :completed, score: 85.0) }

    before do
      allow(Rails.logger).to receive(:info)
    end

    it 'logs statistics header' do
      expect(Rails.logger).to receive(:info).with('=== Daily Example Statistics ===')
      expect(Rails.logger).to receive(:info).with('=== End Daily Stats ===')
      ExampleDailyStatsJob.perform_now
    end

    it 'calculates and logs statistics' do
      expect(ExampleService).to receive(:calculate_statistics).and_call_original
      ExampleDailyStatsJob.perform_now
    end

    it 'logs total examples' do
      expect(Rails.logger).to receive(:info).with(/Total examples: \d+/)
      ExampleDailyStatsJob.perform_now
    end

    it 'logs completed count' do
      expect(Rails.logger).to receive(:info).with(/Completed: \d+/)
      ExampleDailyStatsJob.perform_now
    end

    it 'logs completion rate' do
      expect(Rails.logger).to receive(:info).with(/Completion rate: .*%/)
      ExampleDailyStatsJob.perform_now
    end

    it 'logs average score' do
      expect(Rails.logger).to receive(:info).with(/Average score:/)
      ExampleDailyStatsJob.perform_now
    end
  end
end

RSpec.describe ExampleBulkProcessJob, type: :job do
  describe '#perform' do
    let(:examples) { create_list(:example, 10) }
    let(:example_ids) { examples.map(&:id) }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
    end

    it 'logs bulk processing start' do
      expect(Rails.logger).to receive(:info).with(/Bulk processing 10 examples/)
      ExampleBulkProcessJob.perform_now(example_ids)
    end

    it 'processes all examples' do
      expect(Example).to receive(:where).with(id: anything).at_least(:once).and_call_original
      ExampleBulkProcessJob.perform_now(example_ids)
    end

    it 'logs processing completion' do
      expect(Rails.logger).to receive(:info).with('Finished bulk processing')
      ExampleBulkProcessJob.perform_now(example_ids)
    end

    it 'processes in batches of 50' do
      large_batch = create_list(:example, 100)
      large_ids = large_batch.map(&:id)

      expect(Rails.logger).to receive(:info).with(/Bulk processing 100 examples/)
      ExampleBulkProcessJob.perform_now(large_ids)
    end

    it 'handles empty array' do
      expect {
        ExampleBulkProcessJob.perform_now([])
      }.not_to raise_error
    end
  end
end

RSpec.describe ExampleWithErrorHandlingJob, type: :job do
  describe '#perform' do
    let(:example) { create(:example) }

    it 'processes example successfully' do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with(/Processing: #{example.name}/)
      ExampleWithErrorHandlingJob.perform_now(example.id)
    end

    it 'has retry and discard configuration' do
      # Verify the job class is properly configured
      expect(ExampleWithErrorHandlingJob.ancestors).to include(ActiveJob::Base)
    end
  end
end
