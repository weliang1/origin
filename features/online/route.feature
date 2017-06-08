Feature: Route test in online environments 
  # @author zhaliu@redhat.com
  # @case_id OCP-10047
  Scenario: Custom route with passthrough termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    And I wait for the "service-secure" service to become ready
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route |
      | service | service-secure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "passthrough-route" route
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %> |
      | -I |
      | -k |
    Then the output should match "HTTP/.* 503 Service Unavailable"
    
  # @author zhaliu@redhat.com
  # @case_id OCP-10046
  Scenario: Custom route with edge termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    And I wait for the "service-unsecure" service to become ready
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem" 
    When I run the :create_route_edge client command with:
      | name | edge-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
 
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "edge-route" route

    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>/ |
      | -I | 
      | -k | 
      | -v | 
    Then the output should match "HTTP/.* 503 Service Unavailable"
    Then the output should not contain "CN=*.example.com"