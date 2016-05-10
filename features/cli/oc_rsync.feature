Feature: oc_rsync.feature

  # @author cryan@redhat.com
  # @case_id 510666
  Scenario: oc rsync with --delete option, using rsync-daemon strategy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | uptoknow/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | app=scratch |
    Given a 5 characters random string of type :dns is stored into the :tcdir clipboard
    Given I create the "<%= cb.tcdir %>" directory
    Given a 5 characters random string of type :dns is stored into the :tcfile clipboard
    Given a "<%= cb.tcdir %>/<%= cb.tcfile %>" file is created with the following lines:
    """
    TC 510666 test
    """
    Given I get project pods
    #As of 3/16, oc rsync requires the source/destination points to a path,
    #not a specific file
    When I run the :rsync client command with:
      | source | <%= cb.tcdir %> |
      | destination | <%= pod.name %>:/tmp/test |
    Then the step should succeed
    And the output should match "sent \d+ bytes"
    When I execute on the pod:
      | ls | -ltr | /tmp/test |
    Then the step should succeed
    And the output should contain "<%= cb.tcdir %>"
    When I execute on the pod:
      | cat | /tmp/test/<%= cb.tcdir%>/<%= cb.tcfile %> |
    Then the step should succeed
    And the output should contain "TC 510666 test"
    Given the "<%= cb.tcdir %>/<%= cb.tcfile %>" file is deleted
    Given a 5 characters random string of type :dns is stored into the :tcfile2 clipboard
    Given a "<%= cb.tcdir %>/<%= cb.tcfile2 %>" file is created with the following lines:
    """
    TC 510666 test
    """
    When I run the :rsync client command with:
      | source | <%= cb.tcdir %> |
      | destination | <%= pod.name %>:/tmp/test |
      | delete | true |
      | strategy | rsync-daemon |
    Then the step should succeed
    And the output should match "sent \d+ bytes"
    And the output should contain "deleting"
    When I execute on the pod:
      | ls | -ltr | /tmp/test/<%= cb.tcdir %> |
    Then the step should succeed
    And the output should contain "<%= cb.tcfile2 %>"
    And the output should not contain "<%= cb.tcfile %>"
    When I execute on the pod:
      | cat | /tmp/test/<%= cb.tcdir%>/<%= cb.tcfile2 %> |
    Then the step should succeed
    And the output should contain "TC 510666 test"
    Given a 5 characters random string of type :dns is stored into the :tcfile3 clipboard
    Given a "<%= cb.tcdir %>/<%= cb.tcfile3 %>" file is created with the following lines:
    """
    TC 510666 test
    """
    Then the step should succeed
    When I run the :rsync client command with:
      | source | <%= pod.name %>:/tmp/test/<%= cb.tcdir%> |
      | destination | . |
      | delete | true |
      | strategy | rsync-daemon |
    Then the step should succeed
    And the output should match "sent \d+ bytes"
    And the output should contain "deleting"
    Given the "<%= cb.tcdir %>/<%= cb.tcfile3 %>" file is not present

  # @author cryan@redhat.com
  # @case_id 510657
  Scenario: Copying files from container to host using oc rsync comand with rsync strategy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | app=scratch |
    Given I create the "rsync_folder" directory
    Given a "test1" file is created with the following lines:
    """
    test1
    """
    When I run the :rsync client command with:
      | source | . |
      | destination | <%= pod.name %>:/tmp/test1  |
      | loglevel | 5 |
      | strategy | rsync |
    Then the step should succeed
    When I run the :rsync client command with:
      | source | <%= pod.name %>:/tmp/test1 |
      | destination | ./rsync_folder |
      | loglevel | 5 |
      | strategy | rsync |
    Then the step should succeed
    And the output should match "sent \d+ bytes"
    Given the "rsync_folder/test1" file is present
    When I run the :rsync client command with:
      | source | <%= pod.name %>:/root/notexisted/  |
      | destination | . |
      | loglevel | 5 |
      | strategy | rsync |
    Then the step should fail
    And the output should contain "No such file or directory"
    When I run the :rsync client command with:
      | source | <%= pod.name %>:/tmp/test1 |
      | destination | ./nonexisted |
      | loglevel | 5 |
      | strategy | rsync |
    Then the step should fail
    And the output should contain "invalid path"
    Given I create the "rsync_folder/lvl2" directory
    When I run the :rsync client command with:
      | source | <%= pod.name %>:/tmp/test1 |
      | destination | ./rsync_folder/lvl2 |
      | loglevel | 5 |
      | strategy | rsync |
    Then the step should succeed
    And the output should match "sent \d+ bytes"
    Given the "rsync_folder/lvl2/test1" file is present