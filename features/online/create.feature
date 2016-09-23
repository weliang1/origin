Feature: ONLY ONLINE Create related feature's scripts in this file

  # @author etrott@redhat.com
  # @case_id 530591
  Scenario Outline: Maven repository can be used to providing dependency caching for xPaas templates
    Given I have a project
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %> |
      | template_name | <template>          |
      | namespace     | openshift           |
      | param_one     | :null               |
      | param_two     | :null               |
      | param_three   | :null               |
      | param_four    | :null               |
      | param_five    | :null               |
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-1 |
      | build_status_name | Complete                |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Downloading: https://mirror.openshift.com/nexus/content/groups/public/ |
    Then the step should succeed
    Given I perform the :delete_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | <app-name>          |
      | env_var_key   | MAVEN_MIRROR_URL    |
    Then the step should succeed
    When I run the :save_your_committed_changes web console action
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-2 |
      | build_status_name | Complete                |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Downloading: https://repo1.maven.org/maven2/ |
    Then the step should succeed
    Given I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %>                   |
      | bc_name       | <app-name>                            |
      | env_var_key   | MAVEN_MIRROR_URL                      |
      | env_var_value | https://repo1.maven.org/non-existing/ |
    Then the step should succeed
    When I run the :save_your_committed_changes web console action
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | failed              |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-3 |
      | build_status_name | Failed                  |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Aborting due to error code 1 |
    Then the step should succeed
    Examples:
      | template                             | app-name |
      | jws30-tomcat8-mongodb-persistent-s2i | jws-app  |
      | eap64-mysql-persistent-s2i           | eap-app  |

  # @author etrott@redhat.com
  # @case_id 532961
  # @case_id 533308
  Scenario Outline: Create resource from imagestream via oc new-app
    Given I have a project
    Then I run the :new_app client command with:
      | name         | resource-sample |
      | image_stream | <is>            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=resource-sample-1 |
    When I expose the "resource-sample" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    Examples:
      | is                               |
      | openshift/jboss-eap70-openshift  |
      | openshift/redhat-sso70-openshift |