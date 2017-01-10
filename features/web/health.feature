Feature: Health related feature on web console
  # @author: xxia@redhat.com
  # @case_id: 522098
  Scenario Outline: Check, set and remove readiness and liveness probe for dc and standalone rc in web
    # One case, 2 scenarios: dc and standalone rc
    Given I have a project
    When I run the :create client command with:
      | f    |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<kind>-with-two-containers.yaml |
    Then the step should succeed
    
    Given a pod becomes ready with labels:
      | run |
    When I perform the :<action_name> web console action with:
      | project_name   | <%= project.name %> |
      | <kind>_name    | <resource_name>     |
    Then the step should succeed

    When I run the :check_health_alert web console action
    Then the step should succeed

    When I run the :goto_health_check_page web console action
    Then the step should succeed
    # Add readiness probe of http type in container #1
    When I perform the :add_http_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | readiness   |
      | probe_type     | HTTP        |
      | path           | /healthz    |
      | port           | 8080        |
    Then the step should succeed
    # Add readiness probe of command type in container #2
    When I perform the :add_command_probe web console action with:
      | container_name | <cont_2>          |
      | health_kind    | readiness         |
      | probe_type     | Container Command |
      | command_arg    | ls                |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | <cont_2>          |
      | health_kind    | readiness         |
      | command_arg    | /etc              |
    Then the step should succeed

    # Add liveness probe of socket type in container #1
    When I perform the :add_socket_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | liveness    |
      | probe_type     | TCP Socket  |
      | port           | 8080        |
    Then the step should succeed

    When I run the :click_save_button web console action
    Then the step should succeed

    # Check above save takes effect via CLI
    # Need wait because auto step interval is too fast
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | <kind>             |
      | resource_name | <resource_name>    |
      | o             | yaml               |
    Then the step should succeed
    And the output should contain "nessProbe"
    """

    Then the expression should be true> h = @result[:parsed]['spec']['template']['spec']['containers'][0]; h1 = h['readinessProbe']['httpGet']; h2 = h['livenessProbe']; '/healthz' == h1['path'] and 8080 == h1['port'] and 8080 == h2['tcpSocket']['port']
    And the expression should be true> ['ls', '/etc'] == @result[:parsed]['spec']['template']['spec']['containers'][1]['readinessProbe']['exec']['command']

    # Was on DC/RC page after above Save
    When I perform the :check_health_probe web console action with:
      | container_name   | <cont_1>                                   |
      | readiness_probe  | Readiness Probe: GET /healthz on port 8080 |
      | liveness_probe   | Liveness Probe: Open socket on port 8080   |
    Then the step should succeed
    When I perform the :check_health_probe web console action with:
      | container_name   | <cont_2>                                   |
      | readiness_probe  | Readiness Probe: ls /etc                   |
      | liveness_probe   |                                            |
    Then the step should succeed

    # Below remove probes.
    # Before do remove operation, wait some time so that the DC/RC update is done.
    # Otherwise next Save operation may FAIL with error in page like 'the object has
    # been modified; please apply your changes to the latest version and try again'.
    # Use step '60 seconds have passed' because no better way
    Given 60 seconds have passed
    When I run the :goto_health_check_page web console action
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | readiness   |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_2>    |
      | health_kind    | readiness   |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | liveness    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed

    # Check above save takes effect via CLI
    # Need wait because auto step interval is too fast
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | <kind>             |
      | resource_name | <resource_name>    |
      | o             | yaml               |
    Then the step should succeed
    And the output should not contain "nessProbe"
    """

    Examples:
      | kind | resource_name | cont_1           | cont_2                 | action_name                 |
      | dc   | dctest        | dctest-1         | dctest-2               | goto_one_dc_page            |
      | rc   | rctest        | hello-openshift  | hello-openshift-fedora | goto_one_standalone_rc_page |