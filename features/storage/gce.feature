Feature: GCE Persistent Volume
  # @author lxia@redhat.com
  # @case_id 510362
  @admin
  Scenario: [origin_infra_181] GCE PD volume plugin dynamic provisioning
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo-dynamic.json" replacing paths:
      | ["metadata"]["name"]                         | gce-pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce             |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                       |
    Then the step should succeed
    And the "gce-pvc1-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo-dynamic.json" replacing paths:
      | ["metadata"]["name"]                         | gce-pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany             |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                       |
    Then the step should succeed
    And the "gce-pvc2-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo-dynamic.json" replacing paths:
      | ["metadata"]["name"]                         | gce-pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany              |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                       |
    Then the step should succeed
    And the "gce-pvc3-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | gce-pvc1-<%= project.name %> |
      | gce-pvc2-<%= project.name %> |
      | gce-pvc3-<%= project.name %> |

    When I run the :get client command with:
      | resource      | pvc                          |
      | resource_name | gce-pvc1-<%= project.name %> |
      | o             | json                         |
    Then the step should succeed
    And the output is parsed as JSON
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name1 clipboard

    When I run the :get client command with:
      | resource      | pvc                          |
      | resource_name | gce-pvc2-<%= project.name %> |
      | o             | json                         |
    Then the step should succeed
    And the output is parsed as JSON
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name2 clipboard

    When I run the :get client command with:
      | resource      | pvc                          |
      | resource_name | gce-pvc3-<%= project.name %> |
      | o             | json                         |
    Then the step should succeed
    And the output is parsed as JSON
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name3 clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | gce-pvc1-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod1-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | gce-pvc2-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod2-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | gce-pvc3-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod3-<%= project.name %> |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "<%= pod(-1).name %>" pod:
      | touch | /mnt/gce/testfile_1 |
    #Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | touch | /mnt/gce/testfile_2 |
    #Then the step should succeed
    When I execute on the "<%= pod(-3).name %>" pod:
      | touch | /mnt/gce/testfile_3 |
    #Then the step should succeed

    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    Then I wait for the resource "pv" named "<%= cb.pv_name1 %>" to disappear within 1200 seconds
    And I wait for the resource "pv" named "<%= cb.pv_name2 %>" to disappear
    And I wait for the resource "pv" named "<%= cb.pv_name3 %>" to disappear