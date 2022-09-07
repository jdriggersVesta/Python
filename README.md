# Analytics
Compilation of python scripts and sql procedures used by the analytics team.

## Analytics server
Virtual machine deployed to EC2 in AWS for the execution of python scripts.
This machine is intended to run scripts with special compute and/or ram requirements. It runs on a compute optimized node. Should the need arise, we can deploy it to a GPU accelerated node.

NOTE: Please keep a copy of scripts and generated data out of the server itself, as all storage in it should be considered temporary and prone to deletion.

### Start/stop server
To reduce costs, the server will be stopped while unused. If you need to use it, please ask the engineering team to start the server and let them know once you are finished so they can stop it.

### Access
Access is gated through our nat-bastion:
```
ssh -J nat-bastion analytics-server
```
Both nat-bastion and analytics-server should be defined in .ssh/config with the appropiate IPs and private keys. An example config file with made up data:
```
Host nat-bastion
  HostName 1.2.3.4
  User bastion-user
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/private-key-file
  ForwardAgent yes

Host analytics-server
  HostName 4.3.2.1
  User python-server-user
  IdentityFile ~/.ssh/private-key-file
```

### Deployment
This server is deployed with CDK. Configuration changes can be done on the stack file (./cdk/stacks/analyticsServer.ts) and the engineering team can review and deploy them with:
```
npx cdk -c envConfig=prod diff --exclusively analytics-prod-analyticsServer
npx cdk -c envConfig=prod deploy --exclusively analytics-prod-analyticsServer
```

### Software installs or updates
To allow software installs of new python libraries or updates, please ask the engineering team to temporarily allow outbound traffic by uncommenting the block:
```
    // JuniperServerSG.addEgressRule(
    //   Peer.ipv4('0.0.0.0/0'),
    //   Port.tcp(443),
    //   'allow HTTPS outbound traffic for software updates/installs'
    // );
```
on the analiticsServer.ts file and redeploying. Please be mindful of the threat posed by third party libraries. Even known, wide-used libraries have been compromised by bad actors to include malware by stealing developer credentials from maintainers. The less libraries, the better. This is why we restrict normal outbound access, so that when we get bitten by this type of supply chain attack, the malware cannot exfiltrate our data.
