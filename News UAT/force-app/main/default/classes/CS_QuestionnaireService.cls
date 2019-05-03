/*------------------------------------------------------------
Author:         Mike Jupp
Company:        CloudSense
Description:    
Test Class:     
History
<Date>      <Authors Name>      <Brief Description of Change>
Jun 18      Mike Jupp           Created
------------------------------------------------------------*/
public with sharing class CS_QuestionnaireService 
{
    /***********************************************************************************************************
        Members
    ***********************************************************************************************************/
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  Exception Classes & Enums
    public class X_Exception extends Exception{}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  Singular
    private id m_OpportunityId;
    private id m_CampaignOrderId;
    private id m_SalesOrderId;
    private string m_TargetObjectName;
    private string m_ProductNodeProductType;
    
    public boolean mp_bShowSaveButton                       {get; set;}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  Collections
    public list<CS_Questions_Utilities.SectionWrapper> mp_liQuestions   {get; set;}
    
    private map<id, CS_Questions_Utilities.AnswerWrapper> m_mapQuestiontoAnswers = new map<id, CS_Questions_Utilities.AnswerWrapper>();
    private map<id, Rule__c> m_mapRules = new map<id, Rule__c>();
    private map<string, list<Rule__c>> m_mapRelatedDataRules = new map<string, list<Rule__c>>();
    private map<id, list<Answer_to_Rule__c>> m_mapAnswertoAnswerRules;

    private map<string, set<string>> m_mapObjecttoFields;
    private map<id, list<Rule__c>> m_mapQuestiontoRules;
    
    private set<id> m_setRulesforCollection;
    private set<id> m_setRulesforConsumption;
    
    private map<string, map<string, set<string>>> m_mapSectiontoRelatedRecordData = new map<string, map<string, set<string>>>();

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  Wrapper classes


    /***********************************************************************************************************
        Constructor and Init
    ***********************************************************************************************************/
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Our Constructor
    public CS_QuestionnaireService()
    {

    }

    public void buildQuestionsForDisplay(string recordId, boolean isCampaignBriefCompleted)
    {
        try
        {
            buildQuestionsForDisplay(recordId);
            
            // Update fields on opportunity 
            updateCampaignBriefStatusOpportunity(m_OpportunityId, isCampaignBriefCompleted);
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
        }
    }


    /***********************************************************************************************************
        Worker Methods
    ***********************************************************************************************************/
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public void buildQuestionsForDisplay(string recordId)
    {
        // Work out what the calling object is and get applicable Rules
        map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
        map<string, map<string, set<string>>> map_sObjecttoFieldtoValues;
        
        m_ProductNodeProductType = null;

        // Were we called from an Opportunity record?
        if (map_ObjectToSObjectTypes.get('opportunity').getDescribe().getKeyPrefix() == recordId.subString(0, 3))
        {
            m_OpportunityId = recordId;

            // Get the related Campaign Order id
            list<Order__c> li_CampaignOrders =  [   select  id
                                                    from    Order__c
                                                    where   Opportunity__c = : recordId
                                                    limit   1
                                                ];
            
            if (!li_CampaignOrders.isEmpty())
            {
                m_CampaignOrderId = li_CampaignOrders[0].id;
            }

            // Get the related Sales Order id
            list<csmso__Sales_Order__c> li_SalesOrders =    [   select  id
                                                                from    csmso__Sales_Order__c
                                                                where   csmso__Opportunity__c = : recordId
                                                                limit   1
                                                            ];
            
            if (!li_SalesOrders.isEmpty())
            {
                m_SalesOrderId = li_SalesOrders[0].id;
            }

            m_TargetObjectName = 'opportunity';
            
        }
        // Or a Campaign Order record?
        else if (map_ObjectToSObjectTypes.get('order__c').getDescribe().getKeyPrefix() == recordId.subString(0, 3))
        {
            m_CampaignOrderId = recordId;
            
            // Get the related Opportunity id
            list<Order__c> li_CampaignOrders =  [   select  id,
                                                            Opportunity__c
                                                    from    Order__c
                                                    where   id = : recordId
                                                    limit   1
                                                ];
            
            if (!li_CampaignOrders.isEmpty())
            {
                // We still need the Oppty id for the Answers
                m_OpportunityId = li_CampaignOrders[0].Opportunity__c;

                // Get the related Sales Order id
                list<csmso__Sales_Order__c> li_SalesOrders =    [   select  id
                                                                    from    csmso__Sales_Order__c
                                                                    where   csmso__Opportunity__c = : m_OpportunityId
                                                                    limit   1
                                                                ];
                
                if (!li_SalesOrders.isEmpty())
                {
                    m_SalesOrderId = li_SalesOrders[0].id;
                }

                m_TargetObjectName = 'order__c';
            }
        }
        // Or a Product Order record?
        else if (map_ObjectToSObjectTypes.get('product_order__c').getDescribe().getKeyPrefix() == recordId.subString(0, 3))
        {
            // Get the Product Order
            list<Product_Order__c> li_ProductOrders =   [   select  id,
                                                                    Order__c,
                                                                    Order__r.Opportunity__c,
                                                                    Product_Node__r.Product_Type__c
                                                            from    Product_Order__c
                                                            where   id = : recordId
                                                            limit   1
                                                        ];
            
            if (!li_ProductOrders.isEmpty())
            {
                m_OpportunityId = li_ProductOrders[0].Order__r.Opportunity__c;
                m_CampaignOrderId = li_ProductOrders[0].Order__c;

                // Get the related Sales Order id
                list<csmso__Sales_Order__c> li_SalesOrders =    [   select  id
                                                                    from    csmso__Sales_Order__c
                                                                    where   csmso__Opportunity__c = : m_OpportunityId
                                                                    limit   1
                                                                ];
                
                if (!li_SalesOrders.isEmpty())
                {
                    m_SalesOrderId = li_SalesOrders[0].id;
                }

                m_ProductNodeProductType = li_ProductOrders[0].Product_Node__r.Product_Type__c;

                m_TargetObjectName = 'product_order__c';
            }
        }
        
        // Identify matching Rules
        getRules();
        
        system.debug('*** m_ProductNodeProductType ***' + m_ProductNodeProductType);

        // Get data for use in Data Filters
        map_sObjecttoFieldtoValues = getFilterDataForThisOpportunity(map_ObjectToSObjectTypes, m_OpportunityId);

        // Find the matching Rules
        identifyMatchingRules(map_ObjectToSObjectTypes, map_sObjecttoFieldtoValues);

        // Build the list of wrappers
        map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>> map_SectiontoQuestionWrappers = buildQuestionWrapperMap(m_OpportunityId);
        
        set<string> set_SectionNameswithQuestions = new set<string>(map_SectiontoQuestionWrappers.keySet());
        
        system.debug('*** set_SectionNameswithQuestions ***' + set_SectionNameswithQuestions);
        
        // Add Related Record data
        if (!m_mapSectiontoRelatedRecordData.isEmpty())
            map_SectiontoQuestionWrappers = CS_Questions_Utilities.getRelatedRecordData(
                m_mapSectiontoRelatedRecordData, m_mapRelatedDataRules, map_ObjectToSObjectTypes, map_SectiontoQuestionWrappers,
                m_OpportunityId, m_CampaignOrderId, m_SalesOrderId);
        
        // Convert to a list within a list for display
        mp_liQuestions = new list<CS_Questions_Utilities.SectionWrapper>();
        
        // Sort by Section name, but in the order defined in the schema
        SObjectType sObjType = map_ObjectToSObjectTypes.get('question2__c');
        SObjectField sObjField = sObjType.getDescribe().fields.getMap().get('section__c');
        DescribeFieldResult descFieldResult = SObjField.getDescribe();

        list<string> li_SectionNames = new list<string>();
        
        for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
        {
            if (sPLE.isActive() && map_SectiontoQuestionWrappers.containsKey(sPLE.getValue()))
                li_SectionNames.add(sPLE.getValue());
        }
        
        for (string strSectionName : li_SectionNames)
        {
            // Don't show anything if there are no Questions
            if (!set_SectionNameswithQuestions.contains(strSectionName))
                continue;

            CS_Questions_Utilities.SectionWrapper SectionWrapper = new CS_Questions_Utilities.SectionWrapper(strSectionName);
            
            map<integer, CS_Questions_Utilities.QuestionWrapper> map_QuestionWrappers = map_SectiontoQuestionWrappers.get(strSectionName);

            list<integer> li_SequenceNumbers = new list<integer>(map_QuestionWrappers.keySet());
            li_SequenceNumbers.sort();
            
            for (integer iSequenceNumber : li_SequenceNumbers)
            {
                SectionWrapper.QuestionWrappers.add(map_QuestionWrappers.get(iSequenceNumber));
            }
    
            mp_liQuestions.add(SectionWrapper);
        }

    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public void getRules()
    {
        // Get all active Rules
        m_mapObjecttoFields = new map<string, set<string>>();
        m_mapQuestiontoRules = new map<id, list<Rule__c>>();
        
        m_setRulesforCollection = new set<id>();
        m_setRulesforConsumption = new set<id>();
        
        m_mapSectiontoRelatedRecordData = new map<string, map<string, set<string>>>();
        
        for (Rule__c sRule :    [   select  id,
                                            Question2__c,
                                            Question_Type__c,
                                            Answer_Source__c,
                                            Field_Name__c,
                                            Field_Name_1__c,
                                            Field_Name_2__c,
                                            Field_Data_Type__c,
                                            Field_Data_Type_2__c,
                                            Field_Value_Text__c,
                                            Field_Value_Text_2__c,
                                            Object_Name__c,
                                            Object_Name_1__c,
                                            Object_Name_2__c,
                                            Operator__c,
                                            Related_Object_Name__c,
                                            Related_Field_name__c,
                                            Related_Field_Label__c,
                                            Related_Record_Section__c,
                                            Sequence_Number__c,
                                            WhatId__c,
                                            When_to_Ask__c,
                                            When_to_View__c,
                                            Help_Text__c,
                                            Enable_Field_Tracking__c
                                    from    Rule__c
                                    where   isActive__c = : true
                                    and     Answer_Source__c <> null
                                ])
        {
            // Unpack the collect and consume multiselect picklists
            set<string> set_WhentoAsk = new set<string>();
            set<string> set_WhentoView = new set<string>();
            
            if (!string.isBlank(sRule.When_to_Ask__c))
            {
                if (sRule.When_to_Ask__c.contains(';'))
                {
                    set_WhentoAsk.addAll(sRule.When_to_Ask__c.toLowerCase().split(';'));
                }
                else
                {
                    set_WhentoAsk.add(sRule.When_to_Ask__c.toLowerCase());
                }
            }

            if (sRule.When_to_View__c.contains(';'))
            {
                set_WhentoView.addAll(sRule.When_to_View__c.toLowerCase().split(';'));
            }
            else
            {
                set_WhentoView.add(sRule.When_to_View__c.toLowerCase());
            }
            
            // Related Records
            if (sRule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)
            {
                // Ignore if not consuming at this time
                if (sRule.When_to_View__c == null)
                    continue;
                
                if (!set_WhentoView.contains(m_TargetObjectName))
                    continue;

                // Defensive code
                if (sRule.Related_Object_Name__c == null)
                    continue;

                if (sRule.Related_Field_Name__c == null)
                    continue;

                system.debug('*** sRule added to map ***' + sRule);

                // Add to the relational map
                map<string, set<string>> map_ObjecttoFields = m_mapSectiontoRelatedRecordData.containsKey(sRule.Related_Record_Section__c)
                                                            ? m_mapSectiontoRelatedRecordData.get(sRule.Related_Record_Section__c)
                                                            : new map<string, set<string>>();

                set<string> li_Fields   = map_ObjecttoFields.containsKey(sRule.Related_Object_Name__c)
                                        ? map_ObjecttoFields.get(sRule.Related_Object_Name__c)
                                        : new set<string>();

                li_Fields.add(sRule.Related_Field_Name__c);
                map_ObjecttoFields.put(sRule.Related_Object_Name__c, li_Fields);
                m_mapSectiontoRelatedRecordData.put(sRule.Related_Record_Section__c, map_ObjecttoFields);
                
                // Save to master map
                
                // TODO: Defensive code - remove after old data deleted
                if (sRule.Sequence_Number__c == null)
                    continue;
                
                list<Rule__c> li_Rules  = m_mapRelatedDataRules.containsKey(sRule.Related_Record_Section__c)
                                        ? m_mapRelatedDataRules.get(sRule.Related_Record_Section__c)
                                        : new list<Rule__c>();

                li_Rules.add(sRule);
                m_mapRelatedDataRules.put(sRule.Related_Record_Section__c, li_Rules);
                
                system.debug('*** sRule ***' + sRule);

                continue;
            }

            // Check that we should be collecting or consuming the Question now
            // Note: if Rule specifies BOTH, collection trumps consumption
            
            // Collecting
            if (sRule.When_to_Ask__c != null && set_WhentoAsk.contains(m_TargetObjectName))
            {
                m_setRulesforCollection.add(sRule.id);
            }
            else if (sRule.When_to_View__c != null && set_WhentoView.contains(m_TargetObjectName))
            // Consuming
            {
                m_setRulesforConsumption.add(sRule.id);
            }
            else
            {
                continue;
            }

            // Handle Universal Rules
            if (sRule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
            {
                list<Rule__c> li_Rules  = m_mapQuestiontoRules.containsKey(sRule.Question2__c)
                                        ? m_mapQuestiontoRules.get(sRule.Question2__c)
                                        : new list<Rule__c>();

                li_Rules.add(sRule);
                m_mapQuestiontoRules.put(sRule.Question2__c, li_Rules);
                
                // Save to master map
                m_mapRules.put(sRule.Id, sRule);
            }
            // Handle General and Specific Rules
            else
            {
                // Defensive code
                if (sRule.Object_Name_1__c == null)
                    continue;

                // If we accessed the questionnaire via Product Order, filter by Product Type
                if (m_TargetObjectName == 'product_order__c')
                {
                    if (sRule.Object_Name_1__c.toLowerCase() != 'cscfga__product_configuration__c' ||
                        sRule.Field_Name_1__c.toLowerCase() != 'product_type_name__c' ||
                        sRule.Field_Value_Text__c != m_ProductNodeProductType)
                        continue;
                }

                // Save to master map
                m_mapRules.put(sRule.Id, sRule);
                
                // And to the map that will be used to build the dynamic SOQL
                set<string> set_Fields1 = m_mapObjecttoFields.containsKey(sRule.Object_Name_1__c)
                                        ? m_mapObjecttoFields.get(sRule.Object_Name_1__c)
                                        : new set<string>();
                
                set_Fields1.add(sRule.Field_Name_1__c);
                m_mapObjecttoFields.put(sRule.Object_Name_1__c, set_Fields1);

                // Optional second data filter
                if (sRule.Object_Name_2__c == null)
                    continue;

                set<string> set_Fields2 = m_mapObjecttoFields.containsKey(sRule.Object_Name_2__c)
                                        ? m_mapObjecttoFields.get(sRule.Object_Name_2__c)
                                        : new set<string>();
                
                set_Fields2.add(sRule.Field_Name_2__c);
                m_mapObjecttoFields.put(sRule.Object_Name_2__c, set_Fields2);
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public map<string, map<string, set<string>>> getFilterDataForThisOpportunity(map<string, SObjectType> map_ObjectToSObjectTypes, id opportunityId)
    {
        map<string, map<string, set<string>>> map_sObjecttoFieldtoValues = new map<string, map<string, set<string>>>();
        
        set<id> set_RecordIds = new set<id>();
        set<id> set_SalesOrderIds = new set<id>();

        // Get fields from the Opportunity only if there are Rules that reference an Opportunity in their Data Filter
        if (m_mapObjecttoFields.containsKey('Opportunity'))
        {
            map_sObjecttoFieldtoValues = getData(map_ObjectToSObjectTypes,
                                                map_sObjecttoFieldtoValues,
                                                'Opportunity',
                                                new set<id>{opportunityId});
        }
        
        // Now get Sales Orders if necessary
        if (m_mapObjecttoFields.containsKey('csmso__Sales_Order__c'))
        {
            set_RecordIds = new set<id>();
            
            for (csmso__Sales_Order__c sSalesOrder :    [   select  id
                                                            from    csmso__Sales_Order__c
                                                            where   csmso__Opportunity__c = : opportunityId
                                                        ])
            {
                set_RecordIds.add(sSalesOrder.id);
            }

            map_sObjecttoFieldtoValues = getData(map_ObjectToSObjectTypes,
                                                map_sObjecttoFieldtoValues,
                                                'csmso__Sales_Order__c',
                                                set_RecordIds);
        }
        
        // Finally get Product Configuration data
        if (m_mapObjecttoFields.containsKey('cscfga__Product_Configuration__c'))
        {
            set_RecordIds = new set<id>();
            
            // Only query Sales Order if we haven't already done it
            if (set_RecordIds.isEmpty())
            {
                // We have to go via Sales Order and Product Basket
                for (csmso__Sales_Order__c sSalesOrder :    [   select  id
                                                                from    csmso__Sales_Order__c
                                                                where   csmso__Opportunity__c = : opportunityId
                                                            ])
                {
                    set_SalesOrderIds.add(sSalesOrder.id);
                }
            }

            // Get related Product Baskets
            set<id> set_ProductBasketIds = new set<id>();
            
            for (cscfga__Product_Basket__c sProductBasket : [   select  id
                                                                from    cscfga__Product_Basket__c
                                                                where   csmso__Sales_Order__c in : set_SalesOrderIds
                                                            ])
            {
                set_ProductBasketIds.add(sProductBasket.id);
            }
        
            // Now we are redy to get Product Configuration records
            set<id> set_ProductConfigIds = new set<id>();
            
            for (cscfga__Product_Configuration__c sProductConfig :  [   select  id
                                                                        from    cscfga__Product_Configuration__c
                                                                        where   cscfga__Product_Basket__c in : set_ProductBasketIds
                                                                    ])
            {
                set_ProductConfigIds.add(sProductConfig.id);
            }
            
            set_RecordIds.addAll(set_SalesOrderIds);
            set_RecordIds.addAll(set_ProductConfigIds);

            map_sObjecttoFieldtoValues = getData(map_ObjectToSObjectTypes,
                                                map_sObjecttoFieldtoValues,
                                                'cscfga__Product_Configuration__c',
                                                set_RecordIds);
        }

        return map_sObjecttoFieldtoValues;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public map<string, map<string, set<string>>> getData(map<string, SObjectType> map_ObjectToSObjectTypes,
                                                        map<string, map<string, set<string>>> map_sObjecttoFieldtoValues,
                                                        string objectName,
                                                        set<id> set_RecordIds)
    {
        SObjectType sObjType = map_ObjectToSObjectTypes.get(objectName.toLowerCase());

        string strQuery = 'select id ';
                
        for (string fieldName : m_mapObjecttoFields.get(objectName))
            strQuery += ', ' + fieldName;

        strQuery += ' from ' + objectName + ' where id in : set_RecordIds';
                
        // Execute the query
        list<sObject> li_sObj = database.query(strQuery);

        for (sObject sObj : li_sObj)
        {
            system.debug('*** sObj ***' + sObj);
            
            for (string fieldName : m_mapObjecttoFields.get(objectName))
            {
                SObjectField sObjField =  sObjType.getDescribe().fields.getMap().get(fieldName.toLowerCase());
                DescribeFieldResult descFieldResult = SObjField.getDescribe();
                string strDataType = sObjField.getDescribe().getType().Name();

                // Currently only allow strings in the Data Filter
                if (strDataType != 'STRING' && strDataType != 'PICKLIST')
                    continue;

                map<string, set<string>> map_FieldtoSection = map_sObjecttoFieldtoValues.containsKey(objectName)
                                                            ? map_sObjecttoFieldtoValues.get(objectName)
                                                            : new map<string, set<string>>();
                    
                set<string> set_Values  = map_FieldtoSection.containsKey(fieldName)
                                        ? map_FieldtoSection.get(fieldName)
                                        : new set<string>();
                
                if (strDataType == 'STRING')
                {
                    set_Values.add(string.valueOf(sObj.get(fieldName.toLowerCase())));
                }
                else if (strDataType == 'PICKLIST')
                {
                    list<string> li_PicklistValues = string.valueOf(sObj.get(fieldName.toLowerCase())).split(',');
                    set_Values.addAll(li_PicklistValues);
                }
                
                map_FieldtoSection.put(fieldName, set_Values);
                map_sObjecttoFieldtoValues.put(objectName, map_FieldtoSection);
            }
        }

        return map_sObjecttoFieldtoValues;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public void identifyMatchingRules(map<string, SObjectType> map_ObjectToSObjectTypes, map<string, map<string, set<string>>> map_sObjecttoFieldtoValues)
    {
        // Now match the Rules against the Related Records
        for (Rule__c sRule : m_mapRules.values())
        {
            if (sRule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL || sRule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)         
                continue;
            
            if (string.isBlank(sRule.Object_Name_1__c))
                continue;
                
            boolean bDataFilter1Match = performMatchingLogic(map_sObjecttoFieldtoValues, sRule, sRule.Object_Name_1__c, sRule.Field_Name_1__c, sRule.Field_Value_Text__c, sRule.Field_Data_Type__c);

            boolean bDataFilter2Match = true;
            
            if (!string.isBlank(sRule.Object_Name_2__c))
                bDataFilter2Match = performMatchingLogic(map_sObjecttoFieldtoValues, sRule, sRule.Object_Name_2__c, sRule.Field_Name_2__c, sRule.Field_Value_Text_2__c, sRule.Field_Data_Type_2__c);

            // Did we match one / both filter criteria?
            if (!bDataFilter1Match || !bDataFilter2Match)
                continue;
            
            // Yes - add the Rule to the master collection
            system.debug('*** sRule passed filter check ***' + sRule);
            
            list<Rule__c> li_Rules  = m_mapQuestiontoRules.containsKey(sRule.Question2__c)
                                    ? m_mapQuestiontoRules.get(sRule.Question2__c)
                                    : new list<Rule__c>();

            li_Rules.add(sRule);
            m_mapQuestiontoRules.put(sRule.Question2__c, li_Rules);
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public boolean performMatchingLogic(map<string, map<string, set<string>>> map_sObjecttoFieldtoValues, Rule__c sRule, 
        string objectName, string fieldName, string value, string fieldType)
    {
        system.debug('*** sRule ***' + sRule);
        
        boolean bDataFilterMatch = false;
        
        if (!map_sObjecttoFieldtoValues.containsKey(objectName))
            return bDataFilterMatch;

        map<string, set<string>> map_FieldtoValues = map_sObjecttoFieldtoValues.get(objectName);
        
        if (!map_FieldtoValues.containsKey(fieldName))
            return bDataFilterMatch;
        
        set<string> set_Values = map_FieldtoValues.get(fieldName);
                
        if (fieldType == 'STRING' && set_Values.contains(value))
        {
            bDataFilterMatch = true;
        }
        else if (fieldType == 'PICKLIST')
        {
            for (string valuetoMatch : set_Values)
            {
                list<string> li_PicklistValues = (list<string>)JSON.deserialize(value, list<string>.class);
                    
                for (string picklistValue : li_PicklistValues)
                {
                    if (valuetoMatch == picklistValue)
                    {
                        bDataFilterMatch = true;
                        break;
                    }
                }
            }
        }
        else
        {
            // Other data types not currently supported
        }
        
        return bDataFilterMatch;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>> buildQuestionWrapperMap(id opportunityId)
    {
        // Initialise the collection to be returned
        map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>> map_SectiontoQuestionWrappers = new map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>>();
        
        // Disable the Save button - we only show this if there is one or more Questions to be collected
        mp_bShowSaveButton = false;
        
        // Get Questions
        map<id, Question2__c> map_Questions = new map<id, Question2__c>();
        
        set<id> set_QuestionIds = new set<id>();
        set_QuestionIds.addAll(m_mapQuestiontoRules.keySet());
        
        for (Question2__c sQuestion2 :  [   select  id,
                                                    Section__c,
                                                    Question_Text__c,
                                                    Answer_Type__c,
                                                    Answer_Picklist_Values__c,
                                                    Minimum_Length__c,
                                                    Maximum_Length__c,
                                                    isMandatory__c
                                            from    Question2__c
                                            where   id in : set_QuestionIds
                                        ])
        {
            map_Questions.put(sQuestion2.Id, sQuestion2);
        }
    
        // Now we know what Rules apply, look for any existing Answers
        set<id> set_AnswerIds = new set<id>();
        m_mapAnswertoAnswerRules = new map<id, list<Answer_to_Rule__c>>();
        
        set<id> set_MatchingRuleIds = new set<id>();

        for (list<Rule__c> li_Rules : m_mapQuestiontoRules.values())
        {
            for (Rule__c sRule : li_Rules)
                set_MatchingRuleIds.add(sRule.id);
        }
        
        for (Answer_to_Rule__c sAnswertoRule :  [   select  id,
                                                            Answer2__c,
                                                            Rule__c,
                                                            Rule__r.When_to_Ask__c,
                                                            Rule__r.When_to_View__c,
                                                            Opportunity__c
                                                    from    Answer_to_Rule__c
                                                    where   Opportunity__c = : opportunityId
                                                ])
        {
            if (set_MatchingRuleIds.contains(sAnswertoRule.Rule__c))
            {
                set_AnswerIds.add(sAnswertoRule.Answer2__c);
            }
            else
            {
                // Unpack the collect and consume multiselect picklists
                set<string> set_WhentoAsk = new set<string>();
                set<string> set_WhentoView = new set<string>();
                
                if (!string.isBlank(sAnswertoRule.Rule__r.When_to_Ask__c))
                {
                    if (sAnswertoRule.Rule__r.When_to_Ask__c.contains(';'))
                    {
                        set_WhentoAsk.addAll(sAnswertoRule.Rule__r.When_to_Ask__c.toLowerCase().split(';'));
                    }
                    else
                    {
                        set_WhentoAsk.add(sAnswertoRule.Rule__r.When_to_Ask__c.toLowerCase());
                    }
                }
    
                if (!string.isBlank(sAnswertoRule.Rule__r.When_to_View__c))
                {
                    if (sAnswertoRule.Rule__r.When_to_View__c.contains(';'))
                    {
                        set_WhentoView.addAll(sAnswertoRule.Rule__r.When_to_View__c.toLowerCase().split(';'));
                    }
                    else
                    {
                        set_WhentoView.add(sAnswertoRule.Rule__r.When_to_View__c.toLowerCase());
                    }
                }

                // Check that we should be collecting or consuming the Question now
                // Note: if Rule specifies BOTH, collection trumps consumption
                
                // Collecting
                if (sAnswertoRule.Rule__r.When_to_Ask__c != null && set_WhentoAsk.contains(m_TargetObjectName))
                {
                    m_setRulesforCollection.add(sAnswertoRule.Rule__c);
                }
                else if (sAnswertoRule.Rule__r.When_to_View__c != null && set_WhentoView.contains(m_TargetObjectName))
                // Consuming
                {
                    m_setRulesforConsumption.add(sAnswertoRule.Rule__c);
                }
                else
                {
                    continue;
                }

                set_AnswerIds.add(sAnswertoRule.Answer2__c);
            }

            list<Answer_to_Rule__c> li_AnswerRules  = m_mapAnswertoAnswerRules.containsKey(sAnswertoRule.Answer2__c)
                                                    ? m_mapAnswertoAnswerRules.get(sAnswertoRule.Answer2__c)
                                                    : new list<Answer_to_Rule__c>();

            li_AnswerRules.add(sAnswertoRule);
            m_mapAnswertoAnswerRules.put(sAnswertoRule.Answer2__c, li_AnswerRules);
        }

        // Collect Answers
        map<id, Answer2__c> map_QuestiontoAnswer = CS_Questions_Utilities.getAnswers(set_AnswerIds);

        // Create Answer records where needed
        list<Answer2__c> li_AnswerstoInsert = new list<Answer2__c>();
        list<Answer_to_Rule__c> li_AnswertoRulestoInsert = new list<Answer_to_Rule__c>();
        
        for (id questionId : map_Questions.keySet())
        {
            if (!map_QuestiontoAnswer.containsKey(questionId))
            {
                Question2__c sQuestion2 = map_Questions.get(questionId);
                
                li_AnswerstoInsert.add(new Answer2__c(
                    Question2__c        = questionId,
                    Question_Text__c    = sQuestion2.Question_Text__c,
                    Section__c          = sQuestion2.Section__c
                    ));
            }
        }
        
        if (!li_AnswerstoInsert.isEmpty())
        {
            insert li_AnswerstoInsert;
            
            for (Answer2__c sAnswer2 : li_AnswerstoInsert)
            {
                map_QuestiontoAnswer.put(sAnswer2.Question2__c, sAnswer2);
                
                Question2__c sQuestion2 = map_Questions.get(sAnswer2.Question2__c);
                
                list<Rule__c> li_Rules = m_mapQuestiontoRules.get(sAnswer2.Question2__c);
                
                for (Rule__c sRule : li_Rules)
                {
                    li_AnswertoRulestoInsert.add(new Answer_to_Rule__c(
                        Answer2__c      = sAnswer2.id,
                        Rule__c         = sRule.id,
                        Opportunity__c  = opportunityId
                        ));
                }
            }
                
            insert li_AnswertoRulestoInsert;
            
            for (Answer_to_Rule__c sAnswertoRule : li_AnswertoRulestoInsert)
            {
                list<Answer_to_Rule__c> li_AnswerRules  = m_mapAnswertoAnswerRules.containsKey(sAnswertoRule.Answer2__c)
                                                        ? m_mapAnswertoAnswerRules.get(sAnswertoRule.Answer2__c)
                                                        : new list<Answer_to_Rule__c>();
                
                li_AnswerRules.add(sAnswertoRule);
                m_mapAnswertoAnswerRules.put(sAnswertoRule.Answer2__c, li_AnswerRules);
            }
        }
        
        // At this point we have only been looking at current, Active Questions
        // We also need to check for Answers to Questions that have been de-activated since the Answer was created
        set<id> set_InactivatedQuestionIds = new set<id>();
        
        for (id questionId : map_QuestiontoAnswer.keySet())
        {
            if (!map_Questions.containsKey(questionId))
                set_InactivatedQuestionIds.add(questionId);
        }
        
        if (!set_InactivatedQuestionIds.isEmpty())
        {
            for (Question2__c sQuestion2 :  [   select  id,
                                                        Section__c,
                                                        Question_Text__c,
                                                        Answer_Type__c,
                                                        Answer_Picklist_Values__c,
                                                        Minimum_Length__c,
                                                        Maximum_Length__c,
                                                        isMandatory__c
                                                from    Question2__c
                                                where   id in : set_InactivatedQuestionIds
                                            ])
            {
                map_Questions.put(sQuestion2.Id, sQuestion2);
            }
            
            map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_InactivatedQuestionIds, false);

            for (Rule__c sRule : map_Rules.values())
            {
                // If we accessed the questionnaire via Product Order, filter by Product Type
                if (m_TargetObjectName == 'product_order__c')
                {
                    // Following code commented out at the request of Liz Dillon 14Sep18
                    // Ignore Universal Rules
//                  if (sRule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
//                      continue;

                    if (string.isBlank(m_ProductNodeProductType))
                        continue;

                    boolean bDisplayforPO = false;
                    
                    if (!string.isBlank(sRule.Object_Name_1__c) &&
                        !string.isBlank(sRule.Field_Name_1__c) &&
                        sRule.Object_Name_1__c.toLowerCase() == 'cscfga__product_configuration__c' &&
                        sRule.Field_Name_1__c.toLowerCase() == 'product_type_name__c' &&
                        sRule.Field_Value_Text__c == m_ProductNodeProductType)
                        bDisplayforPO = true;

                    if (!string.isBlank(sRule.Object_Name_2__c) &&
                        !string.isBlank(sRule.Field_Name_2__c) &&
                        sRule.Object_Name_2__c.toLowerCase() == 'cscfga__product_configuration__c' &&
                        sRule.Field_Name_2__c.toLowerCase() == 'product_type_name__c' &&
                        sRule.Field_Value_Text__c == m_ProductNodeProductType)
                        bDisplayforPO = true;
                        
                    if (!bDisplayforPO)
                        continue;
                }
                
                system.debug('*** Question ***' + map_Questions.get(sRule.Question2__c));
                system.debug('*** sRule ***' + sRule);
                
                m_mapRules.put(sRule.Id, sRule);
            }
        }


        // NOW we can build the AnswerWrapper collection for storing Answer and Answer to Rules records
        m_mapQuestiontoAnswers = new map<id, CS_Questions_Utilities.AnswerWrapper>();
        
        for (id questionId : map_Questions.keySet())
        {
            Question2__c sQuestion2 = map_Questions.get(questionId);
        
            CS_Questions_Utilities.AnswerWrapper AnswerWrapper = new CS_Questions_Utilities.AnswerWrapper();
        
            // Retrieve Answer record
            AnswerWrapper.Answer = map_QuestiontoAnswer.get(questionId);
            AnswerWrapper.map_AnswertoRules.put(AnswerWrapper.Answer.id, m_mapAnswertoAnswerRules.get(AnswerWrapper.Answer.id));

            m_mapQuestiontoAnswers.put(questionId, AnswerWrapper);
        }

        // Build the QuestionWrapper collection for the dynamic tabs
        for (id questionId : map_Questions.keySet())
        {
            CS_Questions_Utilities.AnswerWrapper AnswerWrapper = m_mapQuestiontoAnswers.get(questionId);
            Answer2__c sAnswer2 = AnswerWrapper.Answer;
            
            system.debug('*** sAnswer2 ***' + sAnswer2);
            
            CS_Questions_Utilities.QuestionWrapper QuestionWrapper = new CS_Questions_Utilities.QuestionWrapper(questionId, sAnswer2.Question_Text__c, sAnswer2);
            
            // Save the Opportunity Id - the Interface Processing needs this
            QuestionWrapper.OpportunityId = opportunityId;
            
            // Now set the Answer metadata based on the rules
            for (Answer_to_Rule__c sAnswertoRule : AnswerWrapper.map_AnswertoRules.get(sAnswer2.id))
            {
                Question2__c sQuestion2 = map_Questions.get(questionId);
                
                if (!m_mapRules.containsKey(sAnswertoRule.Rule__c))
                    continue;
                
                Rule__c sRule = m_mapRules.get(sAnswertoRule.Rule__c);
                
                system.debug('*** sQuestion2 ***' + sQuestion2);
                system.debug('*** sRule ***' + sRule);

                QuestionWrapper.SequenceNumber = integer.valueOf(sRule.Sequence_Number__c);
                QuestionWrapper.Answer.Sequence_Number__c = QuestionWrapper.SequenceNumber;

                // Collecting or Consuming?
                QuestionWrapper.isReadOnly  = m_setRulesforConsumption.contains(sRule.id)
                                            ? true
                                            : false;

                if (!QuestionWrapper.isReadOnly)
                    mp_bShowSaveButton  = true;

                // Field tracking?
                QuestionWrapper.isFieldTracking = sRule.Enable_Field_Tracking__c
                                                ? true
                                                : false;

                // Set display boolean
                if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_CHECKBOX)
                {
                    QuestionWrapper.showAnswerCheckbox = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_CURRENCY)
                {
                    QuestionWrapper.showAnswerCurrency = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_DATE)
                {
                    QuestionWrapper.showAnswerDate = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_EMAIL)
                {
                    QuestionWrapper.showAnswerEmail = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT)
                {
                    QuestionWrapper.showAnswerLongText = true;

                    // Calculate # rows to show if Field Tracking enabled or if read only
                    if (QuestionWrapper.isFieldTracking || QuestionWrapper.isReadOnly)
                    {
                        // If already answered, show original text as read-only
                        if (!string.isBlank(sAnswer2.Answer_Long_Text__c))
                        {
                            // Populate the additional field with the change history
                            list<CS_Questions_Utilities.ChangeHistoryWrapper> li_ChangeHistory = string.isBlank(QuestionWrapper.Answer.Change_History__c)
                                ? new list<CS_Questions_Utilities.ChangeHistoryWrapper>()
                                : (list<CS_Questions_Utilities.ChangeHistoryWrapper>)JSON.deserialize(QuestionWrapper.Answer.Change_History__c, list<CS_Questions_Utilities.ChangeHistoryWrapper>.class);

                            // Don't populate the history tracking box if there are no entries
                            if (li_ChangeHistory.size() > 0)
                            {
                                QuestionWrapper.showLongTextAdditional = true;
                                
                                for (integer i = li_ChangeHistory.size()-1; i > -1; i--)
                                {
                                    CS_Questions_Utilities.ChangeHistoryWrapper ChangeHistoryWrapper = li_ChangeHistory[i];
                                    
                                    QuestionWrapper.LongTextAdditional  = string.isBlank(QuestionWrapper.LongTextAdditional)
                                                                        ? ChangeHistoryWrapper.whenChanged
                                                                        : QuestionWrapper.LongTextAdditional + '\n' + ChangeHistoryWrapper.whenChanged;
                                    
                                    QuestionWrapper.LongTextAdditional += ' ' + ChangeHistoryWrapper.whoChanged + ' wrote:\n';
                                    QuestionWrapper.LongTextAdditional += ' ' + ChangeHistoryWrapper.whatChanged;
                                }
                                
                                // Work out how many rows to show
                                QuestionWrapper.LongTextRows = 0;
                                
                                // Split by line breaks
                                list<string> li_AnswerText = QuestionWrapper.LongTextAdditional.split('\n');
                                
                                // Now count length of each line because we are wrapping text
                                for (string strAnswerText : li_AnswerText)
                                {
                                    decimal decRows = decimal.valueOf(strAnswerText.length()).divide
                                        (100, 0, System.RoundingMode.UP);
        
                                    QuestionWrapper.LongTextRows += integer.valueOf(decRows);
                                }
                            }
                        }
                        else
                        {
                            // This will happen at consumption time if the Answer is null
                            QuestionWrapper.LongTextRows = 1;
                        }
                    }
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_NUMBER)
                {
                    QuestionWrapper.showAnswerNumeric = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PERCENT)
                {
                    QuestionWrapper.showAnswerPercent = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PHONE)
                {
                    QuestionWrapper.showAnswerPhone = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_TEXT)
                {
                    QuestionWrapper.showAnswerText = true;
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
                {
                    QuestionWrapper.showAnswerPicklist = true;

                    list<CS_Questions_Utilities.PicklistWrapper> li_PicklistWrappers = (list<CS_Questions_Utilities.PicklistWrapper>)JSON.deserialize(sQuestion2.Answer_Picklist_Values__c, list<CS_Questions_Utilities.PicklistWrapper>.class);
                    
                    QuestionWrapper.li_AnswerPicklistValues.add(new CS_Questions_Utilities.PicklistWrapper('', 'Please select'));
                    
                    for (CS_Questions_Utilities.PicklistWrapper PicklistWrapper : li_PicklistWrappers)
                        QuestionWrapper.li_AnswerPicklistValues.add(new CS_Questions_Utilities.PicklistWrapper(PicklistWrapper.value, PicklistWrapper.label));
                }
                else if (sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_URL)
                {
                    QuestionWrapper.showAnswerURL = true;
                }
                
                // Help text etc
                if (!string.isBlank(sRule.Help_Text__c))
                {
                    QuestionWrapper.showHelpText = true;
                    QuestionWrapper.HelpText = sRule.Help_Text__c;
                }
                
                QuestionWrapper.MinLength   = integer.valueOf(sQuestion2.Minimum_Length__c);
                QuestionWrapper.MaxLength   = integer.valueOf(sQuestion2.Maximum_Length__c);
                
                QuestionWrapper.isMandatory = sQuestion2.isMandatory__c;
            
                system.debug('*** QuestionWrapper ***' + QuestionWrapper);
    
                map<integer, CS_Questions_Utilities.QuestionWrapper> map_QuestionWrappers
                    = map_SectiontoQuestionWrappers.containsKey(sAnswer2.Section__c)
                    ? map_SectiontoQuestionWrappers.get(sAnswer2.Section__c)
                    : new map<integer, CS_Questions_Utilities.QuestionWrapper>();
    
                map_QuestionWrappers.put(QuestionWrapper.SequenceNumber, QuestionWrapper);
                map_SectiontoQuestionWrappers.put(sAnswer2.Section__c, map_QuestionWrappers);
            }
        }
        
        return map_SectiontoQuestionWrappers;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public List<String> validateAnswers()
    {
        boolean bIsValid = true;
        List<String> valMessagesList = new List<String>();

        for (CS_Questions_Utilities.SectionWrapper SectionWrapper : mp_liQuestions)
        {
            for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
            {
                // Ignore if read-only
                if (QuestionWrapper.isReadOnly)
                    continue;

                QuestionWrapper.messages = new list<string>();
                
                // Display boolean tells us what the data type is
                if (QuestionWrapper.showAnswerCheckbox)
                {

                }
                else if (QuestionWrapper.showAnswerCurrency)
                {
                    // Do Min / Max length check
                    if (QuestionWrapper.MinLength > 0 && 
                        (QuestionWrapper.Answer.Answer_Currency__c != null && string.valueOf(QuestionWrapper.Answer.Answer_Currency__c).length() < QuestionWrapper.MinLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                    }
                        

                    if (QuestionWrapper.MaxLength > 0 &&
                        (QuestionWrapper.Answer.Answer_Currency__c != null && string.valueOf(QuestionWrapper.Answer.Answer_Currency__c).length() > QuestionWrapper.MaxLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                    }
                        

                }
                else if (QuestionWrapper.showAnswerDate)
                {

                }
                else if (QuestionWrapper.showAnswerEmail)
                {
                    if(!String.isBlank(QuestionWrapper.Answer.Answer_Email__c) && !validateEmail(QuestionWrapper.Answer.Answer_Email__c)){
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + 'Please enter a valid email address.');
                    }
                }
                else if (QuestionWrapper.showAnswerLongText)
                {

                }
                else if (QuestionWrapper.showAnswerNumeric)
                {
                    // Do Min / Max length check
                    if (QuestionWrapper.MinLength > 0 &&
                        (QuestionWrapper.Answer.Answer_Numeric__c != null && string.valueOf(QuestionWrapper.Answer.Answer_Numeric__c).length() < QuestionWrapper.MinLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                    }
                        
                    if (QuestionWrapper.MaxLength > 0 &&
                        (QuestionWrapper.Answer.Answer_Numeric__c != null && string.valueOf(QuestionWrapper.Answer.Answer_Numeric__c).length() > QuestionWrapper.MaxLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                    }
                    
                }
                else if (QuestionWrapper.showAnswerPercent)
                {

                }
                else if (QuestionWrapper.showAnswerPhone)
                {
                    // Do Min / Max length check
                    if (QuestionWrapper.MinLength > 0 && 
                        (QuestionWrapper.Answer.Answer_Phone__c != null && QuestionWrapper.Answer.Answer_Phone__c.length() < QuestionWrapper.MinLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                    }
                        

                    if (QuestionWrapper.MaxLength > 0 &&
                        (QuestionWrapper.Answer.Answer_Phone__c != null && QuestionWrapper.Answer.Answer_Phone__c.length() > QuestionWrapper.MaxLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                    }
                        
                }
                else if (QuestionWrapper.showAnswerText)
                {
                    // Do Min / Max length check
                    if (QuestionWrapper.MinLength > 0 && 
                        (QuestionWrapper.Answer.Answer_Text__c != null && QuestionWrapper.Answer.Answer_Text__c.length() < QuestionWrapper.MinLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MINLENGTH + QuestionWrapper.MinLength);
                    }
                        

                    if (QuestionWrapper.MaxLength > 0 &&
                        (QuestionWrapper.Answer.Answer_Text__c != null && QuestionWrapper.Answer.Answer_Text__c.length() > QuestionWrapper.MaxLength)){

                        QuestionWrapper.messages.add(CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                        valMessagesList.add(QuestionWrapper.QuestionText + ': ' + CS_Questions_Utilities.VALIDATIONERROR_MAXLENGTH + QuestionWrapper.MaxLength);
                    }
                        
                }
                else if (QuestionWrapper.showAnswerPicklist)
                {

                }
                else if (QuestionWrapper.showAnswerURL)
                {
                        
                }

                if (!QuestionWrapper.messages.isEmpty())
                    bIsValid = false;
            }
        }
        
        //return bIsValid;
        return valMessagesList;
    }

    // validate format of the email address 
    private static Boolean validateEmail(String email) {
        Boolean res = true;
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) 
            res = false;
        return res; 
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public void saveAnswers()
    {
        list<Answer2__c> li_AnswerstoUpsert = new list<Answer2__c>();
        
        for (CS_Questions_Utilities.SectionWrapper SectionWrapper : mp_liQuestions)
        {
            for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
            {
                // Ignore read-only Answers
                if (QuestionWrapper.isReadOnly)
                    continue;
                
                QuestionWrapper.LongTextAdditional = null;

                li_AnswerstoUpsert.add(QuestionWrapper.Answer);
            }
        }
        
        // Find and execute any Interface calls
        // First, clear out existing output Answer data
        CS_Interface_Utilities.clearAnswers(mp_liQuestions);
        
        // Now make the call
        futureMakeInterfaceCalls(JSON.serialize(mp_liQuestions));
        
        // This can happen when we are consuming Answers
        if (li_AnswerstoUpsert.isEmpty())
            return;

        upsert li_AnswerstoUpsert;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    @future(callout=true)
    private static void futureMakeInterfaceCalls(string JSONString)
    {
        list<CS_Questions_Utilities.SectionWrapper> liQuestions = 
            (list<CS_Questions_Utilities.SectionWrapper>)JSON.deserialize(JSONString, list<CS_Questions_Utilities.SectionWrapper>.class);
        
        CS_Interface_Utilities.makeInterfaceCalls(liQuestions);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    public void rebuildQuestionWrappers()
    {
        for (CS_Questions_Utilities.SectionWrapper SectionWrapper : mp_liQuestions)
        {
            for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
            {
                // Field Tracking
                if (QuestionWrapper.isFieldTracking)
                {
                    // If already answered, show original text as read-only
                    if (!string.isBlank(QuestionWrapper.Answer.Answer_Long_Text__c))
                    {
                        QuestionWrapper.showLongTextAdditional = true;
                        
                        // Work out how many rows to show
                        QuestionWrapper.LongTextRows = CS_Questions_Utilities.calculateNumberofRows(QuestionWrapper.Answer.Answer_Long_Text__c);
                    }
                }
            }
        }
    }

    // Update the campaign brief form status (Campaign_Brief_Form_Completed__c) on Opportunity
    public void updateCampaignBriefStatusOpportunity(string opportunityId, boolean isCampaignBriefCompleted)
    {
        try
        {
            if (isCampaignBriefCompleted != null)
            {
                Opportunity sOpportunity = new Opportunity();
				//SFE-1043 Begins
				sOpportunity = [Select id, Name,Campaign_Brief_Form_Completed__c,Approved_Sales_Order_Number__c,Opportunity_Platform_NewsXtend__c,IsWon,StageName,Reason_Won_Lost__c FROM Opportunity where id =:opportunityId LIMIT 1];
                //sOpportunity.Id = opportunityId;
				//SFE-1043 Ends
                sOpportunity.Campaign_Brief_Form_Completed__c = isCampaignBriefCompleted;
				//SFE-1043 Begins
				if(sOpportunity.Approved_Sales_Order_Number__c!=null && sOpportunity.Opportunity_Platform_NewsXtend__c == true && sOpportunity.IsWon== false){
					sOpportunity.StageName = 'Closed Won';
					sOpportunity.Campaign_Brief_Form_Completed__c = true;
					sOpportunity.Reason_Won_Lost__c = 'Masthead Reputation';

				}
				//SFE-1043 Ends
                update sOpportunity;
            }
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
        }
    }

}