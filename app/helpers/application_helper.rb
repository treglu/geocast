module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type
    when "notice" then "alert-success"
    when "alert" then "alert-warning"
    when "error" then "alert-danger"
    when "success" then "alert-success"
    when "timeout" then "d-none"
    else "alert-#{flash_type}"
    end
  end

  def large_weather_icon_url(url, size: "300")
    return unless url
    url.gsub("=medium", "=#{size}")
  end

  def pretty_date(date, dow: true)
    return unless date
    date = Date.parse(date) if date.is_a? String
    if dow
      date.strftime("%A, %b %-d")
    else
      date.strftime("%B %-d")
    end
  end
end
