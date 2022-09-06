import { App } from 'aws-cdk-lib';
import { BuildConfigType } from './types';

function ensureString(
    object: { [name: string]: any },
    propName: string
): string {
    if (!object[propName] || object[propName].trim().length === 0) {
        throw new Error(`${propName} does not exist or is empty`);
    }

    return object[propName];
}

function ensureNumber(
    object: { [name: string]: any },
    propName: string
): number {
    const value: number = parseInt(object[propName]);
    if (value == NaN) {
        throw new Error(`${propName} cannot be parsed as a number`);
    }

    return value;
}

export function getConfig(app: App) {
    const environment = app.node.tryGetContext('envConfig') || 'dev';
    const envProfileInfo = app.node.tryGetContext(environment);
    if (!envProfileInfo) {
        throw new Error(
            `Context variables for environment '${environment}' could not be found. Default environment can be changed by passing '-c envConfig=XXX' to the cdk command.`
        );
    }

    const buildConfig: BuildConfigType = {
        App: app.node.tryGetContext('App') || 'unnamed',
        Environment: environment,
        AWSAccountID: ensureString(envProfileInfo, 'AWSAccountID'),
        AWSProfileRegion: ensureString(envProfileInfo, 'AWSProfileRegion'),
        VpcId: ensureString(envProfileInfo, 'VpcId'),
        CDKAssetsBucket: ensureString(envProfileInfo, 'CDKAssetsBucket'),
        RAM: ensureNumber(envProfileInfo, 'RAM'),
        CPU: ensureNumber(envProfileInfo, 'CPU'),
        NumInstances: ensureNumber(envProfileInfo, 'NumInstances'),
    };

    return buildConfig;
}
