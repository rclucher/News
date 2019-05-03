@isTest
private class CS_QuestionnaireAppControllerTest {
    
    @isTest static void testControllerMethods() {
        // Create test data
        // Accounts
        Account sAccount = new Account(Name = 'Test Account 1', No_Parent_Account__c = true);
        insert sAccount;

        // Opportunity
        Opportunity sOpportunity = new Opportunity(Name = 'Test 1', AccountId = sAccount.id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5));
        insert sOpportunity;

        // Questions
        list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
        
        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'ABC',
            Question_Text__c    = 'This is Question #1',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_TEXT,
            isActive__c         = true
            ));

        list<CS_Questions_Utilities.PicklistWrapper> li_PicklistWrappers = new list<CS_Questions_Utilities.PicklistWrapper>();
        li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('A', 'A'));
        li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('B', 'B'));
        li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('C', 'C'));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'ABC',
            Question_Text__c    = 'This is Question #2',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_PICKLIST,
            Answer_Picklist_Values__c = JSON.serialize(li_PicklistWrappers),
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'DEF',
            Question_Text__c    = 'This is Question #3',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'DEF',
            Question_Text__c    = 'This is Question #4',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #5',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_CHECKBOX,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #6',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_CURRENCY,
            Minimum_Length__c   = 12,
            Maximum_Length__c   = 20,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #7',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_DATE,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #8',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_EMAIL,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #9',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_NUMBER,
            Minimum_Length__c   = 12,
            Maximum_Length__c   = 20,
            isActive__c         = true
            ));

/*      li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #10',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_PERCENT,
            isActive__c         = true
            ));
*/
        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #11',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_PHONE,
            Minimum_Length__c   = 12,
            Maximum_Length__c   = 20,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #12',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_TEXT,
            Minimum_Length__c   = 12,
            Maximum_Length__c   = 20,
            isActive__c         = true
            ));

        li_QuestionstoInsert.add(new Question2__c(
            Section__c          = 'GHI',
            Question_Text__c    = 'This is Question #13',
            Answer_Type__c      = CS_Questions_Utilities.ANSWERTYPE_URL,
            isActive__c         = true
            ));
        
        insert li_QuestionstoInsert;

        // Rules
        list<Rule__c> li_RulestoInsert = new list<Rule__c>();
        
        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[0].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 10,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        list<string> li_PicklistValues = new list<string>();
        li_PicklistValues.add('Identify Prospects');

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[1].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_GENERAL,
            Sequence_Number__c  = 20,
            Object_Name_1__c    = 'Opportunity',
            Field_Name_1__c     = 'StageName',
            Field_Data_Type__c  = 'PICKLIST',
            Field_Value_Text__c = JSON.serialize(li_PicklistValues),
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[2].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 10,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            Enable_Field_Tracking__c = true,
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[3].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 20,
            When_to_Ask__c      = 'Order__c',
            When_to_View__c     = 'Opportunity',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD,
            Related_Record_Section__c = 'DEF',
            Related_Field_Label__c = 'Sales Rep Name',
            Related_Object_Name__c = 'Opportunity',
            Related_Field_name__c = 'Owner.Name',
            Help_Text__c        = 'Here is some help text',
            Sequence_Number__c  = 30,
            When_to_View__c     = 'Opportunity',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[4].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 10,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[5].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 20,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[6].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 30,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[7].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 40,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[8].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 50,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[9].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 60,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[10].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 70,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        li_RulestoInsert.add(new Rule__c(
            Question2__c        = li_QuestionstoInsert[11].id,
            Answer_Source__c    = CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
            Question_Type__c    = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
            Sequence_Number__c  = 80,
            When_to_Ask__c      = 'Opportunity',
            When_to_View__c     = 'Order__c',
            isActive__c         = true
            ));

        insert li_RulestoInsert;

        test.startTest();

        // test get all questions

        String allQuestionsString = CS_QuestionnaireAppController.getAllQuestionnairData(sOpportunity.Id);
        CS_QuestionnaireAppController.QuestionnaireResponse allQuestionsRes = (CS_QuestionnaireAppController.QuestionnaireResponse) JSON.deserialize(allQuestionsString, CS_QuestionnaireAppController.QuestionnaireResponse.class);
        System.assertNotEquals(allQuestionsRes, null);

        // test submit all the answers
        String submitResultString = CS_QuestionnaireAppController.submitQuestionnaire(allQuestionsString, sOpportunity.Id, false);
        CS_QuestionnaireAppController.QuestionnaireResponse submitResult = (CS_QuestionnaireAppController.QuestionnaireResponse) JSON.deserialize(submitResultString, CS_QuestionnaireAppController.QuestionnaireResponse.class);
        System.assertNotEquals(submitResult, null);

        // test error handling on submit all the answers
        String submitErrorResultString = CS_QuestionnaireAppController.submitQuestionnaire(null, sOpportunity.Id, false);
        CS_QuestionnaireAppController.QuestionnaireResponse submitErrorResult = (CS_QuestionnaireAppController.QuestionnaireResponse) JSON.deserialize(submitErrorResultString, CS_QuestionnaireAppController.QuestionnaireResponse.class);
        System.assertNotEquals(submitResult, null);
        test.stopTest();

    }


    
}