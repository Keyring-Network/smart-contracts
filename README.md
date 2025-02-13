# Keyring Smart Contracts

### Test

```shell
./test.sh
```
### Deploy
Deployment and upgrade should be managed via the specific deploy and upgrade shell files for each chain. All commands that have been run are commented out.

The steps to create a deployment are as follows:
Run the applicable deploy script and extract the proxy address from the logs.
Place the proxy address in the /scripts/common/deployments.sol file and update the selector list and the if else logic below in the depoloyment file.
Run the upgrade scripts to walk through the upgrade sequence until the new env is caught up to the lastest version number for the system.


Checklist for new deployments:
- UPDATE THE FOUNDARY TOML
- CREATE NEW ENV FILE
- ADD ENV FILE TO GITIGNORE
- ENSURE THE ETHERSCAN ( OR EQUIVALENT) API KEY IS CORRECT FOR THE TARGET CHAIN
- COPY AN EXISTING DEPLOY FILE AND CHANGE THE PARAMS TO THE TARGET CHAIN ENV FILE
- RUN THE DEPLOY SCRIPT
- EXTRACT THE PROXY ADDRESS AND ADD TO /scripts/common/deployments.sol
- IN /scripts/common/deployments.sol UPDATE THE KECCACK ENV LIST AT TOP OF FILE
- IN /scripts/common/deployments.sol UPDATE THE params FUNCTION IF ELSE BLOCK
- COPY AN EXSTING UPGRADE FILE AND COMMENT OUT ALL COMMAND LINES EXCEPT FIRST. THEN CHANGE THE LAST ARGUMENT TO MATCH THE KECCAK SELECTOR CREATED ABOVE
- RUN THE UPGRADE SCRIPT UNTIL ALL COMMANDS HAVE BEEN EXECUTED TO UPGRADE THE CONTRACT TO THE LATEST VERSION ONE AT A TIME
- REGISTER THE KEY ON THE SMART CONTRACT
- DONE