global class CS_SetupProductNodeBatch implements Database.Batchable<sObject>
{
    global class MyException extends Exception
    {
        
    }
    
    private string strQuery;
    private boolean isForInvalidPdts;
    private Set<ID> newsXtendIDs;
    
    global CS_SetupProductNodeBatch()
    {
        isForInvalidPdts = false;
        strQuery = 'SELECT Id,Name,Provider__c,Product_Line__c,Product_Type__c,Network__c,' + 
                                        '       Record_Type_Name__c,HTML_IS__c,Payment_Type__c,' +
                                        '       Basic_Price__c,Cost_Of_Goods__c,Cost_Model__c,' +
                                        '       Maximum_Discount__c,Minimum_Order__c,Quantity_By__c,'  +
                                        '       Product_Groups_For_Investment_Summary__c,' +
                                        '       Product_Groups_For_IO__c,Site_Section__c,Site_Section_Group__c, CreatedDate ' + 
                                        'FROM   News_Xtend_Product_Ref__c ' +
                                        'WHERE  Record_Type_Name__c = \'Product\' AND Provider__c <> null AND Product_Line__c <> null AND Product_Type__c <> null AND Network__c <> null AND Product_Node__c = null ' +
                                        'ORDER BY Provider__c, Product_Line__c, Product_Type__c, Network__c,  Name';    
    }

    global CS_SetupProductNodeBatch(boolean isForInvalidProducts)
    {
        isForInvalidPdts = isForInvalidProducts;
        
        if (isForInvalidProducts)
            strQuery = 'SELECT Id,Name,Provider__c,Product_Line__c,Product_Type__c,Network__c,' + 
                                            '       Record_Type_Name__c,HTML_IS__c,Payment_Type__c,' +
                                            '       Basic_Price__c,Cost_Of_Goods__c,Cost_Model__c,' +
                                            '       Maximum_Discount__c,Minimum_Order__c,Quantity_By__c,'  +
                                            '       Product_Groups_For_Investment_Summary__c,' +
                                            '       Product_Groups_For_IO__c,Site_Section__c,Site_Section_Group__c, CreatedDate ' + 
                                            'FROM   News_Xtend_Product_Ref__c ' +
                                            'WHERE  Record_Type_Name__c = \'Product\' AND Provider__c <> null AND Product_Node__c = null' +
                                            'ORDER BY Provider__c, Product_Line__c, Product_Type__c, Network__c,  Name';
        else
        {
            MyException myExcep = new MyException('Invalid value for contrsuctor parameter');
            throw myExcep;
        }

    }
    
    global CS_SetupProductNodeBatch(list<ID> newsXtendIDsList) {

        isForInvalidPdts = false;
        newsXtendIDs = new Set<ID>();
        newsXtendIDs.addAll(newsXtendIDsList);
        
        // IV: added line Product_Node__c = NULL
        strQuery = 'SELECT Id,Name,Provider__c,Product_Line__c,Product_Type__c,Network__c, ' + 
                                        '       Record_Type_Name__c,HTML_IS__c,Payment_Type__c, ' +
                                        '       Basic_Price__c,Cost_Of_Goods__c,Cost_Model__c, ' +
                                        '       Maximum_Discount__c,Minimum_Order__c,Quantity_By__c, '  +
                                        '       Product_Groups_For_Investment_Summary__c, ' +
                                        '       Product_Groups_For_IO__c,Site_Section__c,Site_Section_Group__c, CreatedDate ' + 
                                        'FROM   News_Xtend_Product_Ref__c ' +
                                        'WHERE  Record_Type_Name__c = \'Product\' AND Provider__c <> null AND Product_Line__c <> null AND ' +
                                        '       Product_Type__c <> null AND Network__c <> null AND Product_Node__c = null AND ' +
                                        '       Id IN :newsXtendIDs ' +
                                        'ORDER BY Provider__c, Product_Line__c, Product_Type__c, Network__c, Name';
    }   
        
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(strQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<News_Xtend_Product_Ref__c> scope)
    {
        map<String, csmso__Business_Unit__c> businessUnits = new map<String, csmso__Business_Unit__c>();
        
        if (!isForInvalidPdts)
        {
            delete [select Id from csmso__Rate_Card_Item_Price__c];
            delete [select Id from csmso__Product_Node__c];
            delete [select Id from csmso__Business_Unit__c];
            
            businessUnits.put('NewsCorp Aust.', new csmso__Business_Unit__c(Name = 'NewsCorp Aust.', csmso__Sales_Ledger_Code__c = '0001'));
            businessUnits.put('News Xtend', new csmso__Business_Unit__c(Name = 'News Xtend', csmso__Sales_Ledger_Code__c = '0002'));
            businessUnits.put('News Corp Studios', new csmso__Business_Unit__c(Name = 'News Corp Studios', csmso__Sales_Ledger_Code__c = '0003'));
            
            insert businessUnits.values();      
        }
        else
        {
            for (csmso__Business_Unit__c bu : [select Name, csmso__Sales_Ledger_Code__c from csmso__Business_Unit__c])
                businessUnits.put(bu.Name, bu);
        }
            

        map<ID, csmso__Product_Node__c> mapProdRefIdToProductNode = new map<ID, csmso__Product_Node__c>();
        map<ID, csmso__Rate_Card__c> mapProdRefIdToRateCard = new map<ID, csmso__Rate_Card__c>();
        map<ID, csmso__Rate_Card_Item_Price__c> mapProdRefIdToRateCardItemPrice = new map<ID, csmso__Rate_Card_Item_Price__c>();
        

        
        //map<String, News_Xtend_Product_Ref__c> mapCombiToXtendProdRef = new map<String, News_Xtend_Product_Ref__c>();
        
        //for (News_Xtend_Product_Ref__c prodRef : scope)
        //{
        //  if (prodRef.Record_Type_Name__c != 'Network' || prodRef.Provider__c.contains('wrong'))
        //      continue;
                
        //  mapCombiToXtendProdRef.put(prodRef.Provider__c + '-' + prodRef.Product_Line__c + '-' + prodRef.Product_Type__c + '-' + prodRef.Name, prodRef);
        //}
        
        //system.debug('@@@@@@@@@ ALL COMBI ' + JSON.serializePretty(mapCombiToXtendProdRef)); 
        
        map<ID, News_Xtend_Product_Ref__c> productReferences = new map<ID, News_Xtend_Product_Ref__c>(scope);
            
        for (News_Xtend_Product_Ref__c prodRef : scope) 
        {
            //if (prodRef.Record_Type_Name__c != 'Product' || (prodRef.Provider__c == null || prodRef.Product_Line__c == null || prodRef.Product_Type__c == null || prodRef.Network__c == null))
            //  continue;
                
            //String strCombi = prodRef.Provider__c + '-' + prodRef.Product_Line__c + '-' + prodRef.Product_Type__c + '-' + prodRef.Network__c;
            //system.debug('@@@@@@@@@ MY COMBI ' + strCombi);
            //system.debug('@@@@@@@@@ MY ID ' + mapCombiToXtendProdRef.get(strCombi));

            csmso__Product_Node__c productNode = new csmso__Product_Node__c(    Name            = prodRef.Name,
                                                                                Provider__c     = prodRef.Provider__c,
                                                                                Product_Line__c = prodRef.Product_Line__c,
                                                                                Product_Type__c = prodRef.Product_Type__c,
                                                                                Network__c      = prodRef.Network__c,
                                                                                HTML_IS__c      = prodRef.HTML_IS__c,
                                                                                //News_Xtend_Product_Ref__c = mapCombiToXtendProdRef.get(strCombi),
                                                                                csmso__Media_Types__c = 'Digital',
                                                                                csmso__Business_Unit__c = businessUnits.get(prodRef.Provider__c).Id,
                                                                                csmso__Root_Node__c = false,
                                                                                Product_Groups_For_Investment_Summary__c = prodRef.Product_Groups_For_Investment_Summary__c,
                                                                                Product_Groups_For_IO__c = prodRef.Product_Groups_For_IO__c,
                                                                                Site_Section__c = prodRef.Site_Section__c,
                                                                                Site_Section_Group__c = prodRef.Site_Section_Group__c);
            mapProdRefIdToProductNode.put(prodRef.Id, productNode);         
            
            csmso__Rate_Card__c rateCard = new csmso__Rate_Card__c(csmso__From_Date__c = prodRef.CreatedDate.date());
            mapProdRefIdToRateCard.put(prodRef.Id, rateCard);
                
            csmso__Rate_Card_Item_Price__c rateCardItemPrice = new csmso__Rate_Card_Item_Price__c(  Basic_Price__c      = prodRef.Basic_Price__c,
                                                                                                    Cost_Model__c       = prodRef.Cost_Model__c,
                                                                                                    Cost_Of_Goods__c    = prodRef.Cost_Of_Goods__c,
                                                                                                    Maximum_Discount__c = prodRef.Maximum_Discount__c,
                                                                                                    Minimum_Order__c    = (prodRef.Minimum_Order__c == null ? 0 : prodRef.Minimum_Order__c),
                                                                                                    Payment_Type__c     = prodRef.Payment_Type__c,
                                                                                                    Quantity_By__c      = prodRef.Quantity_By__c);
            mapProdRefIdToRateCardItemPrice.put(prodRef.Id, rateCardItemPrice);
        }
        
        insert mapProdRefIdToProductNode.values();
        
        //list<Payment_Line_Item__c> paymentLineItems = [select News_Xtend_Product_Ref__c from Payment_Line_Item__c where News_Xtend_Product_Ref__c in :mapProdRefIdToProductNode.keySet()];
        
        //for (Payment_Line_Item__c paymentLineItem : paymentLineItems)
        //{
        //  if (paymentLineItem.News_Xtend_Product_Ref__c == null || !mapProdRefIdToProductNode.containsKey(paymentLineItem.News_Xtend_Product_Ref__c)) continue;
        //  paymentLineItem.Product_Node__c = mapProdRefIdToProductNode.get(paymentLineItem.News_Xtend_Product_Ref__c).Id;
        //}
        
        //update paymentLineItems;
        
        for (ID prodRefId : mapProdRefIdToProductNode.keySet())
        {
            if (!mapProdRefIdToRateCard.containsKey(prodRefId)) continue;
            
            ID productNodeId = mapProdRefIdToProductNode.get(prodRefId).Id;
            mapProdRefIdToRateCard.get(prodRefId).csmso__Product_Node__c = productNodeId;
            
            productReferences.get(prodRefId).Product_Node__c = productNodeId;
        }
        
        insert mapProdRefIdToRateCard.values();
        update productReferences.values();
        
        for (ID prodRefId : mapProdRefIdToRateCard.keySet())
        {
            csmso__Rate_Card__c rateCard = mapProdRefIdToRateCard.get(prodRefId);
            
            mapProdRefIdToRateCardItemPrice.get(prodRefId).csmso__Product_Node__c = rateCard.csmso__Product_Node__c;
            mapProdRefIdToRateCardItemPrice.get(prodRefId).csmso__Rate_Card__c = rateCard.Id;
        }
        
        insert mapProdRefIdToRateCardItemPrice.values();
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
    }
}