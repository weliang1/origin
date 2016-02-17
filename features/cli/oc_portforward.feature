Feature: oc_portforward.feature

  # @author cryan@redhat.com
  # @case_id 472860
  Scenario: Forwarding a pod that isn't running
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod-bad.json |
    When I run the :get client command with:
      | resource | pod |
    Then the output should contain "Pending"
    When I run the :port_forward client command with:
      | pod | hello-openshift |
      | port_spec | :8080 |
    Then the step should fail
    And the output should contain "Unable to execute command because pod is not running. Current status=Pending"

  # @author cryan@redhat.com
  # @case_id 472861
  Scenario: Forwarding local port to a pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :get client command with:
      | resource | pod |
    Then the output should contain "Running"
    When I run the :port_forward client command with:
      | pod | hello-openshift   |
      | port_spec | 5000:8080   |
      | _timeout | 10           |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:5000 -> 8080"
    When I run the :port_forward client command with:
      | pod | hello-openshift  |
      | port_spec | :8080      |
      | _timeout | 10          |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:\d+ -> 8080"
    When I run the :port_forward client command with:
      | pod | hello-openshift  |
      | port_spec | 8000:8080  |
      | _timeout | 10          |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:8000 -> 8080"