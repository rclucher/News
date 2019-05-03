public with sharing class ScorecardSurveyAppExtension {
    
    // SCORECARD VARIABLES
    public Id selectedSurvey {get;set;}
    public Boolean surveyError {get;set;}
    public String surveyErrorMessage {get;set;}
    public Integer currentStep {get;set;}
    public Integer currentProgress {get;set;}
    public Map<Id, List<Survey_Question_Choice__c>> sqcMap {get;set;}
    public Id TaskId {get;set;}
    
    public Integer possibleScore {get;set;}
    public Integer possibleBonus {get;set;}
    public Integer currentScore {get;set;}
    public Integer currentBonus {get;set;}
    public Integer totalScore {get;set;}
    // / SCORECARD VARIABLES
    
    // SURVEY FORCE VARIABLES
    public String  qQuestion                      {get; set;}
    public Boolean qRequired                      {get; set;}
    public String  qChoices                       {get; set;}
    public String surveyName                        {get; set;}
    public String surveyHeader                {get; set;}
    public String surveyId                          {get;
                                                     set{
                                                         this.surveyId = value;
                                                         init();
                                                     }
                                                    }
    public String renderSurveyPreview           {get; set;}
    public String questionName                    {get; set;}
    public String questionType                    {get; set;}
    public Boolean questionRequired             {get; set;}
    public List<SelectOption> singleOptions   {get; set;}
    public List<question> allQuestions        {get; set;}
    public List<String> responses                   {get; set;}
    public Integer allQuestionsSize               {get; set;}
    public String  templateURL                {get; set;}
    public String  surveyThankYouText         {get; set;}
    public String surveyContainerCss {get; set;}
    public String  surveyThankYouURL          {get; set;}
    public String  caseId                     {get; set;}
    public String contactId {get;set;}
    public String anonymousAnswer {get;set;}
    public List<SelectOption> anonymousOrUser {get;set;}
    public Boolean isInternal {get;set;}
    public String baseURL {get;set;}
    
    public String userId{get;set;}
    public String userName{get;set;}
    public String surveyTakerId {get;set;}
    public Boolean thankYouRendered{get;set;}
    public List<String> newOrder {get;set;}
    
    // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
    // Added below set of variable for survey edit functionality
    public List<SurveyTaker__c> surveyTakerList {get; set;}
    // / SURVEY FORCE VARIABLES
    public boolean editSurveySelectedFlag {get; set;}
    public boolean editExistingSurveyResponse {get; set;}
    
    public Map<Id, List<SurveyQuestionResponse__c>> surveyResponseMap;
    
    public ScorecardSurveyAppExtension(ApexPages.StandardController controller) {
        //SURVEY ERROR INFORMATION
        surveyError = false;
        surveyErrorMessage = '';
        currentStep = 1;
        TaskId = Apexpages.currentPage().getParameters().get('Id');
        
        // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
        // Added below set of code for survey edit functionality
        
        selectedSurvey = Apexpages.currentPage().getParameters().get('surveyId');
        surveyTakerId = Apexpages.currentPage().getParameters().get('surveyTakerId');
        
        surveyTakerList = new List<SurveyTaker__c>([Select Contact__c, Survey__c, Survey__r.Name, Taken__c, 
                                                    TaskId__c, Completed_By__c, Total_Score__c, Final_Score__c, 
                                                    LastModifiedById , LastModifiedDate, CreatedDate, CreatedById 
                                                    from SurveyTaker__c 
                                                    where TaskId__c = :TaskId
                                                    ORDER BY CreatedDate DESC]);
        surveyResponseMap = new Map<Id, List<SurveyQuestionResponse__c>>();
        
        if(surveyTakerId != null && surveyTakerId != ''){
            editExistingSurveyResponse = true;
            surveyResponseMap = getAvailableResponse();
            beginSurvey();
            calculateRunningScore();
        }
        else{
            editExistingSurveyResponse = false;
        }
    }
    
    // SCORECARD FUNCTIONS
    public Map<Id, List<SurveyQuestionResponse__c>> getAvailableResponse(){
        Map<Id, List<SurveyQuestionResponse__c>> resonses = new Map<Id, List<SurveyQuestionResponse__c>>();
        
        for(SurveyQuestionResponse__c sq:[Select of_Time_Question_was_Responded_to__c, FailedCompliance__c, Has_Question_Changed__c, Compliance_Question__c, NotApplicable__c, OldResponse__c, Max_Weight__c, Original_Question__c, Response__c, Response_Weight__c, Survey_Question__c, Survey_Question_Choice__c, SurveySection__c, SurveyTaker__c from SurveyQuestionResponse__c where SurveyTaker__c =:surveyTakerId]){
            List<SurveyQuestionResponse__c> tempList = new List<SurveyQuestionResponse__c>();
            
            if(resonses.containsKey(sq.Survey_Question__c))
                tempList = resonses.get(sq.Survey_Question__c);
            
            tempList.add(sq);
            resonses.put(sq.Survey_Question__c, tempList);  
            
        }
        System.debug('resonses' + resonses.size());
        System.debug('resonses' + resonses);
        return resonses;
    }
    
    // SCORECARD FUNCTIONS
    public List<SelectOption> getAvailableSurveys(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','Please select a survey'));
        
        List<Survey__c> surveys = new List<Survey__c>([SELECT Id, Name FROM Survey__c WHERE RecordType.Name = 'Agent Scorecard' ORDER BY Name]);
        for(Survey__c s:surveys){
            options.add(new SelectOption(s.Id, s.Name));
        }
        
        return options;
    }
    
    public Void beginSurvey(){
        surveyError = false;
        if(selectedSurvey == null){
            surveyError = true;
            surveyErrorMessage = 'You have not selected a survey. Please select one before continuing.';
        }else{
            surveyError = false;
            retrieveSQC();
            SurveyForceInit();
        }
    }
    
    public Void retrieveSQC(){
        if(selectedSurvey != null){
            //GET A LIST OF CHOICES FROM CHILD OBJ
            sqcMap = new Map<Id, List<Survey_Question_Choice__c>>();
            List<Survey_Question_Choice__c> sqcList = new List<Survey_Question_Choice__c>([SELECT Id, Choice__c, OrderNumber__c, Survey_Question__c, Weight__c, Label__c, Survey_Question__r.Type__c FROM Survey_Question_Choice__c WHERE Survey_Question__r.Survey__c =:surveyId ORDER BY Survey_Question__c, OrderNumber__c ASC]);
            for(Survey_Question_Choice__c sqc :sqcList){
                if(sqcMap.containsKey(sqc.Survey_Question__c)){
                    sqcMap.get(sqc.Survey_Question__c).add(sqc);
                }else{
                    sqcMap.put(sqc.Survey_Question__c, new List<Survey_Question_Choice__c>());
                    sqcMap.get(sqc.Survey_Question__c).add(sqc);
                }
            }
        }
    }
    
    public Void nextStep(){
        surveyError = false;
        progressCalc();
        currentStep = currentStep + 1;
    }
    
    public Void previousStep(){
        surveyError = false;
        progressCalc();
        if(currentStep > 1){
            currentStep = currentStep - 1;
        }
    }
    
    public Void goToStep(){
        surveyError = false;
        progressCalc();
        currentStep = Integer.ValueOf(Apexpages.currentPage().getParameters().get('selectedStep'));
    }
    
    public Void progressCalc(){
        
        //Item-00625 DD ASFB-03 - Running Score
        
        Integer completedSteps = 0;
        for(question q:allQuestions){
            if((q.renderSelectRadio == 'true' || q.renderSelectRadioWeight == 'true')&& q.selectedOption != '' && q.selectedOption != null){
                completedSteps = completedSteps + 1;
                q.answered = true;
            }else if(q.renderSelectCheckboxes == 'true' &&  q.selectedOptions.size() > 0){
                completedSteps = completedSteps + 1;
                q.answered = true;
            }else if(q.renderFreeText == 'true' &&  q.choices != null && q.choices != ''){
                completedSteps = completedSteps + 1;
                q.answered = true;
            }else if((q.renderSelectRow == 'true' || q.renderSelectRowWeight == 'true') &&  q.selectedOption != '' && q.selectedOption != null){
                completedSteps = completedSteps + 1;
                q.answered = true;
            }else{
                q.answered = false;
            }
        }
        
        currentProgress = completedSteps;
    }
    
    public void calculatePossibleScore(){
        
        //Item-00625 DD ASFB-03 - Running Score
        //reset all variables
        possibleScore = 0;
        possibleBonus = 0;
        
        //loop through the questions wrapper
        for (question q : allQuestions){
            Integer maxScore = 0;
            //only include questions hat contribute to the score
            if((q.questionType=='Single Select-Vertical-Weighted' || q.questionType=='Single Select-Horizontal-Weighted') && q.selectedOption != 'N/A'){
                maxScore = 0;
                if(sqcMap.containsKey(q.Id)){
                    for(Survey_Question_Choice__c sqc :sqcMap.get(q.Id)){
                        if(sqc.Weight__c > maxScore){
                            maxScore = Integer.valueOf(sqc.Weight__c);
                        }
                    }
                }
            }
            // NCS-00574 darshan.gosar@bankofamerica.com Added q.surveySection != null condition to avoid null pointer exception
            if(q.surveySection != null && q.surveySection.toUpperCase() == 'BONUS POINTS'){
                possibleBonus += maxScore;
            }else{
                possibleScore += maxScore;
            }
        }
        
        System.debug('possibleScore' + possibleScore);
        System.debug('possibleBonus' + possibleBonus);
        
        calculateRunningScore();
        
    }
    
    public void calculateRunningScore(){
        
        //Item-00625 DD ASFB-03 - Running Score
        //reset all variables
        currentScore = 0;
        currentBonus = 0;
        totalScore = 0;
        Boolean failedCompliance = false;
        
        //loop through the questions wrapper
        for (question q : allQuestions){
            //check if compliance
            // NCS-00574 darshan.gosar@bankofamerica.com Added sqcMap.containsKey(q.Id) condition to avoid null pointer exception
            if(q.questionType == 'True/False' && q.compliance && sqcMap.containsKey(q.Id)){
                for(Survey_Question_Choice__c sqc :sqcMap.get(q.Id)){
                    // 2017-02-10 Item-00750 louis.wang@bluewolf.com - Salesforce does not allow comparison of String and Id. Need to Cast the Id as String.
                    if(q.selectedOption == String.valueOf(sqc.Id) && sqc.Choice__c.toLowerCase() == 'false'){
                        failedCompliance = true;
                    }
                }
                //only include questions hat contribute to the score
            }else if((q.questionType=='Single Select-Vertical-Weighted' || q.questionType=='Single Select-Horizontal-Weighted') && q.selectedOption != null && q.selectedOption != 'N/A'){
                if(sqcMap.containsKey(q.Id)){
                    for(Survey_Question_Choice__c sqc :sqcMap.get(q.Id)){
                        // 2017-02-10 Item-00750 louis.wang@bluewolf.com - Salesforce does not allow comparison of String and Id. Need to Cast the Id as String.
                        if(q.selectedOption == String.valueOf(sqc.Id)){
                            // NCS-00574 darshan.gosar@bankofamerica.com Added q.surveySection != null condition to avoid null pointer exception
                            if(q.surveySection != null && q.surveySection.toUpperCase() == 'BONUS POINTS'){
                                currentBonus += Integer.valueOf(sqc.Weight__c);
                            }else{
                                currentScore += Integer.valueOf(sqc.Weight__c);
                            }
                        }
                    }
                }
            }
        }
        
        //calculate total score based on score + BONUS
        Integer calcScore = currentScore + currentBonus;
        if(failedCompliance){
            totalScore = 0;
        }else if(calcScore > possibleScore){
            totalScore = possibleScore;
        }else{
            totalScore = calcScore;
        }
        
        System.debug('totalScore' + totalScore);
        System.debug('possibleScore' + possibleScore);
        
        progressCalc();
    }
    // / SCORECARD FUNCTIONS
    
    
    // SURVEY FORCE FUNCTIONS
    public void SurveyForceInit()
    {
        // By default the preview is not showing up
        renderSurveyPreview = 'false';
        surveyId = selectedSurvey;
        init();
    }
    
    
    public void init()
    {
        if (surveyId != null){
            // Retrieve all necessary information to be displayed on the page
            allQuestions = new List<question>();
            setupQuestionList();
            setSurveyNameAndThankYou(surveyId);
            anonymousOrUser = new List<SelectOption>();
            anonymousOrUser.add(new SelectOption('Anonymous',System.Label.LABS_SF_Anonymous));
            anonymousOrUser.add(new SelectOption('User','User ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName()));
            anonymousAnswer = 'Anonymous';
            isInternal =true;
            newOrder = new List<String>();
            String urlBase = URL.getSalesforceBaseUrl().toExternalForm();
            baseURL = urlBase;
            
            userId = UserInfo.getUserId();
            userName = UserInfo.getName();
            
            String profileId = UserInfo.getProfileId();
            calculatePossibleScore();
            calculateRunningScore();
            try
            {
                Profile p = [select Id, UserType from Profile where Id=:profileId];
                if (p.UserType == 'Guest')
                {
                    isInternal = false;
                }
                else
                {
                    isInternal = true;
                }
            }
            catch (Exception e){
                isInternal = false;
            }
            
            
            thankYouRendered=false;
            
            
        }
    }
    
    
    //----------------------------------------------------------------------------//
    
    /* Called during the setup of the page.
Retrieve questions and responses from DB and inserts them in 2 lists. */
    public Integer setupQuestionList(){
        
        getAQuestion();
        return allQuestions.size();
    }
    
    
    /** Sets the survey's name variable
*  param: sID   The survey ID as specified in the DB
*/
    public void setSurveyNameAndThankYou(String sId){
        Survey__c s = [SELECT Name, Id, URL__c, Thank_You_Text__c, thankYouText__c, thankYouLink__c, Survey_Header__c, Survey_Container_CSS__c FROM Survey__c WHERE Id =:sId];
        surveyName = s.Name;
        surveyHeader = s.Survey_Header__c;
        templateURL = s.URL__c+'id='+sId;//+'&cId={!Contact.Id}'+'&caId='+'{!Case.id}';
        surveyThankYouText = s.Thank_You_Text__c;
        if (surveyThankYouText == null)
        {
            surveyThankYouText = System.Label.LABS_SF_Survey_Submitted_Thank_you;
        }
        surveyThankYouURL = s.thankYouLink__c;
        surveyContainerCss = s.Survey_Container_CSS__c;
    }
    
    //------------------------------------------------------------------------------//
    /*public Pagereference updateSurveyName(){
Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
s.Name = surveyName;
try{
update s;
}catch (Exception e){
Apexpages.addMessages(e);
}
return null;
} */
    
    //------------------------------------------------------------------------------//
    /* public Pagereference updateSurveyThankYouAndLink(){
Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
s.thankYouText__c = surveyThankYouText;
s.thankYouLink__c = surveyThankYouURL;
try{
update s;
}catch(Exception e){
Apexpages.addMessages(e);
}
return null;
}*/
    
    //------------------------------------------------------------------------------//
    /** When requested from the page - when the user clicks on 'Update Order' -
this function will reorganize the list so that it is displayed in the new order
*/
    public Pagereference refreshQuestionList(){
        setupQuestionList();
        return null;
    }
    
    
    
    //------------------------------------------------------------------------------//
    
    
    
    //------------------------------------------------------------------------------//
    /*private static boolean checkRequired(String response, Survey_Question__c question){
if(question.Required__c == true){
if(response == null || response =='NO RESPONSE')
return false;
}
return true;
} */
    
    /** Redirects the page that displays the detailed results of the survey,
from all users who took the survey.
*/
    /*public PageReference resultPage() {
return new PageReference('/apex/ResultsPage?id='+surveyId);
}*/
    
    
    //------------------------------------------------------------------------------//
    
    //------------------------------------------------------------------------------//
    
    /**
*/
    /*public List<String> getResponses() {
List<SurveyQuestionResponse__c> qr = [Select Survey_Question__c, SurveyTaker__c, Response__c, Name From SurveyQuestionResponse__c limit 100];
List<String> resp = new List<String>();
for (SurveyQuestionResponse__c r : qr) {
resp.add(r.Response__c);
}

return resp;
}  */
    
    
    
    
    
    /** Class: question
*  Retrieves the question information and puts it in the question object
*/
    public class question{
        public String   name                   {get; set;}
        public String   id                           {get; set;}
        public String   question               {get; set;}
        public String   orderNumber            {get; set;}
        public String   choices                {get; set;}
        public String   selectedOption         {get;set;}
        public List<String> selectedOptions {get;set;}
        public List<SelectOption> singleOptions{get; set;}
        public List<SelectOption> multiOptions {get; set;}
        public Boolean  required               {get; set;}
        public String   questionType           {get; set;}
        public String   surveySection          {get; set;}
        public String   surveyName               {get; set;}
        public String   renderFreeText             {get; set;}
        public String   renderSelectRadio      {get; set;}
        public String   renderSelectRadioWeight      {get; set;}
        public String   renderSelectCheckboxes {get; set;}
        public String   renderSelectRow        {get; set;}
        public String   renderSelectRowWeight        {get; set;}
        public List<String> responses              {get; set;}
        public String   singleOptionsForChart  {get; set;}
        public String   qResultsForChart         {get; set;}
        public List<String> strList              {get; set;} // The question's option as a list of string
        public List<Integer> resultsCounts       {get; set;} // The count of each response to a question's choices
        public List<SelectOption> rowOptions   {get; set;}
        public boolean  noData                 {get; set;}
        public Boolean answered {get;set;}
        public Boolean compliance {get;set;}
        public Boolean applicable {get; set;}   
        //ND 1289
        public Decimal maxWeight{get;set;}
        
        /** Fills up the question object
*  param:    Survey_Question__c
* WRAPPER CLASS #@#@
*/
        // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
        // Added List<SurveyQuestionResponse__c> as additional attribute, Changed sqcList to sqcMap
        public question(Survey_Question__c sq, Map<Id, Survey_Question_Choice__c> sqcMap, List<SurveyQuestionResponse__c> response) {
            
            name = sq.Name;
            id = sq.Id;
            question = sq.Question__c;
            orderNumber = String.valueOf(sq.OrderNumber__c+1);
            choices = sq.Choices__c;
            required = sq.Required__c;
            questionType = sq.Type__c;
            surveySection = sq.surveySection__c;
            compliance = sq.ComplianceQuestion__c;
            applicable = sq.NotApplicable__c;
            singleOptionsForChart = ' ';
            selectedOption = null;
            selectedOptions = new List<String>();
            
            System.debug('question: ' + question);
            System.debug('questionType: ' + questionType);
            System.debug('response: ' + response);
            
            if (sq.Type__c=='Single Select--Vertical'){
                renderSelectRadio='true';
                singleOptions = stringToSelectOptions(choices, applicable);
                
                renderSelectRadioWeight = 'false';
                renderSelectCheckboxes='false';
                renderFreeText='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'false';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode
                if(response.size() > 0 && response[0].Response__c != null){
                    if(response[0].Response__c == 'N/A')
                        selectedOption = 'N/A';
                    else        
                        selectedOption = singleSelectedResponse(singleOptions, response[0].Response__c);
                }
            }
            else if (sq.Type__c=='Multi-Select--Vertical'){
                renderSelectCheckboxes='true';
                multiOptions = stringToSelectOptions(choices, applicable);
                renderSelectRadio='false';
                renderSelectRadioWeight = 'false';
                renderFreeText='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'false';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode
                if(response.size() > 0)
                    selectedOptions = multiSelectedResponse(multiOptions, response);                
            }
            else if (sq.Type__c=='Single Select--Horizontal'){
                renderSelectCheckboxes='false';
                rowOptions = stringToSelectOptions(choices,applicable);
                renderSelectRadio='false';
                renderSelectRadioWeight = 'false';
                renderFreeText='false';
                renderSelectRow = 'true';
                renderSelectRowWeight = 'false';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode        
                if(response.size() > 0 && response[0].Response__c != null){
                    if(response[0].Response__c == 'N/A')
                        selectedOption = 'N/A';
                    else
                        selectedOption = singleSelectedResponse(rowOptions, response[0].Response__c);
                }            
            }
            else if (sq.Type__c=='Free Text'){
                renderFreeText='true';
                renderSelectRadio='false';
                renderSelectRadioWeight = 'false';
                renderSelectCheckboxes='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'false';
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode          
                if(response.size() > 0)
                    choices= response[0].Response__c;
            }
            else if(sq.Type__c=='Single Select-Vertical-Weighted'){
                renderSelectRadioWeight='true';
                singleOptions = objectToSelectOptions(sqcMap.values(), applicable);
                
                renderSelectRadio='false';
                renderSelectCheckboxes='false';
                renderFreeText='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'false';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode        
                if(response.size() > 0 && (response[0].Survey_Question_Choice__c != null || response[0].Response__c != null)){
                    if(response[0].Response__c == 'N/A')
                        selectedOption = 'N/A';
                    else
                        selectedOption = sqcMap.get(response[0].Survey_Question_Choice__c).Id;
                }
            }
            else if(sq.Type__c=='Single Select-Horizontal-Weighted'){
                renderSelectRadioWeight='false';
                singleOptions = objectToSelectOptions(sqcMap.values(), applicable);
                
                renderSelectRadio='false';
                renderSelectCheckboxes='false';
                renderFreeText='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'true';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode        
                if(response.size() > 0 && (response[0].Survey_Question_Choice__c != null || response[0].Response__c != null)){
                    if(response[0].Response__c == 'N/A')
                        selectedOption = 'N/A';
                    else
                        selectedOption = sqcMap.get(response[0].Survey_Question_Choice__c).Id;
                }
            }
            else if(sq.Type__c == 'True/False'){
                renderSelectRadio = 'true';
                singleOptions = objectToSelectOptions(sqcMap.values(), applicable);
                
                renderSelectRadioWeight='false';
                renderSelectCheckboxes='false';
                renderFreeText='false';
                renderSelectRow = 'false';
                renderSelectRowWeight = 'false';
                //selectedOption = 'N/A';
                selectedOptions = new List<String>();
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
                // Added below logic to prefill data during edit mode        
                if(response.size() > 0 && response[0].Response__c != null){
                    //NCS-00753 Allanah
                    // Added N/A option for true false
                    if(response[0].Response__c == 'N/A') {
                        selectedOption = 'N/A';
                    }
                    for(Survey_Question_Choice__c s: sqcMap.values()){
                        if(response[0].Response__c == s.Choice__c.toLowerCase()){
                            selectedOption = s.Id;
                            break;
                        }
                    }
                }
            }
            //responses= getResponses();
        }
        
        /** Splits up the string as given by the user and adds each option
*  to a list to be displayed as option on the Visualforce page
*  param: str   String as submitted by the user
*  returns the List of SelectOption for the visualforce page
*/
        private List<SelectOption> stringToSelectOptions(String str, Boolean na){
            if (str == '')
            {
                return new List<SelectOption>();
            }
            strList = str.split('\n');
            
            List<SelectOption> returnVal = new List<SelectOption>();
            if(na){
                returnVal.add(new SelectOption('N/A', 'N/A'));
            }
            Integer i = 0;
            for(String s: strList){
                if (s!='') {
                    if (s != 'null' && s!= null) {
                        String sBis = s.replace(' ', '%20');
                        singleOptionsForChart += s.trim()+'|';
                        
                        /*RSC2012-02-20
String st = s.replace (' ', '&nbsp;');
returnVal.add(new SelectOption(String.valueOf(i),st));
*/
                        returnVal.add(new SelectOption(String.valueOf(i),s));
                        System.debug('*****VALUES: ' + s);
                        i++;
                    }
                }
            }
            singleOptionsForChart = singleOptionsForChart.substring(0, singleOptionsForChart.length()-1);
            return returnVal;
        }
        
        private List<SelectOption> objectToSelectOptions(List<Survey_Question_Choice__c> sqcList, Boolean na){
            if (sqcList.isEmpty())
            {
                return new List<SelectOption>();
            }
            
            List<SelectOption> returnVal = new List<SelectOption>();
            if(na){
                returnVal.add(new SelectOption('N/A', 'N/A'));
            }
            for(Survey_Question_Choice__c sqc: sqcList){
                //if statement reh
                if (sqc.Survey_Question__r.Type__c == 'True/False'){
                    returnVal.add(new SelectOption(sqc.Id, sqc.Label__c));
                }else
                    returnVal.add(new SelectOption(sqc.Id,sqc.Choice__c));
            }
            
            return returnVal;
        }
        
        // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
        // Added below set of method for survey edit functionality
        private String singleSelectedResponse(List<SelectOption> ops, String response){
            String retString = '';
            
            for(SelectOption s: ops){
                if(s.getLabel() == response){
                    retString = s.getValue();
                    break;
                }
            }
            
            return  retString;
        }
        
        private List<String> multiSelectedResponse(List<SelectOption> ops, List<SurveyQuestionResponse__c> responses){
            List<String> retString = new List<String>();
            
            for(SelectOption s: ops){
                for(SurveyQuestionResponse__c sq: responses){
                    
                    if(s.getLabel().replace('\r', '') == sq.Response__c){
                        retString.add(s.getValue());
                        break;
                    }
                }
            }
            
            return  retString;
        }         
    }
    
    
    
    /** Fills up the List of questions to be displayed on the Visualforce page
*/
    public List<question> getAQuestion() {
        qQuestion = '';
        qChoices ='';
        
        List<Survey_Question__c> allQuestionsObject =
            [Select s.Type__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
             s.OrderNumber__c, s.Name, s.Choices__c, s.ComplianceQuestion__c, s.SurveySection__c, s.NotApplicable__c, s.Max_weight__c
             From Survey_Question__c s
             WHERE s.Survey__c =: surveyId ORDER BY s.OrderNumber__c, SurveySection__c];
        allQuestions = new List<question>();
        
        Double old_OrderNumber = 0;
        Double new_OrderNumber;
        Double difference = 0;
        
        //GET A LIST OF CHOICES FROM CHILD OBJ
        sqcMap = new Map<Id, List<Survey_Question_Choice__c>>();
        List<Survey_Question_Choice__c> sqcList = new List<Survey_Question_Choice__c>([SELECT Id, Choice__c, OrderNumber__c, Survey_Question__c, Weight__c, Label__c, Survey_Question__r.Type__c FROM Survey_Question_Choice__c WHERE Survey_Question__r.Survey__c =:surveyId ORDER BY Survey_Question__c, OrderNumber__c ASC]);
        for(Survey_Question_Choice__c sqc :sqcList){
            if(sqcMap.containsKey(sqc.Survey_Question__c)){
                sqcMap.get(sqc.Survey_Question__c).add(sqc);
            }else{
                sqcMap.put(sqc.Survey_Question__c, new List<Survey_Question_Choice__c>());
                sqcMap.get(sqc.Survey_Question__c).add(sqc);
            }
        }
        
        /* Make sure that the order number follow each other (after deleting a question, orders might not do so) */
        for (Survey_Question__c q : allQuestionsObject){
            new_OrderNumber = q.OrderNumber__c;
            difference = new_OrderNumber - old_OrderNumber - 1;
            if (difference > 0) {
                Double dd = double.valueOf(difference);
                Integer newOrderInt = dd.intValue();
                q.OrderNumber__c -= Integer.valueOf(newOrderInt);
            }
            old_OrderNumber = q.OrderNumber__c;
            List<Survey_Question_Choice__c> sqcRefList = new List<Survey_Question_Choice__c>();
            Map<Id, Survey_Question_Choice__c> sqcMapValue = new Map<Id, Survey_Question_Choice__c>();
            if(sqcMap.containsKey(q.Id)){
                sqcRefList = sqcMap.get(q.Id);
            }
            
            // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com 
            // Added below logic to pass question response during edit mode 
            for(Survey_Question_Choice__c sq: sqcRefList){
                sqcMapValue.put(sq.Id, sq);
            }
            question theQ;
            
            if(editExistingSurveyResponse && surveyResponseMap.containsKey(q.Id)) {
                theQ = new question(q, sqcMapValue, surveyResponseMap.get(q.Id));
            }  else {
                theQ = new question(q, sqcMapValue, new List<SurveyQuestionResponse__c>());
            }
            //ND
            theQ.maxWeight = q.Max_weight__c;
            allQuestions.add(theQ);
        }
        allQuestionsSize = allQuestions.size();
        System.debug('allQuestionsSize' + allQuestionsSize);
        System.debug('allQuestions' + allQuestions);
        
        return allQuestions;
    }
    
    public void submitResults(){
        surveyError = false;
        List <SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
        
        List <SurveyQuestionResponse__c> sqrDeleteList = new List<SurveyQuestionResponse__c>();
        
        for (question q : allQuestions){
            SurveyQuestionResponse__c sqr = new SurveyQuestionResponse__c();
            //Adsales 01289 - ND to calculate final score properly. 
            sqr.Max_Weight__c = q.maxWeight;
            // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
            // This would update existing record for all sceanrio except Multi checkbox response
            if(editExistingSurveyResponse && surveyResponseMap.containsKey(q.Id))
                sqr = surveyResponseMap.get(q.Id)[0];
            else
                sqr.Survey_Question__c = q.Id;            
            
            if (q.renderSelectRadio == 'true'){            
                
                if (q.required &&  (q.selectedOption == null || q.selectedOption == '')){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    surveyError = true;
                    surveyErrorMessage = 'Please fill out all required fields';
                    return;
                }
                
                // 2017-03-15 Item-00754 louis.wang@bluewolf.com - default NotApplicable to false. This aims to produce same FinalScore
                //                                                  for initial submit and subsequent submit.
                sqr.NotApplicable__c = false;
                if (q.selectedOption == null || q.selectedOption == ''){
                    sqr.Response__c = '';
                }else if(q.selectedOption == 'N/A'){
                    sqr.NotApplicable__c = true;
                    sqr.Response__c = 'N/A';
                    sqr.Response_Weight__c = null;
                    
                    // 2017-03-15 Item-00754 louis.wang@bluewolf.com - Update the logic around setting FailedCompliance.
                    //                               Note the current "else if" branch is targetting overlapping set of data to the next branch.
                    //                                This patch is required for compliance question to work, if re-submit is involved
                    if(q.questionType == 'True/False' && q.compliance){
                        sqr.FailedCompliance__c = false;
                    }
                }
                else if(q.questionType == 'True/False'){
                    System.debug('SELECTED OPTION IS HERE BEFORE IF STATEMENT **********    ' + q.selectedOption);
                    if(sqcMap.containsKey(q.Id)){
                        for(Survey_Question_Choice__c sqc :sqcMap.get(q.Id)){
                            // 2017-02-10 Item-00750 louis.wang@bluewolf.com - Salesforce does not allow comparison of String and Id. Need to Cast the Id as String.
                            if(q.selectedOption.toLowerCase() != 'true' && q.selectedOption.toLowerCase() != 'false' && q.selectedOption == String.valueOf(sqc.Id)){
                                q.selectedOption = sqc.Choice__c;
                            }
                            
                            // 2017-03-15 Item-00754 louis.wang@bluewolf.com - default FailedCompliance to false. 
                            //                                                    This attribute should only be set to true on compliance question
                            sqr.FailedCompliance__c = false;
                            if(q.selectedOption.toLowerCase() == 'false'){
                                System.debug('SELECTED OPTION IS HERE AFTER IF STATEMENT IS HERE **********    ' + q.selectedOption);                        
                                sqr.Response__c = 'false';
                                if(q.compliance)
                                {
                                    sqr.FailedCompliance__c = true;
                                }
                            }else{
                                System.debug('SELECTED OPTION ON ELSE STATEMENT IS HERE **********    ' + q.selectedOption);
                                sqr.Response__c = 'true';
                            }
                        }
                        
                        
                    }
                }else{
                    sqr.Response__c = q.singleOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
                }
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
                // Survey_Question__c is already set for edit mode & for new we set after initialization                
                //sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }else if (q.renderFreeText == 'true'){
                
                if (q.required && q.choices == ''){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    surveyError = true;
                    surveyErrorMessage = 'Please fill out all required fields';
                    return;
                }
                System.debug('*****Select Radio ' + q.choices);
                
                sqr.Response__c = q.choices;
                
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
                // Survey_Question__c is already set for edit mode & for new we set after initialization                    
                //sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }
            else if (q.renderSelectCheckboxes == 'true'){
                if (q.required && (q.selectedOptions == null || q.selectedOptions.size() == 0)){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    surveyError = true;
                    surveyErrorMessage = 'Please fill out all required fields';
                    return;
                }
                
                for (String opt : q.selectedOptions){
                    
                    // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
                    // Populating delete list if Survey is in edit mode. Evey checkbox selection create seperate entry in response table
                    // Hence on each update deleting old values & creating new as per code below                                    
                    if(editExistingSurveyResponse && surveyResponseMap.containsKey(q.Id)){
                        sqrDeleteList = surveyResponseMap.get(q.Id);
                    }
                    
                    sqr = new SurveyQuestionResponse__c();
                    if (opt == '' || opt == null){
                        sqr.Response__c = '';
                    }else if(opt == 'N/A'){
                        sqr.Response__c = 'N/A';
                    }else{
                        sqr.Response__c = q.multiOptions.get(Integer.valueOf(opt)).getLabel();
                    }
                    sqr.Survey_Question__c = q.Id;
                    sqrList.add(sqr);
                }
            }else if (q.renderSelectRow == 'true'){
                
                if (q.required && (q.selectedOption == null || q.selectedOption == '')){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    surveyError = true;
                    surveyErrorMessage = 'Please fill out all required fields';
                    return;
                }
                
                // 2017-03-15 Item-00754 louis.wang@bluewolf.com - default NotApplicable to false. This aims to produce same FinalScore
                //                                                  for initial submit and subsequent submit.
                sqr.NotApplicable__c = false;
                if (q.selectedOption == null || q.selectedOption == ''){
                    sqr.Response__c = '';
                }else if(q.selectedOption == 'N/A'){
                    sqr.NotApplicable__c = true;
                    sqr.Response__c = 'N/A';
                    sqr.Response_Weight__c = null;
                }else{
                    sqr.Response__c = q.rowOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
                }
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
                // Survey_Question__c is already set for edit mode & for new we set after initialization                
                //sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }else if(q.renderSelectRadioWeight == 'true' || q.renderSelectRowWeight == 'true'){
                
                
                
                Survey_Question_Choice__c selectedChoice;
                if(q.selectedOption != 'N/A'){
                    List<Survey_Question_Choice__c> sqcList = sqcMap.get(q.Id);
                    for(Survey_Question_Choice__c sqc :sqcList){
                        // 2017-02-10 Item-00750 louis.wang@bluewolf.com - Salesforce does not allow comparison of String and Id. Need to Cast the Id as String.
                        if(q.selectedOption == String.valueOf(sqc.Id)){
                            selectedChoice = sqc;
                        }
                    }
                }
                
                //if(selectedChoice != null){
                
                if (q.required &&  (q.selectedOption == null || q.selectedOption == '')){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    surveyError = true;
                    surveyErrorMessage = 'Please fill out all required fields';
                    return;
                }
                
                // 2017-03-15 Item-00754 louis.wang@bluewolf.com - default NotApplicable to false. This aims to produce same FinalScore
                //                                                  for initial submit and subsequent submit.
                sqr.NotApplicable__c = false;
                if (q.selectedOption == null || q.selectedOption == ''){
                    sqr.Response__c = '';
                }else if(q.selectedOption == 'N/A'){
                    sqr.NotApplicable__c = true;
                    sqr.Response__c = 'N/A';
                    sqr.Response_Weight__c = null;
                    sqr.Survey_Question_Choice__c = null;
                }else{
                    sqr.Response__c = selectedChoice.Choice__c;
                }
                // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
                // Survey_Question__c is already set for edit mode & for new we set after initialization                    
                //sqr.Survey_Question__c = q.Id;
                if(selectedChoice != null && selectedChoice.Weight__c != null){
                    sqr.Response_Weight__c = selectedChoice.Weight__c;
                    sqr.Survey_Question_Choice__c = selectedChoice.Id;
                }
                sqrList.add(sqr);
                
            }
        }
        
        // NCS-00626  2016-11-29 darshan.gosar@bluewolfgroup.com            
        // If its non edit mode then creating new response else upsert editing response & delete old checkbox responses                     
        if(!editExistingSurveyResponse){
            if(AddSurveyTaker()){
                for (SurveyQuestionResponse__c sqr : sqrList){
                    if(sqr.SurveyTaker__c == null)
                        sqr.SurveyTaker__c = surveyTakerId;
                }
                insert sqrList;
                thankYouRendered=true;
            }
        }
        else{
            for (SurveyQuestionResponse__c sqr : sqrList){
                if(sqr.SurveyTaker__c == null)
                    sqr.SurveyTaker__c = surveyTakerId;
            }
            upsert sqrList;
            
            if(sqrDeleteList.size() > 0)
                delete sqrDeleteList;
            
            thankYouRendered=true;
        }
        
        
    }
    
    
    private Boolean AddSurveyTaker()
    {
        String userId;
        
        if (surveyId == null){
            return false;
        }
        if(caseId != null && (caseId.toUpperCase() =='NONE'|| caseId.length()<5))
            caseId = null;
        if(contactId != null && (contactId.toUpperCase() =='NONE'|| contactId.length()<5))
            contactId = null;
        if (anonymousAnswer != 'Anonymous'){
            userId = UserInfo.getUserId();
        }else{
            userId = null;
        }
        
        if(anonymousAnswer != 'Anonymous' && (contactId != null || caseId != null)){
            List<SurveyTaker__c> check = [Select Contact__c, Survey__c, Case__c, User__c From SurveyTaker__c Where Contact__c=:contactId and Survey__c=:surveyId and Case__c = :caseId and User__c=:UserId];
            if(check != null && check.size()>0){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.LABS_SF_You_have_already_taken_this_survey));
                
                return false;
            }
        }
        
        
        
        SurveyTaker__c st = new SurveyTaker__c();
        st.Contact__c = contactId;
        st.Survey__c = surveyId;
        st.Taken__c = 'false';
        st.Case__c = caseId;
        st.User__c = UserInfo.getUserId();
        if(taskId != null){
            List<Task> tList = new List<Task>([SELECT Id, OwnerId FROM Task WHERE Id =:taskId LIMIT 1]);
            if(!tList.isEmpty()){
                st.Call_Agent__c = tList[0].OwnerId;
            }
        }
        
        if(TaskId != null){
            st.TaskId__c = TaskId;
        }
        insert st;
        surveyTakerId = st.Id;
        return true;
    }
    // / SURVEY FORCE FUNCTIONS
}