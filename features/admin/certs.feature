Feature: cacert related scenarios
  # @author pruan@redhat.com
  # @case_id 512254
  Scenario: Create an RSA key pair and generate PEM-encoded public/private key files
    Given a 5 characters random string of type :dns is stored into the :private_key_name clipboard
    Given a 5 characters random string of type :dns is stored into the :public_key_name clipboard
    When I run the :oadm_ca_create_key_pair client command with:
      | private_key | <%= cb.private_key_name %> |
      | public_key  | <%= cb.public_key_name %>  |
      | loglevel    | 4                          |
    Then the step should succeed
    And the output should contain:
      | Generated new key pair as <%= cb.public_key_name %> and <%= cb.private_key_name %> |
    When I run the :oadm_ca_create_key_pair client command with:
      | private_key | <%= cb.private_key_name %> |
      | public_key  | <%= cb.public_key_name %>  |
      | loglevel    | 4                          |
      | overwrite   | false                      |
    Then the step should succeed
    And the output should contain:
      | Keeping existing private key file <%= cb.private_key_name %> |
    When I run the :oadm_ca_create_key_pair client command with:
      | private_key | <%= cb.private_key_name %> |
      | public_key  | <%= cb.public_key_name %>  |
      | loglevel    | 4                          |
      | overwrite   | true                       |
    Then the step should succeed
    And the output should contain:
      | Generated new key pair as <%= cb.public_key_name %> and <%= cb.private_key_name %> |

  # @author pruan@redhat.com
  # @case_id 512255
  Scenario: Create a self-signed CA key/cert
    #  Create self-signed CA key/cert without any options
    When I run the :oadm_ca_create_signer_cert client command
    Then the step should succeed
    And the "openshift.local.config/master" directory contains:
      | ca.serial.txt |
      | ca.key        |
      | ca.crt        |
    Given the "openshift.local.config/master/ca.crt" cert file is parsed into the clipboard
    Then the expression should be true> cb.cert.subject.to_s =~ /\/CN=openshift-signer@\d+/
    Then the expression should be true> cb.cert.subject.to_s == cb.cert.issuer.to_s
    # Create self-signed CA key/cert with --cert & --key
    Given the "openshift.local.config" directory is removed
    # need to remove the directory for the next run
    When I run the :oadm_ca_create_signer_cert client command with:
      | cert | ca.crt |
      | key  | ca.key |
    Then the step should fail
    And the output should contain:
      |  error: open openshift.local.config/master/ca.serial.txt: no such file or directory |
    # Create self-signed CA key/cert with --cert or --key
    When I run the :oadm_ca_create_signer_cert client command with:
      | cert | ca.crt |
    Then the step should succeed
    Given the "." directory contains:
      | ca.crt                 |
      | openshift.local.config |
    Then the "openshift.local.config/master" directory contains:
      | ca.serial.txt |
      | ca.key        |
    Given the "openshift.local.config" directory is removed
    # check for self-signed CA key/cert with --name
    When I run the :oadm_ca_create_signer_cert client command with:
      | name | redhat.com |
    Then the step should succeed
    Given the "openshift.local.config/master/ca.crt" cert file is parsed into the clipboard

    Then the expression should be true> cb.cert.subject.to_s =~ /\/CN=redhat.com/
    Given the "openshift.local.config" directory is removed
    # check for self-signed CA key/cert with --serial
    Given the "serial.txt" file is created with the following lines:
      | 5551234567 |
    When I run the :oadm_ca_create_signer_cert client command with:
      | serial | serial.txt |
    Then the step should succeed
    Given the "openshift.local.config/master/ca.crt" cert file is parsed into the clipboard
    Then the "." directory contains:
      | serial.txt |
    And evaluation of `cb.cert.issuer.to_s.split('@')[1]` is stored in the :cert_id_old clipboard
    # check  self-signed CA key/cert  with --overwrite=true
    When I run the :oadm_ca_create_signer_cert client command with:
      | serial    | serial.txt |
      | overwrite | true       |
    Then the step should succeed
    Given the "openshift.local.config/master/ca.crt" cert file is parsed into the clipboard
    And evaluation of `cb.cert.issuer.to_s.split('@')[1]` is stored in the :cert_id_new clipboard
    Then the expression should be true> cb.cert_id_new != cb.cert_id_old