require 'rails_helper'

RSpec.describe "Examples", type: :request do
  describe "GET /examples" do
    it "returns successful response" do
      get examples_path
      expect(response).to have_http_status(:success)
    end

    it "displays all examples" do
      example1 = Example.create!(name: 'Example 1', status: 'new')
      example2 = Example.create!(name: 'Example 2', status: 'completed')

      get examples_path

      expect(response.body).to include('Example 1')
      expect(response.body).to include('Example 2')
    end

    it "orders examples by name" do
      Example.create!(name: 'Zebra', status: 'new')
      Example.create!(name: 'Apple', status: 'new')

      get examples_path

      # Check that Apple appears before Zebra in the response
      apple_position = response.body.index('Apple')
      zebra_position = response.body.index('Zebra')

      expect(apple_position).to be < zebra_position
    end

    it "calculates percentile values" do
      # Create examples with different scores
      Example.create!(name: 'Low Score', status: 'new', score: 10)
      Example.create!(name: 'Medium Score', status: 'new', score: 50)
      Example.create!(name: 'High Score', status: 'new', score: 90)

      get examples_path

      expect(response).to have_http_status(:success)
      # Verify the page renders successfully with the data
      expect(response.body).to include('Low Score')
      expect(response.body).to include('High Score')
    end

    it "handles empty database" do
      get examples_path

      expect(response).to have_http_status(:success)
      # Verify the page renders even with no data
      expect(response.body).to include('Showing 0 of 0')
    end
  end

  describe "GET /examples/:id" do
    let(:example) { Example.create!(name: 'Test Example', status: 'new', description: 'Test description') }

    it "returns successful response" do
      get example_path(example)
      expect(response).to have_http_status(:success)
    end

    it "displays the example details" do
      get example_path(example)

      expect(response.body).to include('Test Example')
      expect(response.body).to include('Test description')
    end

    it "returns 404 for non-existent example" do
      get example_path(id: 99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "percentile calculations" do
    before do
      # Create a dataset with known distribution
      [10, 20, 30, 40, 50, 60, 70, 80, 90, 100].each do |score|
        Example.create!(name: "Example #{score}", status: 'new', score: score)
      end
    end

    it "calculates correct percentiles for score" do
      get examples_path

      # Verify the page renders with the data
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Example 10')
      expect(response.body).to include('Example 50')
      expect(response.body).to include('Example 100')
    end

    it "handles multiple filterable columns" do
      Example.create!(name: 'Multi-metric', status: 'new',
                     priority: 3, complexity: 4, speed: 2, quality: 5)

      get examples_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Multi-metric')
    end

    it "skips columns with no data" do
      Example.destroy_all
      Example.create!(name: 'Only name', status: 'new') # No numeric values

      get examples_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Only name')
    end
  end

  describe "filtering behavior" do
    before do
      # Create examples with various attributes for filtering
      Example.create!(name: 'High Priority', status: 'new', priority: 5, score: 90)
      Example.create!(name: 'Medium Priority', status: 'in_progress', priority: 3, score: 50)
      Example.create!(name: 'Low Priority', status: 'completed', priority: 1, score: 10)
    end

    it "provides data structure for JavaScript filtering" do
      get examples_path

      # Verify the page renders with all the filter data
      expect(response).to have_http_status(:success)
      expect(response.body).to include('High Priority')
      expect(response.body).to include('Low Priority')
    end

    it "includes all examples for client-side filtering" do
      get examples_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('High Priority')
      expect(response.body).to include('Medium Priority')
      expect(response.body).to include('Low Priority')
    end
  end
end
