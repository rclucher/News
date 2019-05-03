/*------------------------------------------------------------
Author:			Kevin Wu	
Company:		CloudSense
Description:	Controller for the Campaign brief questionnaire component
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jul 18		Kevin Wu			Created
------------------------------------------------------------*/
public with sharing class CS_QuestionnaireAppController {	
	@AuraEnabled
    public static String getAllQuestionnairData(String recordId) {
        QuestionnaireResponse res = new QuestionnaireResponse(); 

        try{
            CS_QuestionnaireService csqController = new CS_QuestionnaireService();
            csqController.buildQuestionsForDisplay(recordId);
            list<CS_Questions_Utilities.SectionWrapper> mp_liQuestions = csqController.mp_liQuestions;

            res.code = 2000;
            res.message = 'Success';
            res.details = JSON.serialize(mp_liQuestions);
        }catch(Exception ex){
            res.code = 5000;
            res.message = 'System errors occured when retrieving the list of questions. Please contact your System Administrator.';
            res.details = ex.getMessage();
        }
        return JSON.serialize(res);
    }


    @AuraEnabled
    public static String submitQuestionnaire(String results, String recordId, Boolean isCompleted) {
    	QuestionnaireResponse res = new QuestionnaireResponse(); 

    	try{
    		list<CS_Questions_Utilities.SectionWrapper> mp_liQuestions = (list<CS_Questions_Utilities.SectionWrapper>) JSON.deserialize(results, list<CS_Questions_Utilities.SectionWrapper>.class);
	        CS_QuestionnaireService csqController = new CS_QuestionnaireService();
	        csqController.buildQuestionsForDisplay(recordId, isCompleted);
	        csqController.mp_liQuestions = mp_liQuestions;
            List<String> valMessagesList = csqController.validateAnswers();
			//rebuildQuestionWrappers();

            if(valMessagesList != null && valMessagesList.size()>0){
                res.code = 2100;
                res.message = 'Error';
                res.details = JSON.serialize(valMessagesList);
            }else{
                csqController.saveAnswers();
                res.code = 2000;
                res.message = 'Success';
                res.details = JSON.serialize(csqController.mp_liQuestions);
            }

		}catch(Exception ex){
			res.code = 5000;
			res.message = 'System error.';
			res.details = ex.getMessage();
		}
        
        return JSON.serialize(res);
    }

    public class QuestionnaireResponse{

    	public Integer code;
    	public String message;
    	public String details;
    }

}