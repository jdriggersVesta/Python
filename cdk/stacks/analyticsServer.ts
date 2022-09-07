import { Stack, StackProps } from 'aws-cdk-lib';
import { BlockDeviceVolume, GenericLinuxImage, Instance, InstanceClass, InstanceSize, InstanceType, Peer, Port, SecurityGroup, SubnetType, Vpc } from 'aws-cdk-lib/aws-ec2';
import { Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { BuildConfigType } from '../utils/types';

export default class AnalyticsServer extends Stack {

  constructor(
    scope: Construct,
    id: string,
    props: StackProps,
    buildConfig: BuildConfigType
  ) {
    super(scope, id, props);

    const vpc = Vpc.fromLookup(this, 'VPC', {
      vpcId: buildConfig.VpcId,
    });

    // Security group to only allow inbound and outbound to connections
    // to nat-bastion
    const AnalyticsServerSG = new SecurityGroup(this, 'AnalyticsServerSG', {
      vpc,
      description: 'Restrict juniper server access as it may run python code from third parties',
      allowAllOutbound: false,
    });
    AnalyticsServerSG.addIngressRule(
      Peer.ipv4('10.0.10.77/32'),
      Port.tcp(22),
      'allow inbound traffic from nat-bastion'
    );
    AnalyticsServerSG.addEgressRule(
      Peer.ipv4('10.0.10.77/32'),
      Port.tcp(22),
      'allow outbound traffic to nat-bastion'
    );
    // JuniperServerSG.addEgressRule(
    //   Peer.ipv4('0.0.0.0/0'),
    //   Port.tcp(443),
    //   'allow HTTPS outbound traffic for software updates/installs'
    // );

    const analyticsPythonScriptsRole = new Role(this, 'analyticsPythonScriptsRole', {
      assumedBy: new ServicePrincipal('ec2.amazonaws.com'),
      // managedPolicies: [
      //   ManagedPolicy.fromAwsManagedPolicyName('AmazonS3ReadOnlyAccess'),
      // ],
    });

    new Instance(this, 'AnalyticsServerInstance', {
      vpc,
      vpcSubnets: { subnetType: SubnetType.PRIVATE_WITH_NAT },
      role: analyticsPythonScriptsRole,
      securityGroup: AnalyticsServerSG,
      keyName: 'devops-jorge',
      instanceName: 'AnalyticsServer',
      instanceType: InstanceType.of(InstanceClass.C5, InstanceSize.XLARGE2),
      machineImage: new GenericLinuxImage({
        'us-east-1': 'ami-0932d5903821bbb22'
      }),
      blockDevices: [
        {
          deviceName: '/dev/sda1',
          volume: BlockDeviceVolume.ebs(100),
        },
      ],
    });
  }
}
