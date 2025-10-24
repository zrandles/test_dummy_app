module ApplicationHelper
  def status_badge_class(status)
    case status
    when "healthy"
      "bg-green-100 text-green-800"
    when "warning"
      "bg-yellow-100 text-yellow-800"
    when "critical"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def severity_badge_class(severity)
    case severity
    when "critical", "high"
      "bg-red-100 text-red-800"
    when "medium"
      "bg-yellow-100 text-yellow-800"
    when "low"
      "bg-blue-100 text-blue-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
