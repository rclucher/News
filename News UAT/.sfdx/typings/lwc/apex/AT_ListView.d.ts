declare module "@salesforce/apex/AT_ListView.getObjectInfo" {
  export default function getObjectInfo(param: {configName: any}): Promise<any>;
}
declare module "@salesforce/apex/AT_ListView.getConfigs" {
  export default function getConfigs(): Promise<any>;
}
declare module "@salesforce/apex/AT_ListView.getRecords" {
  export default function getRecords(param: {configName: any, viewMode: any, maxCount: any, pageSize: any, pageNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/AT_ListView.getSummary" {
  export default function getSummary(param: {configName: any}): Promise<any>;
}
