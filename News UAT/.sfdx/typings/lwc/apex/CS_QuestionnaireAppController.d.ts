declare module "@salesforce/apex/CS_QuestionnaireAppController.getAllQuestionnairData" {
  export default function getAllQuestionnairData(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/CS_QuestionnaireAppController.submitQuestionnaire" {
  export default function submitQuestionnaire(param: {results: any, recordId: any, isCompleted: any}): Promise<any>;
}
