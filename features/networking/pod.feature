Feature: Service related networking scenarios
  # @author bmeng@redhat.com
  # @case_id 514976
  @admin
  Scenario: Pod cannot claim UDP port 4789 on the node as part of a port mapping
    Given I have a project
    And SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod_with_udp_port_4789.json |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :pending
    When I run the :describe client command with:
      | resource      | pod   |
    Then the output should contain "address already in use"

  # @author bmeng@redhat.com
  # @case_id 516869
  @admin
  Scenario: The user created docker container in openshift cluster should have outside network access
    Given I select a random node's host
    And I run commands on the host:
      | docker run -td --name=test-container bmeng/hello-openshift |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run commands on the host:
      | docker rm -f test-container |
    the step should succeed
    """
    When I run commands on the host:
      | docker exec test-container curl -sIL www.redhat.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200 OK"