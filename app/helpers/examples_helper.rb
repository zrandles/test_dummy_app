module ExamplesHelper
  # Status badge with color coding
  # new (blue), in_progress (yellow), completed (green), archived (gray)
  #
  # Usage:
  #   <%= status_badge(example.status) %>
  def status_badge(status)
    colors = {
      'new' => 'bg-blue-100 text-blue-700',
      'in_progress' => 'bg-yellow-100 text-yellow-700',
      'completed' => 'bg-green-100 text-green-700',
      'archived' => 'bg-gray-100 text-gray-700'
    }

    labels = {
      'new' => 'New',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'archived' => 'Archived'
    }

    color_class = colors[status] || 'bg-gray-100 text-gray-700'
    label = labels[status] || status.to_s.titleize

    content_tag(:span, label, class: "px-2 py-1 text-xs rounded #{color_class}")
  end

  # Category badge with color coding
  # ui_pattern (purple), backend_pattern (green), data_pattern (blue), deployment_pattern (orange)
  #
  # Usage:
  #   <%= category_badge(example.category) %>
  def category_badge(category)
    colors = {
      'ui_pattern' => 'bg-purple-100 text-purple-700',
      'backend_pattern' => 'bg-green-100 text-green-700',
      'data_pattern' => 'bg-blue-100 text-blue-700',
      'deployment_pattern' => 'bg-orange-100 text-orange-700'
    }

    labels = {
      'ui_pattern' => 'UI',
      'backend_pattern' => 'Backend',
      'data_pattern' => 'Data',
      'deployment_pattern' => 'Deploy'
    }

    color_class = colors[category] || 'bg-gray-100 text-gray-700'
    label = labels[category] || category.to_s.titleize

    content_tag(:span, label, class: "px-2 py-1 text-xs rounded #{color_class}")
  end

  # Format numeric score with highlighting for high values
  # >= 90: green, >= 75: yellow, < 75: gray
  #
  # Usage:
  #   <%= format_score(example.score) %>
  def format_score(score)
    return content_tag(:span, '-', class: 'text-gray-400') if score.nil?

    color_class = if score >= 90
                    'text-green-700 font-bold'
                  elsif score >= 75
                    'text-yellow-700'
                  else
                    'text-gray-600'
                  end

    content_tag(:span, score.round(1), class: color_class)
  end

  # Format priority (1-5) with visual indicator
  # 5: critical (red), 4: high (orange), 3: medium (yellow), 2: low (blue), 1: minimal (gray)
  #
  # Usage:
  #   <%= format_priority(example.priority) %>
  def format_priority(priority)
    return content_tag(:span, '-', class: 'text-gray-400') if priority.nil?

    colors = {
      5 => 'text-red-700 font-bold',
      4 => 'text-orange-700 font-semibold',
      3 => 'text-yellow-700',
      2 => 'text-blue-700',
      1 => 'text-gray-600'
    }

    color_class = colors[priority] || 'text-gray-600'
    content_tag(:span, priority, class: color_class)
  end

  # Highlight cell if value is in top percentile
  # Used for table cell highlighting
  #
  # Usage:
  #   <td class="<%= percentile_class(value, 'score', @percentiles) %>">
  def percentile_class(value, column, percentiles)
    return '' if value.nil? || percentiles.nil? || percentiles[column].nil?

    # Calculate percentile rank
    values = percentiles[column]
    percentile = calculate_percentile(value.to_f, values)

    if percentile >= 95
      'bg-green-100 font-bold'
    elsif percentile >= 90
      'bg-green-50'
    elsif percentile >= 75
      'bg-yellow-50'
    else
      ''
    end
  end

  private

  # Calculate percentile rank for a value
  def calculate_percentile(value, percentile_hash)
    # percentile_hash is { 0 => val, 5 => val, ..., 100 => val }
    # Find which percentile the value falls into
    percentile_hash.each do |p, v|
      return p if value <= v
    end
    100  # Value is above 100th percentile
  end
end
