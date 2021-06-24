# champion-skin-test


## todo

  - [x] create consul cluster
  - [] create vault cluster
    - [x] create 3 vault servers
    - [x] have connected to consul via consul clients
    - [x] have vault servers all clustered
      - [x] each server must know about the other servers
        - [X] have vault self-register with consul
      - [] have playbook tasks run with VAULT_ADDR set correctly
    - [] have vault setup and store keys

## Problem: We need to reference or create a shared secret value that is easily accesible by all playbooks and roles before a shared secret value service exists

Solution 'tmp file': Store value in local machine file
  - Consequence: Unencrytped
  - Consequence: Roles and playbooks have nested paths that are unequal, annoying to fix
  - Consequence: Accessible to the local machine
  - Consequence: Unencrypted
  - Consequence: Value has to be shared to each machine via facts

Solution 'env': Store value in local machine env
  - Consequence: Could be longer than allowed
  - Consequence: Unencrypted
  - Consequence: Accessible to the local machine
  - Consequence: Value has to be shared to each machine via facts

Solution 'KMS': Utilize the cloud based KMS to store a "promethean value" (aka for-bootstrap-only value)
  - Consequence: Doesn't work on own-clouds
  - Consequence: Costs money


Jun 24 00:58:40 ip-172-31-17-120 vault[10800]: Error initializing listener of type tcp: error loading TLS cert: open : no such file or directory

Jun 24 00:58:40 ip-172-31-17-120 vault[10800]: 2021-06-24T00:58:40.460Z [WARN]  no `api_addr` value specified in config or in VAULT_API_ADDR; falling back to detection if possible, but this value should be manually set       

Jun 24 01:26:09 ip-172-31-17-120 systemd[1]: /lib/systemd/system/vault-server.service:33: Unknown key name 'StartLimitIntervalSec' in section 'Service', ignoring.