/**
 * Triggered on cscfga__Attribute__c object by CS_AllAttributeTriggers.trigger
 */
public class CS_AllAttributeTriggerHelper {

    /**
     * Runs after INSERT or UPDATE. 
     */
    public static void AddAttr(List<cscfga__Attribute__c> attrList){

        /*Set<Id> configIds = new Set<Id>();
        Map<Id, List<cscfga__Attribute__c>> configIdAttrListMap = new Map<Id, List<cscfga__Attribute__c>>();

        for (cscfga__Attribute__c att : attrList) {
            configIds.add(att.cscfga__Product_Configuration__c);
            if (configIdAttrListMap.get(att.cscfga__Product_Configuration__c) == null) {
                configIdAttrListMap.put(att.cscfga__Product_Configuration__c, new List<cscfga__Attribute__c>());
            }
            configIdAttrListMap.get(att.cscfga__Product_Configuration__c).add(att);
        }
       
        
        List<cscfga__Product_Configuration__c> configUpdateList = [
            select id, Total_Invoice__c, Total_impressions__c, Total_Cost__c
            from cscfga__Product_Configuration__c
            where id in :configIds
        ];
        
        for(cscfga__Product_Configuration__c pc : configUpdateList) {
            List<cscfga__Attribute__c> mapAttrList = configIdAttrListMap.get(pc.Id);
            Map<String, Schema.SObjectField> fieldMap = cscfga__Product_Configuration__c.getSObjectType().getDescribe().Fields.getMap();
            for(cscfga__Attribute__c a : mapAttrList) {
                // TODO - Attribute value to be cut to number of chars supported by field
                if (a.cscfga__Value__c != null && a.Configuration_Output_Mapping__c != null && a.Configuration_Output_Mapping__c != '') {
                    system.debug('+++++++ mapAttrList ' + mapAttrList);
                    Schema.DescribeFieldResult dfr = fieldMap.get(a.Configuration_Output_Mapping__c).getDescribe();
                    if (dfr.getSoapType() == Schema.SoapType.String) {
                        pc.put(a.Configuration_Output_Mapping__c, a.cscfga__Value__c);
                    }
                    else if (dfr.getSoapType() == Schema.SoapType.DateTime) {
                        pc.put(a.Configuration_Output_Mapping__c, DateTime.parse(a.cscfga__Value__c));
                    }
                    else if (dfr.getSoapType() == Schema.SoapType.Date) {
                        if (a.cscfga__Value__c != null && a.cscfga__Value__c.trim() != '') {
                            List<String> dateSplit = a.cscfga__Value__c.split('/');
                            Date ADate = Date.newInstance(Integer.valueOf(dateSplit[2]),Integer.valueOf(dateSplit[1]),Integer.valueOf(dateSplit[0]));
                            pc.put(a.Configuration_Output_Mapping__c, ADate);
                        }
                    }   
                    else if (dfr.getSoapType() == Schema.SoapType.Double) {
                        Double dblRoundedToScale = (Double) Decimal.valueOf(a.cscfga__Value__c).setScale(dfr.getScale(),RoundingMode.UP);
                        pc.put(a.Configuration_Output_Mapping__c, dblRoundedToScale);
                    }
                    else if (dfr.getSoapType() == Schema.SoapType.Integer) {
                        pc.put(a.Configuration_Output_Mapping__c, Integer.valueOf(a.cscfga__Value__c));
                    }
                    system.debug('+++++++ configUpdateList ' + configUpdateList);
                    system.debug('+++++++ dfr ' + dfr);
                }
            }
        }
        update configUpdateList;*/
    }
    
    //created by Davor Dubokovic as a part of SFE-860
    private static Set<Id> CollectPCId(Map<Id, cscfga__Attribute__c> newAttMap, Map<Id, cscfga__Attribute__c> oldAttMap)
    {
        Set<Id> setPCId = new Set<Id>();

        for (Id tmpAttId : newAttMap.keySet()) 
        {
            if (newAttMap.get(tmpAttId).cscfga__Value__c!=oldAttMap.get(tmpAttId).cscfga__Value__c)
            {
                setPCId.add(newAttMap.get(tmpAttId).cscfga__Product_Configuration__c);
            }
        }
        
        return setPCId;
    }


    public static void ResetSalesOrder(Set<Id> setPCId)
    {

        if (setPCId.size()>0)
        {
            List<cscfga__Product_Configuration__c> lstPC = [SELECT Id,cscfga__Product_Basket__c, 
                cscfga__Product_Basket__r.csmso__Sales_Order__c 
                from cscfga__Product_Configuration__c
                where Id in :  setPCId
                and cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c in 
                ('Internally Approved','Internally Rejected','Externally Rejected','Rejected')];

            if (lstPC.size()>0)
            {
                Set<Id> setSOId = new Set<Id>();

                for (cscfga__Product_Configuration__c tmpPC : lstPC)
                {
                    setSOId.add(tmpPC.cscfga__Product_Basket__r.csmso__Sales_Order__c);
                }

                Boolean ResetTesult = ResetApprovalProcess(setSOId);

                if (ResetTesult)
                {
                    List<csmso__Sales_Order__c> lstSO = [select Id,csmso__Status__c, Retraction_On__c
                        from csmso__Sales_Order__c
                        where Id in : setSOId];

                    for(csmso__Sales_Order__c tmpSO : lstSO)
                    {
                        // kw: order amendment
                        // Reset so back to 'Retracted' if the reset happens within a retraction
                        tmpSO.csmso__Status__c= (tmpSO.Retraction_On__c != null && tmpSO.Retraction_On__c != 'Active Campaign') ? 'Draft' : 'Retracted';    
                    }

                    update lstSO;
                }
            }
        }
    }

    private static Boolean ResetApprovalProcess(Set<Id> setSOId )
    {
        Boolean FinalResult=true;
        
        List<ProcessInstanceWorkitem> lstProcessInstanceWorkitem = [SELECT Id FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId in : setSOId 
            AND ProcessInstance.Status = 'Pending' ];

        if (lstProcessInstanceWorkitem.size()>0)
        {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Removed');
        
            for(ProcessInstanceWorkitem tmpProcessInstanceWorkitem : lstProcessInstanceWorkitem)
            {
                pwr.setWorkItemId(lstProcessInstanceWorkitem[0].id);
                Approval.ProcessResult result = Approval.process(pwr);
                if (result.getErrors().size()>0)
                    return false;
            }
        }

        return FinalResult;
    }


    public static void afterUpdate(Map<Id, cscfga__Attribute__c> newAttMap, Map<Id, cscfga__Attribute__c> oldAttMap)
    {
        Set<Id> setPCId = CollectPCId(newAttMap,oldAttMap);
        ResetSalesOrder(setPCId);
    }
    //end of code done by Davor Dubokovic as a part of SFE-860

    public static void beforeUpdate(Map<Id, cscfga__Attribute__c> newAttMap, Map<Id, cscfga__Attribute__c> oldAttMap) {
        
        Set<String> objIds     = new Set<String>();
        Set<String> attNames   = new Set<String>{'Product', 'Network', 'Product Type', 'Provider', 'Product Line'};
        Set<String> slAttNames = new Set<String>{'Quantity or Invoice Price'};

        Map<String, String> attIdToObjIdMap = new Map<String, String>();
        Map<String, cscfga__Attribute__c> attNameMap = new Map<String, cscfga__Attribute__c>();
        
        for (cscfga__Attribute__c att : newAttMap.values()) {
            if (slAttNames.contains(att.Name)) {
                att.cscfga__Display_Value__c = att.cscfga__Value__c;
            }

            // if News Xtend Ref Attribute
            if (attNames.contains(att.Name) && att.cscfga__Value__c != oldAttMap.get(att.Id).cscfga__Value__c) {
                if (att.cscfga__Value__c == null || att.cscfga__Value__c == '') {
                    att.cscfga__Display_Value__c = '';
                } else {
                    objIds.add(att.cscfga__Value__c);
                    attIdToObjIdMap.put(att.Name, att.cscfga__Value__c);

                    attNameMap.put(att.Name, att);
                }
            }
        }

        setNewsXtendDisplayValues(objIds, attIdToObjIdMap, attNameMap);

    }
    
    public static void beforeInsert(List<cscfga__Attribute__c> newAtts) {
        Set<String> objIds     = new Set<String>();    // Values of Xtend Attributes, which are News_Xtend_ref IDs
        Set<String> attNames   = new Set<String>{ 'Product', 'Network', 'Product Type', 'Provider', 'Product Line' }; 
        Set<String> slAttNames = new Set<String>{ 'Quantity or Invoice Price' };

        // maps all Attribute Names to its Attribute objects
        Map<String, cscfga__Attribute__c> attNameMap = new Map<String, cscfga__Attribute__c>();
        // maps News_Xtend_ref Record Type Name to its News_Xtend_Ref ID
        Map<String, String> attIdToObjIdMap = new Map<String, String>();

        //helper strings to check if atts come from bundle or News Xtend
        String pNodePrefix = csmso__Product_Node__c.getSObjectType().getDescribe().getKeyPrefix();
        String newsXtendPrefix = News_Xtend_Product_Ref__c.getSObjectType().getDescribe().getKeyPrefix();

        // store all Attributes in the Map by Attribute Name: Map<String, cscfga__Attribute__c> attNameMap
        // and process the News Xtend Attributes
        String attPrefix ='';

        for (cscfga__Attribute__c att : newAtts) {

            // For 'Quantity or Invoice Price' attribute, set Attribute Display Value to Attribute Value
            if (slAttNames.contains(att.Name)) {
                att.cscfga__Display_Value__c = att.cscfga__Value__c;
            }

            attNameMap.put(att.Name, att);



            /**
             *  if Attribute Name is one of the News_Xtend_ref product names then:
             *      if News_Xtend_ref Attribute Value is empty, clear the Attribute display value
             *      else add the Attribute Value (News_Xtend_Ref ID) to objIds Set 
             *      and map the News_Xtend_ref Attribute (Record Type) Name to its Value (News_Xtend_Ref ID) in attIdToObjIdMap
             */
            if (attNames.contains(att.Name)) {

                //skip non conforming attributes from bundle Xtend
                attPrefix = att.cscfga__Value__c != null ? att.cscfga__Value__c.left(3) : '';
                if  (attPrefix != pNodePrefix && attPrefix != newsXtendPrefix)  continue;

                
                if (att.cscfga__Value__c == null || att.cscfga__Value__c == '') {
                    att.cscfga__Display_Value__c = '';
                } else {
                    objIds.add(att.cscfga__Value__c);
                    attIdToObjIdMap.put(att.Name, att.cscfga__Value__c);
                }
            }
        }

        setNewsXtendDisplayValues(objIds, attIdToObjIdMap, attNameMap);


    }

    /**
     * Sets Display Values of the News_Xtend_Ref Attributes to the Name of News_Xtend_Ref records
     * @param objIds Values of Xtend Attributes, which are News_Xtend_ref IDs
     * @param attIdToObjIdMap Values of News_Xtend_ref Record Type Name mapped to News_Xtend_Ref ID
     * @param attNameMap All Attribute Names mapped to their Attribute objects
     */
    private static void setNewsXtendDisplayValues(Set<String> objIds, Map<String, String> attIdToObjIdMap, Map<String, cscfga__Attribute__c> attNameMap) {
        if (!objIds.isEmpty()) {

            // News Xtend code start
            Map<Id, News_Xtend_Product_Ref__c> newsXtends = new Map<Id, News_Xtend_Product_Ref__c>([SELECT Id, Name
                                                                                                    FROM News_Xtend_Product_Ref__c
                                                                                                    WHERE Id IN :objIds]);

            if (!newsXtends.isEmpty()) {
                System.debug('Entered Xtend code...');

                for (String attId : attIdToObjIdMap.keySet()) {
                    if (newsXtends.get(attIdToObjIdMap.get(attId)) != null) {
                        cscfga__Attribute__c att = attNameMap.get(attId);

                        // set Display Value of the News_Xtend_Ref Attribute to the Name of the News_Xtend_Ref record 
                        att.cscfga__Display_Value__c = newsXtends.get(attIdToObjIdMap.get(attId)).Name;
                    }
                }
            }
            // News Xtend code end

            Map<Id, csmso__Product_Node__c> productNodes = new Map<Id, csmso__Product_Node__c>([SELECT Id, Name
                                                                                                FROM csmso__Product_Node__c
                                                                                                WHERE Id IN :objIds]);
            // Product Node code start
            if (!productNodes.isEmpty()) {


                for (String attId : attIdToObjIdMap.keySet()) {
                    if (productNodes.get(attIdToObjIdMap.get(attId)) != null) {
                        cscfga__Attribute__c att = attNameMap.get(attId);

                        
                        // set Display Value of the Product Node Attribute to the Name of the Product Node record
                        att.cscfga__Display_Value__c = productNodes.get(attIdToObjIdMap.get(attId)).Name;

                    }
                }
            }
            // Product Node code end
        }
    }
}