public with sharing class CS_ViewBriefingFormController
{

    public class QAwrap 
    {
        public Integer numberValue { get; set; }
        public Date dateValue { get; set; }
        public List<SelectOption> picklistOptions { get; set; }
        public List<String> multiSelections { get; set; }
        
        public Question__c ques { get; set; }
        public Boolean questionMandatoryForTier { get; set; }
        
        public Answer__c ans { get; set; }
        public Briefing_Form__c briefForm { get; set; }
        public Opportunity opp { get; set; }
        public Answer__c salesAnswer { get; set; }
        
        public QAwrap (Question__c question, Opportunity opportunityRecord, String customerTier, Briefing_Form__c brieForm, map<id, Answer__c> mappedSalesQuesAnswers) 
        {
            this.opp = opportunityRecord;
            this.ques = question;
            SetQuestionMandatoryForTier(customerTier);
            //this.questionMandatoryForTier = this.ques.Mandatory__c != null && this.ques.Mandatory_For__c != null && customerTier != null && this.ques.Mandatory__c == True && this.ques.Mandatory_For__c == customerTier;
            this.ans = new Answer__c(Question__c = this.ques.Id);
            this.briefForm = brieForm;

            if (mappedSalesQuesAnswers != null && this.ques.Briefing_Form__c.contains('Campaign') && this.ques.Briefing_Form__c.contains('Sales') && this.briefForm.Sales_Briefing_Form__c !=null) {
                system.debug(mappedSalesQuesAnswers.get(question.Id) );
                if (mappedSalesQuesAnswers.get(question.Id) != null)
                    this.ans = mappedSalesQuesAnswers.get(question.Id).clone(false, true, false, false); 
                system.debug(ans);
            }

            SetValues();
            multiSelections = new List<String>();
            system.debug('***IVANA**'+this.ans.Selected_Answer__c);

        }

        public QAwrap (Question__c question, Answer__c answer, Opportunity opportunityRecord, String customerTier, Briefing_Form__c brieForm) 
        {
            this.opp = opportunityRecord;
            this.ques = question;
            SetQuestionMandatoryForTier(customerTier);
            //this.questionMandatoryForTier = this.ques.Mandatory__c != null && this.ques.Mandatory_For__c != null && customerTier != null && this.ques.Mandatory__c == True /*&& this.ques.Mandatory_For__c == customerTier*/;
            this.ans = answer;
            this.briefForm = brieForm;

            //if (this.ques.Briefing_Form__c.contains('Campaign') && this.ques.Briefing_Form__c.contains('Sales') && this.briefForm.Sales_Briefing_Form__c !=null) {
            //    this.salesAnswer = mappedSalesQuesAnswers.get(question.Id).clone(false, true, false, false); 
            //}
            SetValues();
            multiSelections = new List<String>();
        }

        private void SetQuestionMandatoryForTier(String customerTier)
        {
            if (this.ques.Mandatory_For__c != null) {
                List<String> tierList = this.ques.Mandatory_For__c.split(';');
                Set<String> tierSet = new Set<String>(tierList);
                this.questionMandatoryForTier = this.ques.Mandatory__c != null && this.ques.Mandatory_For__c != null && customerTier != null && this.ques.Mandatory__c == True && tierSet.contains(customerTier);
            }
        }

        private void SetOppMapping() 
        {
            try {
            String oppField = this.ques.Output_Opportunity_Mapping__c;
            if (oppField.contains('.')) 
            {
                List<String> oppObjectAndField = oppField.split('\\.');

                ans.Selected_Answer__c = String.valueOf(this.opp.getSobject(oppObjectAndField[0]).get(oppObjectAndField[1]));
            }
            else 
                ans.Selected_Answer__c = String.valueOf(this.opp.get(oppField));
            }
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', this.ques, 'Opportunity mapping is not set properly');
                            System.debug(ex.getMessage());

            }
        }

        private void SetValues() 
        {
            /*
            if (this.ques.Briefing_Form__c.contains('Campaign') && this.ques.Briefing_Form__c.contains('Sales') && this.briefForm.Sales_Briefing_Form__c !=null) {
                String ansquery =  'select ' + CS_Utils.getSobjectFields('answer__c') + ' from answer__c where question__c = \''+ this.ques.Id +'\' and briefing_form__c = \'' + this.briefForm.Sales_Briefing_Form__c+'\'';
                List<Answer__c> salesAns = database.query(ansquery);
                if (!salesAns.isEmpty() && salesAns.get(0).Selected_Answer__c != null)    
            */
            
            
            if (this.ques.Predefined_Offered_Answers__c != null) {
                this.picklistOptions = new List<SelectOption>();
                List<String> options = this.ques.Predefined_Offered_Answers__c.split(',');
                for (String o : options) {
                    picklistOptions.add(new SelectOption (o, o));
                }
            }
            
            if(this.ques.Output_Opportunity_Mapping__c != null && this.ques.Output_Opportunity_Mapping__c!='')  
                SetOppMapping();
        }
    }

    public Id recordTypeId { get; set; }
    public String rtName { get; set; }
    public Briefing_form__c briefingForm { get; set; }
    public Boolean viewBF { get; set; }
    public List<Question__c> questions { get; set; }
    public List<Answer__c> answers { get; set; }
    public List<String> sections { get; set; }
    public String bfName { get; set; }
    public Answer__c answer { get; set; }
    public Decimal ansNumber {get; set;}
    public Id orderId { get; set; }
    public List<String> salesSections { get; set; }
    public List<String> campaignSections { get; set; }
    
    public Boolean allMandantoryFieldsFilled { get; set; }
    public Boolean nameFilled { get; set; }

    public Opportunity salesOpp { get; set; }
    public Order__c campaignOrd { get; set; }

    public String context { get; set; }

    public Map<String, List<QAwrap>> sectionQuestions { get; set; }

    public Map<Id, Answer__c> getMapQuestionsWithAnswer (List<Question__c> quesList, Id bfId) {
        String ansquery =  'select ' + CS_Utils.getSobjectFields('answer__c') + ' from answer__c where question__c IN :quesList '+
                ' and briefing_form__c = \'' + bfId+'\' and Selected_Answer__c != null';

        List<Answer__c> salesAns = database.query(ansquery);
        Map<Id, Answer__c> mappedAnswers = new Map<Id, Answer__c>();
        if (!salesAns.isEmpty()) {    
            for (Answer__c ans : salesAns) {
                if (salesAns.get(0).Selected_Answer__c != null)
                    mappedAnswers.put(ans.Question__c, ans);
            }
            //this.ans = salesAns.get(0).clone(false, true, false, false);
        }
        return mappedAnswers;
    }

    public CS_ViewBriefingFormController () 
    {

        Id oppId = ApexPages.currentPage().getParameters().get('oppId');
        String oppquery =  'select Owner.Name,'+ CS_Utils.getSobjectFields('Opportunity') + ','+ UtilMethods.getSobjectRelatedFields('Account,Account') + ',' + 
        UtilMethods.getSobjectRelatedFields('Contact__r,Contact') + ' from Opportunity where Id=: oppId';
        system.debug(oppquery);
        salesOpp = database.query(oppquery);
        allMandantoryFieldsFilled = true;
        nameFilled = true;

        system.debug('>> in controller');
            
        if(ApexPages.currentPage().getParameters().get('bfId')!=null) 
        {
            Id bfId = ApexPages.currentPage().getParameters().get('bfId');
            String bfquery =  'select ' + CS_Utils.getSobjectFields('Briefing_form__c') + ', RecordType.Name from Briefing_form__c where Id=: bfId';
            briefingForm = database.query(bfquery);
            rtName = briefingForm.RecordType.Name;
            viewBF = true;
            
            String ansquery =  'select ' + CS_Utils.getSobjectFields('Answer__c') + ' from Answer__c where Briefing_form__c=: bfId';
            answers = database.query(ansquery);
            List<Order__c> orders = new list<order__c>();
            if (rtName == 'Campaign') {
                orders = [select id from order__c where briefing_form__c =: bfId];
                if (!orders.isEmpty())
                    campaignOrd = orders[0];
            }
            
            getAllQuestionsAndAnswers ();
        }
        else if (ApexPages.currentPage().getParameters().get('rtName')!=null)
        {
            rtName = ApexPages.currentPage().getParameters().get('rtName');
            recordTypeId = UtilMethods.getRecordTypeId ('Briefing_Form__c.'+rtName); 
            viewBF = false;
            
            if(ApexPages.currentPage().getParameters().get('orderId')!=null)    
                orderId = ApexPages.currentPage().getParameters().get('orderId');
            briefing_form__c salesBF;
            system.debug(orderId);
            if (orderId != null) {
                campaignOrd = [select id, briefing_form__c, Opportunity__c from order__c where id =: orderId];
                List<Briefing_Form__c> salesBFs = [select id from briefing_form__c where id in 
                (select briefing_form__c from Opportunity where id =: campaignOrd.Opportunity__c) ];
                if (!salesBFs.isEmpty())
                    salesBF = salesBFs.get(0); 
            }
            system.debug(salesBF);
            briefingForm = new briefing_form__c (recordTypeId = recordTypeId);
            if (salesBF!=null)
                briefingForm.Sales_Briefing_Form__c = salesBF.Id;
            
            answers = new List<Answer__c>();

            getAllQuestions ();
        }

        SortSectionList();
    }

    public void getAllQuestions () 
    {   
        // Get all the questions for this type of Briefing Form
        String query = 'select ' + CS_Utils.getSobjectFields('Question__c');
        query += ' from Question__c where Briefing_Form__c includes (\''+rtName+'\') AND Active__c = true ORDER By Sequence__c';
        questions = Database.query(query);

        // Get 'Customer Tier' to check if the Question is required for this Tier
        String customerTier = salesOpp.Account.Tier__c;
        
        // Wrap through Briefing Form Questions and build its structure organized in Sections
        sectionQuestions = new Map<String, List<QAwrap>>();
        map<id, Answer__c> mappedQuesAndAns;
        if (briefingForm.Sales_Briefing_Form__c != null)
            mappedQuesAndAns = getMapQuestionsWithAnswer (questions, briefingForm.Sales_Briefing_Form__c);
            //system.debug('>>'+mappedQuesAndAns);
        for (question__c q : questions) 
        {
            List<QAwrap> listQ = sectionQuestions.get (q.Section_Name__c);
            if (listQ == null)
                listQ = new List<QAwrap>();

            QAwrap qaw = new QAwrap(q, salesOpp, customerTier, briefingForm, mappedQuesAndAns);

            if (mappedQuesAndAns != null) {
                Answer__c answ =  mappedQuesAndAns.get(q.id);
                system.debug('**IVANA**'+answ);
                if( answ!= null && (answ.IsMultiAnswer__c!=null && answ.IsMultiAnswer__c == true)) 
                    qaw.multiSelections = answ.Selected_Answer__c.split(',');
            }
            listQ.add(qaw);
            system.debug('**IVANA**'+listQ);
            sectionQuestions.put(q.Section_Name__c, listQ);
        }
        sections = new List<String>(sectionQuestions.keySet());
    }

    public void getAllQuestionsAndAnswers () 
    {

        system.debug('>> getAllQuestionsAndAnswers');
        // Get all the questions for this type of Briefing Form
        String query = 'select ' + CS_Utils.getSobjectFields('Question__c');
        query += ' from Question__c where Briefing_Form__c includes (\' '+rtName+'\') AND Active__c = true ORDER By Sequence__c';
        map<id, answer__c> answerWithQues = new map<id, answer__c>();

        // Get 'Customer Tier' to check if the Question is required for this Tier
        String customerTier = salesOpp.Account.Tier__c;
        system.debug('**IVANA**'+answers);
        for (answer__c a : answers)
            answerWithQues.put(a.question__c, a);
                
        questions = Database.query(query);  
        sectionQuestions = new Map<String, List<QAwrap>>();
        system.debug('**IVANA**'+answerWithQues);
        map<id, Answer__c> mappedQuesAndAns;
        for (question__c q : questions) {
            answer__c a= answerWithQues.get(q.Id);
            system.debug('**IVANA**'+a);

            List<QAwrap> listQ = sectionQuestions.get (q.Section_Name__c);
            if (listQ == null)
                listQ = new List<QAwrap>();
             
            if (a!= null)
               {
                 QAwrap qaw = new QAwrap(q, a, salesOpp, customerTier, briefingForm);
                 if(a.IsMultiAnswer__c!=null && a.IsMultiAnswer__c == true) 
                    {
                        qaw.multiSelections = a.Selected_Answer__c.split(',');
                    }
                 listQ.add(qaw);              
               }
            else
                listQ.add(new QAwrap(q, salesOpp, customerTier, briefingForm, mappedQuesAndAns));
            sectionQuestions.put(q.Section_Name__c, listQ);
        
        }
        sections = new List<String>(sectionQuestions.keySet());

        //sections = SortSectionList(sections);
    }

    public void SortSectionList()
    {
        List<Briefing_Form_Section__mdt> sectionList = [SELECT Id, MasterLabel, DeveloperName, Briefing_Form_Type__c, Order__c FROM Briefing_Form_Section__mdt ORDER BY Order__c];

        salesSections = new List<String>();
        campaignSections = new List<String>();

        Set<String> sectionsSet = new Set<String>();
        sectionsSet.addAll(sections);
        List<String> finalSectionsList = new List<String>();
              
        Set<String> sectionType; 
        Map<Decimal, String> sortmap = new Map<Decimal, String>();
        if (!sectionList.isEmpty()) {
        for (Briefing_Form_Section__mdt formSection : sectionList) {
                sectionType = new Set<String>();
                if (formSection.Briefing_Form_Type__c.contains(',')) {

                    sectionType.addAll(new List<String>(formSection.Briefing_Form_Type__c.split(',')));
                }
                else
                    sectionType.add(formSection.Briefing_Form_Type__c);

                if (sectionsSet.contains(formSection.MasterLabel))
                    finalSectionsList.add(formSection.MasterLabel);

                if (sectionType.contains('Sales'))
                    salesSections.add(formSection.MasterLabel);
                else if (sectionType.contains('Campaign'))
                    campaignSections.add(formSection.MasterLabel);
            }
        }

        Set<String> tempsection = new Set<String>();
        tempsection.addAll(finalSectionsList);
        for (string temp : sectionsSet) {
            if (!tempsection.contains(temp))
                finalSectionsList.add(temp);
        }
        sections = new List<String> (finalSectionsList);
        
    }


    public void updateBriefingFormReference()
    {
        if (rtName == 'Campaign')
        {
            if (!viewBF) 
            {
                campaignOrd.briefing_form__c = briefingForm.Id;
                update campaignOrd;
            }
            else 
            {
                campaignOrd = [select id from order__c where briefing_form__c =: briefingForm.Id];
            }
        } 
        else if (rtname == 'Sales')
        {
            salesOpp.briefing_form__c = briefingForm.Id;
            update salesOpp;
        }
        else
        { /* do nothing */ }
    }

    public String redirectTo()
    {
        system.debug('Inside redirectTo rtname ->>> ' + rtName);
        if (rtName == 'Campaign')
        {
            system.debug('Inside redirectTo CAMPAIGN ID ->>> ' + campaignOrd.Id);
            return campaignOrd.Id;
        }
        else if (rtname == 'Sales')
        {
            system.debug('Inside redirectTo SALES ID ->>> ' + salesOpp.Id);
            return salesOpp.Id;
        }
        else
            return '';
    }

    public PageReference submitBF() 
    {
        if (briefingForm.status__c != 'Completed')
            briefingForm.status__c = 'Completed';
        
        allMandantoryFieldsFilled = True;
        nameFilled = True;
        system.debug(allMandantoryFieldsFilled);

        if (briefingForm.Name == null || briefingForm.Name == '') {
            nameFilled = false;
            return null;
            system.debug(briefingForm.name);
        }
        upsert briefingForm; 
        

        for (List<QAwrap> wraps : sectionQuestions.values())
        {system.debug('**IVANA**'+wraps);
            for(QAwrap wrap : wraps) 
            {
                system.debug('***IVANA**'+wrap.ans.Selected_Answer__c);
                wrap.ans.Question_Text__c = wrap.ques.Question_Text__c != null ?
                                            wrap.ques.Question_Text__c.trim() :
                                            wrap.ques.Question_Text__c;
                if (wrap.ans.Selected_Answer__c != null && wrap.ans.Selected_Answer__c.trim().length() == 0)
                    wrap.ans.Selected_Answer__c = null;
                if (wrap.numberValue != null) 
                    wrap.ans.Selected_Answer__c = String.valueOf(wrap.numberValue);
                if (wrap.multiSelections != null && wrap.multiSelections.size() > 0) 
                  {
                    String sVals = '';
                    for (String stro : wrap.multiSelections) 
                      {
                        sVals = sVals+stro+',';
                      }               
                    sVals = sVals.removeEnd(',');
                    wrap.ans.Selected_Answer__c = sVals;
                    wrap.ans.IsMultiAnswer__c = true;
                  }    
                if (wrap.ans.briefing_form__c == null || wrap.ans.briefing_form__c != briefingForm.Id)
                    wrap.ans.briefing_form__c = briefingForm.Id;
                system.debug('***IVANA**'+wrap.ans.Id);
                if (wrap.ans.Id == null)
                    answers.add(wrap.ans);
                if (wrap.ques != null)
                    wrap.ans.Question_Text__c = wrap.ques.Question_Text__c != null ?
                                            wrap.ques.Question_Text__c.trim() :
                                            wrap.ques.Question_Text__c;

                if ((wrap.ans.Selected_Answer__c == null || wrap.ans.Selected_Answer__c =='') && wrap.questionMandatoryForTier == True)
                {
                    allMandantoryFieldsFilled = False;
                }
                system.debug('***IVANA**'+wrap.ans);
            }
        }
        if (!allMandantoryFieldsFilled) {
            answers = new List<Answer__c>();
            return null;
        }
        try {
            system.debug('**IVANA**'+answers);

            upsert answers;
        } catch(Exception ex)
        {
            ExLog.log(ex, 'config', answers, 'Did not upsert answers.');
            system.debug(ex.getMessage());
        }
        updateBriefingFormReference();

        return new PageReference('/'+redirectTo());
    }

    public PageReference quickSaveBF() 
    {
        if (briefingForm.status__c != 'Draft')
            briefingForm.status__c = 'Draft';
system.debug('>> in quickSaveBF');

        nameFilled = true;

        if (briefingForm.Name == null || briefingForm.Name == '') {
            nameFilled = false;
            return null;
        }
        upsert briefingForm;

        for (List<QAwrap> wraps : sectionQuestions.values())
        {
            for(QAwrap wrap : wraps) 
            {
                wrap.ans.Question_Text__c = wrap.ques.Question_Text__c != null ?
                                            wrap.ques.Question_Text__c.trim() :
                                            wrap.ques.Question_Text__c;
                if (wrap.multiSelections != null && wrap.multiSelections.size() > 0) 
                  {
                    String sVals = '';
                    for (String stro : wrap.multiSelections) 
                      {
                        sVals = sVals+stro+',';
                      }
                    
                    sVals = sVals.removeEnd(',');
                    wrap.ans.Selected_Answer__c = sVals;
                    wrap.ans.IsMultiAnswer__c = true;
                  }
                if (wrap.numberValue != null)
                    wrap.ans.Selected_Answer__c = String.valueOf(wrap.numberValue);
                if (wrap.ans.briefing_form__c == null || wrap.ans.briefing_form__c != briefingForm.Id)
                    wrap.ans.briefing_form__c = briefingForm.Id;
                if (wrap.ans.Id == null)
                    answers.add(wrap.ans);
                if (wrap.ques != null)
                    wrap.ans.Question_Text__c = wrap.ques.Question_Text__c;
            }
        }
        try {
            upsert answers;
        } catch(Exception ex)
        {
            ExLog.log(ex, 'config', answers, 'Did not upsert answers.');
            System.debug(ex.getMessage());
        }

        updateBriefingFormReference();
        return new PageReference('/'+redirectTo());
    }

    public PageReference CancelBF() 
    {
        return new PageReference('/'+redirectTo());
    }
}