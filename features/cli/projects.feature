Feature: projects related features via cli
  # @author pruan@redhat.com
  # @case_id 479238
  Scenario: There is annotation instead of 'Display name' for project info
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
      | display_name | <%= cb.proj_name %> |
    Then the step should succeed
    And I run the :get client command with:
      | resource | project |
      |  o       | json    |
    Then the output should contain:
      | display-name": "<%= cb.proj_name %>" |
    And the output should not contain:
      | displayName |

  # @author pruan@redhat.com
  # @case_id 494759
  Scenario: Could not create the project with invalid name via CLI
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | new-project  |
    Then the step should fail
    And the output should contain:
      | Create a new project for yourself |
      | oc new-project NAME [--display-name=DISPLAYNAME] [--description=DESCRIPTION] [options] |
      | error: must have exactly one argument                                                  |
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    Given a 64 character random string of type :dns is stored into the :proj_name_3 clipboard
    And evaluation of `"xyz-"` is stored in the :proj_name_4 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should fail
    And the output should contain:
      | project "<%= cb.proj_name %>" already exists |
    When I run the :new_project client command with:
      | project_name | q |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name_3 %> |
    Then the step should fail
    When I run the :new_project client command with:
      | project_name | ALLUPERCASE |
    Then the step should fail
    Then the output should contain:
      | The ProjectRequest "ALLUPERCASE" is invalid. |
    When I run the :new_project client command with:
      | project_name | -abc |
    Then the step should fail
    And the output should contain:
      | unknown shorthand flag: 'a' in -abc |
    When I run the :new_project client command with:
      | project_name | xyz- |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "xyz-" is invalid. |

    When I run the :new_project client command with:
      | project_name | $pe#cial& |
    Then the step should fail
    And the output should contain:
      | The ProjectRequest "$pe#cial&" is invalid. |

  # @author pruan@redhat.com
  # @case_id 478983
  @admin
  @destructive
  Scenario: A user could create a project successfully via CLI
    Given I have a project
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    Then the output should contain:
      | <%= project.name %> |
      | Active              |
    And I register clean-up steps:
     | I run the :oadm_add_cluster_role_to_group admin command with: |
     |   ! role_name  ! self-provisioner     !                       |
     |   ! group_name ! system:authenticated !                       |
     | the step should succeed                                       |
    When I run the :oadm_remove_cluster_role_from_group admin command with:
      | role_name  | self-provisioner     |
      | group_name | system:authenticated |
    Then the step should succeed
    When I create a new project
    Then the step should fail
    And the output should contain:
      | You may not request a new project via this API |
  # @author pruan@redhat.com
  # @case_id 470729
  Scenario: Should use and show the existing projects after the user login
    Given I create a new project
    And evaluation of `user.projects` is stored in the :user1_proj clipboard
    And I switch to the second user
    And I create a new project
    And I create a new project
    And I create a new project
    And evaluation of `user.projects` is stored in the :user2_proj clipboard
    And I switch to the first user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the output should contain:
      | Using project "<%= cb.user1_proj[0].name %>" |
    And I switch to the second user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the output should contain:
      | Using project "<%= project.name %>" |
      | You have access to the following projects and can switch between them with 'oc project <projectname>': |
      | * <%= cb.user2_proj[0].name %> |
      | * <%= cb.user2_proj[1].name %> |
      | * <%= cb.user2_proj[2].name %> |
    And I switch to the third user
    And I run the :login client command with:
      | u | <%= @user.name %>     |
    Then the step should succeed
    And the output should contain:
      | You don't have any projects. You can try to create a new project |

  # @author pruan@redhat.com
  # @case_id 470730
  Scenario: User should be able to switch projects via CLI
    Given I create a new project
    And I create a new project
    And I create a new project
    When I run the :project client command with:
      | project_name | <%= project(2, switch: false).name %> |
    Then the output should contain:
      | Now using project "<%= project(2, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project(1, switch: false).name %> |
    Then the output should contain:
      | Now using project "<%= project(1, switch: false).name %>" on server |
    When I run the :project client command with:
      | project_name | <%= project.name %> |
    Then the output should contain:
      | Now using project "<%= project.name %>" on server |
    And I run the :project client command with:
      | project_name | notaccessible |
    Then the output should contain:
      | error: You are not a member of project "notaccessible". |
      | Your projects are:                                      |
      | * <%= project(0).name %>                              |
      | * <%= project(1).name %>                              |
      | * <%= project(2).name %>                              |
  # @author haowang@redhat.com
  # @case_id 497401
  Scenario: Indicate when build failed to push in 'oc status'
    Given I have a project
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      | <%= project.name %> |
      |no services |
      |Run 'oc new-app' to create an application|
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | l | app=ruby |
    Then the step should succeed
    And the output should contain:
      | WARNING |
      | No Docker registry has been configured with the server |
    Given the "ruby-hello-world-1" build was created
    When I run the :status client command
    Then the step should succeed
    And the output should contain:
      | can't push to image |
      | Warning |
      | administrator has not configured the integrated Docker registry |

  # @author yapei@redhat.com
  # @case_id 476297
  Scenario: Could delete all resources when delete the project
    Given a 5 characters random string of type :dns is stored into the :prj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.prj_name %> |
    Then the step should succeed
    And I create a new application with:
      | docker image | openshift/mysql-55-centos7 |
      | code         | https://github.com/openshift/ruby-hello-world |
      | n            | <%= cb.prj_name %>           |
    Then the step should succeed

    ### get project resource
    When I run the :get client command with:
      | resource | deploymentconfigs |
      | n        | <%= cb.prj_name %>  |
    Then the output should contain:
      | mysql-55-centos7 |
      | ruby-hello-world |

    When I run the :get client command with:
      | resource | buildconfigs |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | ruby-hello-world |

    When I run the :get client command with:
      | resource | services |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | mysql-55-centos7 |
      | ruby-hello-world |

    When I run the :get client command with:
      | resource | pods  |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | mysql-55-centos7-1-deploy |
      | ruby-hello-world-1-build |

    ### delete this project
    Then I run the :delete client command with:
      | object_type       | project |
      | object_name_or_id | <%= cb.prj_name %> |
    And the step should succeed

    ### get project resource after project is deleted
    When I run the :get client command with:
      | resource | deploymentconfigs |
      | n        | <%= cb.prj_name %>  |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list deploymentconfigs in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | buildconfigs |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list buildconfigs in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | services |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list services in project "<%= cb.prj_name %>" |
    When I run the :get client command with:
      | resource | pods  |
      | n        | <%= cb.prj_name %> |
    Then the output should contain:
      | Error from server: User "<%= @user.name %>" cannot list pods in project "<%= cb.prj_name %>" |

    ### create a project with same name, no context for this new one
    Given I run the :new_project client command with:
      | project_name | <%= cb.prj_name %> |
    And the step should succeed
    Then I run the :status client command
    And the output should contain:
      | In project <%= cb.prj_name %> on server |
      | You have no services, deployment configs, or build configs |

  # @author cryan@redhat.com
  # @case_id 481697
  @admin
  Scenario: User can get node selector from a project
    Given  an 8 character random string of type :dns is stored into the :oadmproj1 clipboard
    Given  an 8 character random string of type :dns is stored into the :oadmproj2 clipboard
    When admin creates a project with:
      | project_name | <%= cb.oadmproj1 %> |
      | admin | <%= user.name %> |
    Then the step should succeed
    When admin creates a project with:
      | project_name | <%= cb.oadmproj2 %> |
      | node_selector | env=qa |
      | description | testnodeselector |
      | admin | <%= user.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | project |
      | name | <%= cb.oadmproj1 %> |
    Then the step should succeed
    And the output should match "Node Selector:\s+<none>"
    When I run the :describe client command with:
      | resource | project |
      | name | <%= cb.oadmproj2 %> |
    Then the step should succeed
    And the output should match "Node Selector:\s+env=qa"

  # @author wyue@redhat.com
  # @case_id 481695
  @admin
  Scenario: Should be able to create a project with valid node selector
    ##create a project with the node label
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/projects/prj_with_invalid_node-selector.json"
    And I replace lines in "prj_with_invalid_node-selector.json":
      |"openshift.io/node-selector": "env,qa"|"openshift.io/node-selector": "<%= env.nodes[0].labels.first.join("=") %>"|
    Then the step should succeed
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    And I replace lines in "prj_with_invalid_node-selector.json":
      |"name": "jhou"|"name": "<%= cb.proj_name %>"|
    Then the step should succeed
    When I run the :create admin command with:
      | f | prj_with_invalid_node-selector.json |
    Then the step should succeed

    Given I register clean-up steps:
      | admin deletes the "<%= cb.proj_name %>" project |
      | the step should succeed                     |

    When I run the :describe admin command with:
      | resource | project |
      | name     | <%= cb.proj_name %> |
    Then the output should contain:
      | <%= env.nodes[0].labels.first.join("=") %> |

    ##grant admin to user
    When I run the :policy_add_role_to_user admin command with:
      | role            |   admin               |
      | user name       |   <%= user.name %>    |
      | n               |   <%= cb.proj_name %> |
    Then the step should succeed

    ##create a pod in the project
    When I use the "<%= cb.proj_name %>" project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then  the step should succeed

    ##check pod is create on the correspod node
    When I run the :describe client command with:
      | resource      | pods            |
      | name | hello-openshift |
    Then the output should contain:
      | <%= env.nodes.first.name %> |



  # @author xiaocwan@redhat.com
  # @case_id 476298
  Scenario: [origin_platformexp_387][origin_runtime_664] User should be notified if the set project does not exist anymore
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed

    When I run the :oadm_add_role_to_user client command with:
      | role_name | admin             |
      | user_name | <%= user(1, switch: false).name %>  |
    Then the step should succeed

    Given I switch to the second user
    When I use the "<%= cb.proj_name %>" project
    Then the step should succeed

    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Then the step should succeed

    When I delete the project
    Then the step should succeed

    Given I switch to the first user
    When I run the :get client command with:
      | resource | pods |
    Then the step should fail

  # @author pruan@redhat.com
  # @case_id 515693
  Scenario: Give user suggestion about new-app on new-project
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    And the output should contain:
      | You can add applications to this project with the 'new-app' command. |

  # @author cryan@redhat.com
  # @case_id 487699
  Scenario: Could remove user and group from the current project
    Given I have a project
    When I run the :oadm_add_role_to_user client command with:
      | role_name | admin |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :oadm_add_role_to_group client command with:
      | role_name | admin |
      | group_name | system:serviceaccounts:<%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | policybinding |
      | name | :default |
    Then the step should succeed
    And the output should match:
      | Users:\\s+<%= user.name %>, <%= user(1, switch: false).name %> |
      | Groups:\\s+system:serviceaccounts:<%= user(1, switch: false).name %> |
    When I run the :policy_remove_group client command with:
      | group_name | system:serviceaccounts:<%= user(1, switch: false).name %> |
    Then the step should succeed
    And the output should contain "Removing admin from groups"
    When I run the :describe client command with:
      | resource | policybinding |
      | name | :default |
    Then the step should succeed
    And the output should match:
      | Users:\\s+<%= user.name %>, <%= user(1, switch: false).name %> |
    And the output should not contain "system:serviceaccounts:<%= user(1, switch: false).name %>"