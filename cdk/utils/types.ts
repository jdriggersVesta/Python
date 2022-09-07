export interface BuildConfigType {
  readonly App: string;
  readonly Environment: string;
  readonly AWSAccountID: string;
  readonly AWSProfileRegion: string;
  readonly VpcId?: string;
  readonly CDKAssetsBucket: string;
  readonly RAM: number;
  readonly CPU: number;
  readonly NumInstances: number;
}