declare module "@salesforce/apex/NewsQ_Dashboard.getDashboardInfo" {
  export default function getDashboardInfo(param: {username: any}): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getUsersOrRoles" {
  export default function getUsersOrRoles(param: {userRoleID: any}): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getTopicScores" {
  export default function getTopicScores(param: {pillarName: any, topicCount: any, userRoleID: any}): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getPillarScores" {
  export default function getPillarScores(): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getUserIDs" {
  export default function getUserIDs(param: {userRoleID: any}): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getPillarScores" {
  export default function getPillarScores(param: {userRoleID: any}): Promise<any>;
}
declare module "@salesforce/apex/NewsQ_Dashboard.getFinancials" {
  export default function getFinancials(param: {userIDs: any, roleIDs: any}): Promise<any>;
}
