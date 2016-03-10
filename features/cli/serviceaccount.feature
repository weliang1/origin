Feature: ServiceAccount and Policy Managerment

  # @author anli@redhat.com
  # @case_id 490717
  Scenario: Could grant admin permission for the service account username to access to its own project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I create the serviceaccount "demo"
    And I give project admin role to the demo service account
    When I run the :describe client command with:
      | resource | policybindings |
      | name     | :default       |
    Then the output should match:
      | Role:\\s+admin |
      | ServiceAccounts:\\s+demo |
    Then the output should contain:
      | RoleBinding[system:deployers] |
    Given I find a bearer token of the demo service account
    And I switch to the demo service account
    When I run the :get client command with:
      | resource | buildconfig        |
    Then the output should contain:
      | myapp   |

  # @author xxing@redhat.com
  # @case_id 490722
  Scenario: The default service account could only get access to imagestreams in its own project
    Given I have a project
    When I run the :policy_who_can client command with:
      | verb     | get |
      | resource | imagestreams/layers |
    Then the output should match:
      | Groups:\\s+system:cluster-admins |
      | system:serviceaccounts:<%= Regexp.escape(project.name) %> |
    When I run the :policy_who_can client command with:
      | verb     | get |
      | resource | pods/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)? |
    Given I create a new project
    When I run the :policy_who_can client command with:
      | verb     | get |
      | resource | imagestreams/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)?:<%= Regexp.escape(@projects[0].name) %>  |
    When I run the :policy_who_can client command with:
      | verb     | update |
      | resource | imagestreams/layers |
    Then the output should not contain:
      | system:serviceaccounts:<%= project.name %> |
    When I run the :policy_who_can client command with:
      | verb     | delete |
      | resource | imagestreams/layers |
    Then the output should not match:
      | system:serviceaccount(?:s)?:<%= Regexp.escape(project.name) %> |

  # @author xxia@redhat.com
  # @case_id 497381
  Scenario: Could grant view permission for the service account username to access to its own project
    Given I have a project
    When I create a new application with:
      | docker image | <%= project_docker_repo %>openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    When I give project view role to the default service account
    And I run the :get client command with:
      | resource       | rolebinding  |
      | resource_name  | view         |
    Then the output should match:
      | view.+default         |

    Given I find a bearer token of the default service account
    And I switch to the default service account
    When I run the :get client command with:
      | resource | buildconfig         |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | myapp   |
    When I create a new application with:
      | docker image | <%= project_docker_repo %>openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | another-app         |
      | n            | <%= project.name %> |
    Then the step should fail
    When I run the :delete client command with:
      | object_type       | bc        |
      | object_name_or_id | myapp     |
      | n                 | <%= project.name %> |
    Then the step should fail
    When I give project admin role to the builder service account
    Then the step should fail


  # @author anli@redhat.com
  # @case_id 497373
  Scenario: Could grant edit permission for the service account group to access to other project
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_group client command with:
      | role | edit     |
      | group_name | system:serviceaccounts:<%= cb.project1 %> |
    Then the step should succeed
    Given I use the "<%= cb.project1 %>" project
    Given I find a bearer token of the system:serviceaccount:<%= cb.project1 %>:default service account
    Given I switch to the system:serviceaccount:<%= cb.project1 %>:default service account
    Given I use the "<%= cb.project2 %>" project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I wait for the "myapp" service to be created
    When I run the :delete client command with:
      | object_type       | service    |
      | object_name_or_id | myapp  |
      | cascade           | true  |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author anli@redhat.com
  # @case_id 497374
   Scenario: Could grant view permission for the service account group to access to other project
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    When I run the :policy_add_role_to_group client command with:
      | role | view     |
      | group_name | system:serviceaccounts:<%= cb.project1 %> |
    Then the step should succeed
    Given I use the "<%= cb.project1 %>" project
    Given I find a bearer token of the system:serviceaccount:<%= cb.project1 %>:default service account
    Given I switch to the system:serviceaccount:<%= cb.project1 %>:default service account
    Given I use the "<%= cb.project2 %>" project
    When I run the :get client command with:
      | resource | service |
    Then the step should succeed
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp2         |
    Then the step should fail
    When I run the :delete client command with:
      | object_type       | service    |
      | object_name_or_id | myapp  |
      | cascade           | true  |
    Then the step should fail
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author anli@redhat.com
  # @case_id 497375
   Scenario: Could grant edit permission for the service account group to access to its own project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I wait for the "myapp" service to be created
    Given I create the serviceaccount "test1"
    When I run the :policy_add_role_to_group client command with:
      | role | edit     |
      | group_name | system:serviceaccounts:<%= project.name %> |
    Then the step should succeed
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:test1 service account
    Given I switch to the system:serviceaccount:<%= project.name %>:test1 service account
    And I use the "<%= project.name %>" project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp2         |
    Then the step should succeed
    When I run the :get client command with:
      | resource | service |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | service    |
      | object_name_or_id | myapp  |
      | cascade           | true  |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail


  # @author anli@redhat.com
  # @case_id 497376
   Scenario: Could grant view permission for the service account group to access to its own project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I wait for the "myapp" service to be created
    Given I create the serviceaccount "test1"
    When I run the :policy_add_role_to_group client command with:
      | role | view     |
      | group_name | system:serviceaccounts:<%= project.name %> |
    Then the step should succeed
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:test1 service account
    Given I switch to the system:serviceaccount:<%= project.name %>:test1 service account
    And I use the "<%= project.name %>" project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp2         |
    Then the step should fail
    When I run the :get client command with:
      | resource | service |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | service    |
      | object_name_or_id | myapp  |
      | cascade           | true  |
    Then the step should fail
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author anli@redhat.com
  # @case_id 497377
   Scenario: Could grant edit permission for the service account username to access to other project
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    Given I use the "<%= cb.project1 %>" project
    And I create the serviceaccount "test1"
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    Given I use the "<%= cb.project2 %>" project
    When I run the :policy_add_role_to_user client command with:
      | role       | edit            |
      | user_name | system:serviceaccount:<%= cb.project1 %>:test1 |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Given I wait for the "database" service to be created    
    Given I use the "<%= cb.project1 %>" project
    Given I find a bearer token of the system:serviceaccount:<%= cb.project1 %>:test1 service account
    Given I switch to the system:serviceaccount:<%= cb.project1 %>:test1 service account
    And I use the "<%= project.name %>" project
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    Given I use the "<%= cb.project2 %>" project
    When I run the :deploy client command with:
      | deployment_config | database |
      | cancel             ||
    Then the step should succeed   
    And I wait for the steps to pass:
    """ 
    When I run the :deploy client command with:
    | deployment_config | database |
    Then the output should contain:
    | deployment was cancelled by the user|
    """
    When I run the :deploy client command with:
      | deployment_config | database |
      | retry             ||
    Then the step should succeed
    And the "ruby-sample-build-1" build was created

    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author anli@redhat.com
  # @case_id 497378
  Scenario: Could grant view permission for the service account username to access to other project
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    Given I use the "<%= cb.project1 %>" project
    And I create the serviceaccount "test1"
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    Given I use the "<%= cb.project2 %>" project
    When I run the :policy_add_role_to_user client command with:
      | role       | view            |
      | user_name | system:serviceaccount:<%= cb.project1 %>:test1 |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    Given I wait for the "database" service to be created
    Given I use the "<%= cb.project1 %>" project
    Given I find a bearer token of the system:serviceaccount:<%= cb.project1 %>:test1 service account
    Given I switch to the system:serviceaccount:<%= cb.project1 %>:test1 service account
    And I use the "<%= project.name %>" project
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    Given I use the "<%= cb.project2 %>" project
    When I run the :deploy client command with:
      | deployment_config | database |
      | cancel             ||
    Then the step should fail   
    And the output should contain:
      | ser "system:serviceaccount:<%= cb.project1 %>:test1" cannot update |

    When I run the :policy_add_role_to_user client command with:
      | role  | view     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | view     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author anli@redhat.com
  # @case_id 497380
   Scenario: Could grant edit permission for the service account username to access to its own project
    Given I have a project
    Given I create the serviceaccount "test1"
    When I run the :policy_add_role_to_user client command with:
      | role | edit     |
      | user_name | system:serviceaccount:<%= project.name %>:test1 |
    Then the step should succeed
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:test1 service account
    Given I switch to the system:serviceaccount:<%= project.name %>:test1 service account
    And I use the "<%= project.name %>" project 
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    Then the step should succeed
    Given I wait for the "myapp" service to be created
    When I replace resource "dc" named "myapp" saving edit to "tmp_out.yaml":
      | replicas: 1 | replicas: 2 |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pod    |
      | l                 | deploymentconfig=myapp  |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role  | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should fail
    When I run the :policy_remove_role_from_user client command with:
      | role  | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id 491400
  Scenario:[origin_platformexp_407] Create pods without ImagePullSecrets will inherit the ImagePullSecrets from its service account.
    Given I have a project
    And I create the serviceaccount "myserviceaccount<%= project.name  %>"
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/a8c3f83d3aedfe6930d1b9f56b1e6e8fa42dcd89/pods/hello-pod.json"
    And I replace lines in "hello-pod.json":
      | "serviceAccount": "" | "serviceAccount": "myserviceaccount<%= project.name  %>" |
    Then the step should succeed
    When I run the :create client command with:
      | f                    |  hello-pod.json                      |
    Then the step should succeed

    When I run the :get client command with:
      | resource             |   pods                               |
      | o                    |   yaml                               |
    Then the step should succeed
    And the output should match:
      | imagePullSecrets:\\s+- name: myserviceaccount<%= project.name  %>-dockercfg     |

  # @author xiaocwan@redhat.com
  # @case_id 490720
  Scenario:Could grant admin permission for the service account group to access to other project
    Given an 8 characters random string of type :dns is stored into the :project1 clipboard
    And an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_group client command with:
      | role | admin     |
      | group_name | system:serviceaccounts:<%= cb.project1 %> |
    Then the step should succeed
    Given I use the "<%= cb.project1 %>" project
    And I find a bearer token of the system:serviceaccount:<%= cb.project1 %>:default service account
    And I switch to the system:serviceaccount:<%= cb.project1 %>:default service account
    And I use the "<%= cb.project2 %>" project

    When I run the :get client command with:
      | resource | service |
    Then the output should not contain "ruby-hello-world"
    When I create a new application with:
      | image_stream | ruby          |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp<%= cb.project1 %>                       |
    Then the step should succeed
    Given I wait for the "myapp<%= cb.project1 %>" service to be created
    When I run the :delete client command with:
      | object_type       | service        |
      | object_name_or_id | myapp<%= cb.project1 %>          |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit     |
      | user_name |  <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_remove_role_from_user client command with:
      | role      | edit     |
      | user_name |  %= user(0, switch: false).name %> |
    Then the step should succeed
    
