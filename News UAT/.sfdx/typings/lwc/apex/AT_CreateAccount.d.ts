declare module "@salesforce/apex/AT_CreateAccount.lookupABN" {
  export default function lookupABN(param: {abn: any}): Promise<any>;
}
declare module "@salesforce/apex/AT_CreateAccount.duplicateCheck" {
  export default function duplicateCheck(param: {name: any, abn: any, street: any, city: any, postcode: any, state: any, country: any}): Promise<any>;
}
declare module "@salesforce/apex/AT_CreateAccount.getRecordTypes" {
  export default function getRecordTypes(): Promise<any>;
}
declare module "@salesforce/apex/AT_CreateAccount.lookupAddress" {
  export default function lookupAddress(param: {address: any, sourceOfTruth: any}): Promise<any>;
}
