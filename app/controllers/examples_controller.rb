class ExamplesController < ApplicationController
  # Homepage: advanced table with filtering
  def index
    @examples = Example.all.order(:name)
    @percentile_values = calculate_percentile_values
  end

  # Show individual pattern with full description
  def show
    @example = Example.find(params[:id])
  end

  private

  # Calculate percentile values for all filterable columns
  # Returns hash of { column_name => { 0 => value, 5 => value, ..., 100 => value } }
  #
  # These values power the slider markers showing what numeric values correspond to
  # each percentile. For example, if the 90th percentile for 'score' is 85, then
  # 90% of examples have a score <= 85.
  #
  # Pattern from bull_attributes app - production-tested with 70+ columns
  def calculate_percentile_values
    # List of filterable numeric columns (matches filter_controller.js)
    filterable_columns = %w[
      priority score complexity speed quality average_metrics
    ]

    percentiles = {}

    filterable_columns.each do |column|
      # Get all non-null values, sorted ascending
      values = Example.where.not(column => nil)
                      .order(column)
                      .pluck(column)
                      .map(&:to_f)

      next if values.empty?

      # Calculate value at each 5th percentile (0, 5, 10, ..., 95, 100)
      # This gives us 21 reference points for the slider
      percentiles[column] = {}
      (0..100).step(5).each do |p|
        # Find the value at this percentile
        index = ((values.length - 1) * p / 100.0).round
        percentiles[column][p] = values[index].round(2)
      end
    end

    percentiles
  end
end
