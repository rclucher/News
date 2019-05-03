@isTest
private class CS_ViewBriefingFormController_Test 
{
    // coverage = %
    public static Briefing_Form__c salesBF;
    public static Briefing_Form__c cBF;
    public static Opportunity opp;
    public static Order__c order;
    
    @isTest static void salesBF_Cancel() 
    {
        preparedata();

        // Test execution
        Test.startTest();

        PageReference pageRef = Page.CS_ViewBriefingForm;
        pageRef.getParameters().put('bfId', String.valueOf(salesBF.Id));
        pageRef.getParameters().put('oppId', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);

        CS_ViewBriefingFormController vbfc = new CS_ViewBriefingFormController();

        vbfc.cancelBF();

        Test.stopTest();
    }

    @isTest static void salesBF_Quicksave() 
    {

        preparedata();

        // Test execution
        Test.startTest();

        PageReference pageRef = Page.CS_ViewBriefingForm;
        pageRef.getParameters().put('rtName', 'Campaign');
        pageRef.getParameters().put('oppId', String.valueOf(opp.Id));
        pageRef.getParameters().put('orderId', String.valueOf(order.id));
        Test.setCurrentPage(pageRef);

        CS_ViewBriefingFormController vbfc = new CS_ViewBriefingFormController();

        vbfc.quickSaveBF();

        Test.stopTest();
    }
    
    @isTest static void salesBF_Submit() 
    {
        preparedata();
        // Test execution
        Test.startTest();

        PageReference pageRef = Page.CS_ViewBriefingForm;
        order.Briefing_Form__c = cBF.Id;
        update order;
        system.debug(cBF.name);
		cBF.Name ='Test Briefing Form';
        pageRef.getParameters().put('bfId', String.valueOf(cBF.Id));
        pageRef.getParameters().put('oppId', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);
    
    
        CS_ViewBriefingFormController vbfc = new CS_ViewBriefingFormController();

        // vbfc.cancelBF();
        
        vbfc.submitBF();
        vbfc.quickSaveBF();
        //
        //System.assertEquals(new PageReference('/'+opp.Id), vbfc.cancelBF());
		
		List<Question__c> quesList = [Select id, Name,Question_Text__c,Answer_Format__c,Briefing_Form__c,Active__c,Mandatory__c,Mandatory_For__c,Sequence__c,Section_Name__c FROM Question__c];
		id bfid = [Select id from Briefing_Form__c limit 1].id;
		vbfc.getMapQuestionsWithAnswer(quesList,bfid);
        Test.stopTest();
    }


    
    
    @isTest static void campaignBF_Cancel() 
    {
        preparedata();
        // Test execution
        Test.startTest();

        PageReference pageRef = Page.CS_ViewBriefingForm;
        pageRef.getParameters().put('bfId', String.valueOf(salesBF.Id));
        pageRef.getParameters().put('oppId', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);
    
        CS_ViewBriefingFormController vbfc = new CS_ViewBriefingFormController();

        vbfc.cancelBF();

        Test.stopTest();
    }

    public static void preparedata() {
                // Sales Briefing Form 
        salesBF = new Briefing_Form__c();
        RecordType salesRTypes = [Select Name, Id From RecordType where sObjectType='Briefing_Form__c' and Name = 'Sales' and isActive=true];
        salesBF.RecordTypeId = salesRTypes.Id;
        salesBF.Name = 'Sales Briefing Form - Unit Test';
        salesBF.Status__c = 'Draft';
        insert salesBF;

        cBF = new Briefing_Form__c();
        RecordType cRTypes = [Select Name, Id From RecordType where sObjectType='Briefing_Form__c' and Name = 'Campaign' and isActive=true];
        cBF.RecordTypeId = cRTypes.Id;
        cBF.Name = 'Campaign Briefing Form - Unit Test';
        cBF.Status__c = 'Draft';
        cBF.Sales_Briefing_Form__c  = salesBF.Id;
        insert cBF;

        // Question 1: 
        Question__c q1 = new Question__c();
        q1.Name = 'Sales / Favorite TV Program - Question';
        q1.Question_Text__c = 'What is your favourite TV show?';
        q1.Answer_Format__c = 'Text';
        q1.Briefing_Form__c = 'Campaign; Sales';
        q1.Active__c = True;
        q1.Mandatory__c = True;
        q1.Mandatory_For__c = 'Tier 3';
        q1.Sequence__c = 10;
        q1.Section_Name__c = 'RTB';
        insert q1;
        
        // Question 2: 
        Question__c q2 = new Question__c();
        q2.Name = 'Sales / Birthplace - Question';
        q2.Question_Text__c = 'What is your birthplace?';
        q2.Answer_Format__c = 'Text';
        q2.Predefined_Offered_Answers__c = 'Split,Sydney';
        q2.Briefing_Form__c = 'Campaign; Sales';
        q2.Active__c = True;
        q2.Mandatory__c = True;
        q2.Mandatory_For__c = 'Tier 3';
        q2.Sequence__c = 10;
        q2.Section_Name__c = 'SEM';
        insert q2;

        // Question 3: 
        Question__c q3 = new Question__c();
        q3.Name = 'Sales / Hobby - Question';
        q3.Question_Text__c = 'What is your favourite hobby?';
        q3.Answer_Format__c = 'Text';
        q3.Briefing_Form__c = 'Campaign; Sales';
        q3.Active__c = True;
        q3.Mandatory__c = True;
        q3.Mandatory_For__c = 'Tier 2';
        q3.Sequence__c = 20;
        q3.Section_Name__c = 'RTB';
        insert q3;

        // Question 4: 
        Question__c q4 = new Question__c();
        q4.Name = 'Sales / Favorite Team - Question';
        q4.Question_Text__c = 'What is your favourite football team?';
        q4.Answer_Format__c = 'Number';
        q4.Briefing_Form__c = 'Campaign; Sales';
        q4.Active__c = True;
        q4.Mandatory__c = True;
        q4.Mandatory_For__c = 'Tier 1';
        q4.Sequence__c = 20;
        q4.Section_Name__c = 'SEM';
        insert q4;

        Question__c q5 = new Question__c();
        q5.Name = 'Sales rep';
        q5.Question_Text__c = 'Sales Rep';
        q5.Answer_Format__c = 'Text';
        q5.Briefing_Form__c = 'Campaign; Sales';
        q5.Active__c = True;
        q5.Mandatory__c = True;
        q5.Mandatory_For__c = 'Tier 1';
        q5.Sequence__c = 20;
        q5.Section_Name__c = 'SEM';
        q5.Output_Opportunity_Mapping__c = 'Owner.Name';
        insert q5;

        // Answer 1:
        Answer__c a1 = new Answer__c();
        a1.Name = 'Sales / Favorite TV Program - Answer';
        a1.Briefing_Form__c = cBF.Id;
        a1.Question__c = q1.Id;
        a1.Selected_Answer__c = 'Homeland';
        insert a1;

        // Answer 2:
        Answer__c a2 = new Answer__c();
        a2.Name = 'Sales / Birthplace - Answer';
        a2.Briefing_Form__c = salesBF.Id;
        a2.Question__c = q2.Id;
        a2.Selected_Answer__c = 'Lisbon';
        insert a2;

        // Answer 3:
        Answer__c a3 = new Answer__c();
        a3.Name = 'Sales / Hobby - Answer';
        a3.Briefing_Form__c = salesBF.Id;
        a3.Question__c = q3.Id;
        a3.Selected_Answer__c = 'Football';
        insert a3;

        // Answer 4:
        Answer__c a4 = new Answer__c();
        a4.Name = 'Sales / Favorite Team - Answer';
        a4.Briefing_Form__c = salesBF.Id;
        a4.Question__c = q4.Id;
        a4.Selected_Answer__c = 'S.L. Benfica';
        insert a4;

        // Customer Account
        Account acc = new Account();
        RecordType accountRTypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Business Account' and isActive=true];
        acc.RecordTypeId = accountRTypes.Id;
        acc.Name = 'Customer Account - Unit Test';
        acc.No_Parent_Account__c = True;
        acc.Phone = '1234567890';
        acc.Type = 'Non Account Managed';
        acc.Account_Type__c = 'General';
        acc.Revenue_Group__c = 'Retail';
        acc.Status__c = 'Active';
        //acc.Tier__c = 'Tier 1';
        insert acc;

        // Sales Opportunity
        opp = new Opportunity();
        RecordType opportunityRTypes = [Select Name, Id From RecordType where sObjectType='Opportunity' and Name = 'Multi-Channel' and isActive=true];
        opp.RecordTypeId = opportunityRTypes.Id;
        opp.Name = 'Sales Briefing Form Opportunity - Unit Test';
        opp.Account = acc;
        opp.Type = 'Core Activity';
        opp.CloseDate = Date.Today()+100;
        opp.OpportunityGroup__c = 'NewsXtend';
        opp.Campaign_Start_Date__c = Date.Today()+101;
        opp.StageName = 'Identify Prospects';
        opp.ForecastCategoryName = 'Omitted';
        opp.Briefing_Form__c = salesBF.Id;

        insert opp;

        order = new Order__c();
        order.Status__c = 'In Progress';
        insert order;

    }
}