#!/usr/bin/env node
import { App, Tags } from 'aws-cdk-lib';
import { BuildConfigType } from './utils/types';
import { getConfig } from './utils/config';
import { DefaultStackSynthesizer } from 'aws-cdk-lib';
import AnalyticsServer from './stacks/analyticsServer';

const app = new App();
const buildConfig: BuildConfigType = getConfig(app);

Tags.of(app).add('app', buildConfig.App);
Tags.of(app).add('environment', buildConfig.Environment);
const stacksNamePrefix = `${buildConfig.App}-${buildConfig.Environment}`;

const service = new AnalyticsServer(
  app,
  `${stacksNamePrefix}-analyticsServer`,
  {
    synthesizer: new DefaultStackSynthesizer({
      fileAssetsBucketName: buildConfig.CDKAssetsBucket,
    }),
    env: {
      region: buildConfig.AWSProfileRegion,
      account: buildConfig.AWSAccountID,
    }
  },
  buildConfig
);
Tags.of(service).add(
  'stack',
  service.stackName
);
