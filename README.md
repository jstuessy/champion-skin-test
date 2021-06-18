# champion-skin-test


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