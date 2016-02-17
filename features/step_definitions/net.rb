Then /^a web server should be available via the(?: "(.+?)")? route$/ do |route_name|
  @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

Given /^I wait(?: up to ([0-9]+) seconds)? for a server to become available via the(?: "(.+?)")? route$/ do |seconds, route_name|
  @result = route(route_name).wait_http_accessible(by: user, timeout: seconds)

  unless @result[:success]
    logger.error(@result[:response])
    # you may notice now `route` refers to last called route,
    #   i.e. route(route_name)
    raise "error openning web server on route '#{route.name}'"
  end
end

When /^I open web server via the(?: "(.+?)")? route$/ do |route_name|
  @result = CucuShift::Http.get(url: "http://" + route(route_name).dns(by: user))
end
When /^I open web server via the(?: "(.+?)")? url$/ do |url|
  @result = CucuShift::Http.get(url: url)
end

When /^I download a file from "(.+?)"$/ do |url|
  @result = CucuShift::Http.get(url: url)
  if @result[:success]
    file_name = File.basename(URI.parse(url).path)
    File.write(file_name, @result[:response])
    @result[:file_name] = file_name
    @result[:abs_path] = File.absolute_path(file_name)
  else
    raise "Failed to download file from #{url} with HTTP status #{@result[:exitstatus]}"
  end
end

# this step simply delegates to the Http.request method;
# all options are acepted in the form of a YAML or a JSON hash where each
#   option correspond to an option of the said method.
# Example usage:
# When I perform the HTTP request:
#   """
#   :url: <%= env.api_endpoint_url %>/
#   :method: :get
#   :headers:
#     :accept: text/html
#   :max_redirects: 0
#   """
When /^I perform the HTTP request:$/ do |yaml_request|
  @result = CucuShift::Http.request(YAML.load yaml_request)
end