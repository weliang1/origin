Feature: Configuration of environment variables check

  # @author xiuwang@redhat.com
  # @case_id 499488 499490
  Scenario Outline: Check environment variables of ruby-20 image
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-<os>.json |
      | n | <%= project.name %> |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc499490/ruby20<os>-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-1 |
    Then the step should succeed
    And the output should contain "<image>"
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Welcome to an OpenShift v3 Demo App |
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | RACK_ENV=production            |
      | RAILS_ENV=production           |
      | DISABLE_ASSET_COMPILATION=true |
    Examples:
      | os | image |
      | rhel7   | <%= product_docker_repo %>openshift3/ruby-20-rhel7:latest |
      | centos7 | docker.io/openshift/ruby-20-centos7 |

  # @author xiuwang@redhat.com
  # @case_id 499491
  Scenario: Check environment variables of perl-516-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/perl516rhel7-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Everything is OK |
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | ENABLE_CPAN_TEST=on |
      | CPAN_MIRROR=        |

  # @author wzheng@redhat.com
  # @case_id 499485
  Scenario: Configuration of enviroment variables check - php-55-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-55-rhel7-stibuild.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | ERROR_REPORTING=E_ALL & ~E_NOTICE |
      | DISPLAY_ERRORS=ON |
      | DISPLAY_STARTUP_ERRORS=OFF |
      | TRACK_ERRORS=OFF |
      | HTML_ERRORS=ON |
      | INCLUDE_PATH=/opt/app-root/src |
      | SESSION_PATH=/tmp/sessions |
      | OPCACHE_MEMORY_CONSUMPTION=16M |
      | PHPRC=/opt/rh/php55/root/etc/ |
      | PHP_INI_SCAN_DIR=/opt/rh/php55/root/etc/ |

  # @author cryan@redhat.com
  # @case_id 493677
  Scenario: Substitute environment variables into a container's command
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/container/commandtest.json |
    Then the step should succeed
    Given the pod named "expansion-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | expansion-pod |
    Then the step should succeed
    And the output should contain "http"
  
  # @author pruan@redhat.com
  # @case_id 493676
  Scenario: Substitute environment variables into a container's args
    Given I have a project
    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/container/argstest.json |
    Then the step should succeed
    Given the pod named "expansion-pod" status becomes :running
    When I run the :logs client command with:
      | resource_name | expansion-pod |
    Then the step should succeed
    And the output should contain:
      |  serving on 8080 |
      |  serving on 8888 |

  # @author pruan@redhat.com
  # @case_id 493678
  Scenario: Substitute environment variables into a container's env
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc493678/envtest.json |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    When I run the :env client command with:
      | resource | pod             |
      | keyval   | hello-openshift |
      | list     | true            |
    Then the step should succeed
    And the output should match:
      | zzhao=redhat                    |
      | test2=\$\(zzhao\)               |
      | test3=___\$\(zzhao\)___         |
      | test4=\$\$\(zzhao\)_\$\(test2\) |
      | test6=\$\(zzhao\$\(zzhao\)      |
      | test7=\$\$\$\$\$\$\(zzhao\)     |
      | test8=\$\$\$\$\$\$\$\(zzhao\)   |
