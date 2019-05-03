public class Creator_DataPrep {

    public static csmso__Sales_Order__c prepInsertionOrder(Map<String, Object> inputMap, Id salesOrderId) {
        
        //Get DataSources
        List<csdg__Data_Source__c> dss = [SELECT Id, Name, csdg__CustomerDataSourceId__c,csdg__Image_Name__c
													From csdg__Data_Source__c];
        Map<String, csdg__Data_Source__c> dsMap = new Map<String, csdg__Data_Source__c>();
        for(csdg__Data_Source__c ds : dss) {
            dsMap.put(ds.csdg__CustomerDataSourceId__c, ds);
        }
        
        //DUMMY 1 ROW
        //
        List<Map<String, String>> dummyOneRow = new List<Map<String, String>>();
        Map<String, String> dummy = new Map<String, String>();
        dummy.put('test','test');
        dummyOneRow.add(dummy);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004DF').Id, dummyOneRow);  
        
        csmso__Sales_Order__c salesOrder = [SELECT Id, Name,
                                                    csmso__Opportunity__r.Account.Name, 
                                                    csmso__Booking_Contact__r.Name, 
                                                    csmso__Opportunity__r.Account.datasan__Account_ABN__c, 
                                                    csmso__Opportunity__r.Account.Website, 
                                                    
                                                    
                                                    csmso__Opportunity__r.Account.Owner.Name, 
                                                    csmso__Opportunity__r.Account.Owner.Email, 
                                                    csmso__Opportunity__r.Account.Owner.MobilePhone,
                                            		csmso__Opportunity__r.Planner_Account__c,
													csmso__Opportunity__r.Payer_Account__c,
                                            		csmso__Advertiser__r.Name,
                                            		csmso__Advertiser__r.Billing_Status__c,

                                                    
                                                    csmso__Opportunity__r.Name,
                                                    csmso__Opportunity__r.CreatedDate, 
                                                    csmso__Opportunity__r.Campaign_Start_Date__c, 
                                                    csmso__Opportunity__r.Campaign_End_Date__c, 
                                                    csmso__Purchase_Order_Number__c,
                                                    
													Total_Duration_Price_GST_Inclusive__c, 
                                                    Total_Print_Duration_Price__c, 
                                                    Proposed_Print_Price__c, 
                                                    Target_Print_Price__c, 
                                                    Total_Print_Price_GST_inclusive__c, 
                                                    Recurring_Price__c,
                                                    GST_Tax__c,
                                                    Total_Xtend_Price_GST_Inclusive__c,
                                                    Total_Xtend_Price__c,
													One_Off_Price__c,
                                            		Dashboard__c,
                                            		Conversion_Tracking__c,
                                            		Creative_Services__c
                                                    
                                                    from csmso__Sales_Order__c 
                                                    WHERE Id = :salesOrderId];
        
        //PLANNER CONTACT
        List<Contact> contacts = [SELECT
                                Id,
                                Name, AccountId,
                                Email, 
                                Phone, 
                                MobilePhone,Is_Primary_Contact__c
                                From Contact
                                Where AccountId = :salesOrder.csmso__Opportunity__r.Planner_Account__c
                                LIMIT 1];
        Map<String, String> contactMap = new Map<String, String>();
        if(contacts.size() > 0) {
            Contact contact = contacts.get(0);
            contactMap.put('Name', contact.Name);
            contactMap.put('Email', contact.Email);
            contactMap.put('Phone', contact.Phone);
            contactMap.put('MobilePhone', contact.MobilePhone);
        }
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Cl').Id, contactMap);  
        
        
        //PAYER CONTACT
        List<Contact> payerContacts = [SELECT
                                Id,
                                Name, AccountId,
                                Email, 
                                Phone, 
                                MobilePhone,Is_Primary_Contact__c
                                From Contact
                                Where AccountId = :salesOrder.csmso__Opportunity__r.Payer_Account__c
                                LIMIT 1];
        Map<String, String> payerContactMap = new Map<String, String>();
        if(payerContacts.size() > 0) {
            Contact contact = payerContacts.get(0);
            payerContactMap.put('Name', contact.Name);
            payerContactMap.put('Email', contact.Email);
            payerContactMap.put('Phone', contact.Phone);
            payerContactMap.put('MobilePhone', contact.MobilePhone);
        }
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004D5').Id, payerContactMap);  
        
        AggregateResult[] groupedResults = [SELECT
                                                SUM(Total_Bundle_Duration_Price__c) sumBundleDurationPrice
                                            FROM cscfga__Product_Configuration__c
                                            WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :salesOrderId
                                                AND cscfga__Parent_Configuration__c = null 
                                                AND Bundle_Name__c != '/'
                                                AND Bundle_Name__c != null];
        
        Decimal sumBundleDurationPrice = (Decimal)groupedResults[0].get('sumBundleDurationPrice');
        if(sumBundleDurationPrice == null) {
            sumBundleDurationPrice = 0;
        }
        Decimal tax = 0;
        if(salesOrder.GST_Tax__c != null) {
            tax = salesOrder.GST_Tax__c;
        }
        Map<String, Decimal> SummaryTotals = new Map<String, Decimal>();
        SummaryTotals.put('TotalCostExclGst', sumBundleDurationPrice);
        if(tax != 0) {
        	SummaryTotals.put('TotalCostInclGst', sumBundleDurationPrice * (1 + (tax / 100) ) ) ;
        } else {
        	SummaryTotals.put('TotalCostInclGst', 0 ) ;
        }
        SummaryTotals.put('SetUpCostExclGst', salesOrder.One_Off_Price__c) ;
        if(tax != 0 && salesOrder.One_Off_Price__c != null) {
        	SummaryTotals.put('SetUpCostInclGst', salesOrder.One_Off_Price__c * (1 + (tax / 100) ) ) ;
        } else {
        	SummaryTotals.put('SetUpCostInclGst', 0 ) ;
        }
        //TOTAL CAMPAIGN SUMMARY
        Decimal soTargetPrintPrice = (salesOrder.Target_Print_Price__c == null ) ? 0 : salesOrder.Target_Print_Price__c; //PM 05/12/2018 fix for old SO's as salesforce still doesn't propagate default value of new fields on existing records
        SummaryTotals.put('CampaignTotalCostExclGst', sumBundleDurationPrice + salesOrder.Total_Xtend_Price__c + soTargetPrintPrice ) ;
        SummaryTotals.put('CampaignTotalCostInclGst', (sumBundleDurationPrice * (1 + (tax / 100) )) + 
                                        							salesOrder.Total_Xtend_Price_GST_Inclusive__c + salesOrder.Total_Print_Price_GST_inclusive__c ) ;
        SummaryTotals.put('Zero', 0.00);
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Bs').Id, SummaryTotals);

        Map<String, String> contants = new Map<String, String>();
        contants.put('NowFormatted', Datetime.now().format('MM-dd-yyyy HH:mm:ss'));
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004DA').Id, contants);
        
        //START - PRINT ADVERTISING CAMPAIGN 
        //Get all products
        //loop through and 
        //		prep a Set of publication state & type
        //		calculate totals ??? the data are already totals
        //		Get Start & End Date
        //add Set to inputmap
        //add pulications to inputmap
        //add totals to inputmap
        
        List<cscfga__Product_Configuration__c> pcsPrintAdvCampaign = [SELECT
                                            Id,
                                            Name,
                                            Publication_Type__c, Publication_State__c,
                                            Publication__c,
                                            Selected_Dates__c, 
                                            Ad_Size__c, 
                                            Section__c, 
                                            Subsection__c, 
                                            Ad_Size_Rate_Card__c, 
                                            cscfga__Product_Basket__r.csmso__Sales_Order__r.Proposed_Print_Discount__c, 
                                            cscfga__Product_Basket__r.csmso__Sales_Order__r.Total_Print_Price__c,
                                            cscfga__Product_Basket__r.csmso__Sales_Order__r.Proposed_Print_Price__c,
                                            Platform__c,
                                            Cycle__c,
                                            Duration__c,
                                            Position__c, 
                                            Proposed_Discount__c, 
                                            Total_Print_Duration_Price__c, 
                                            Proposed_Discount_Amount__c, 
                                            Line_Item_Duration_Price__c,
                                            Impressions_Quantity__c,
                                            Price_Per_Impression__c
                                        FROM cscfga__Product_Configuration__c
                                        WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :salesOrderId AND
                                            cscfga__Parent_Configuration__c = null AND
                                            Name = 'Print Display'
                                        ORDER BY
                                        	Publication_State__c, Publication_Type__c, Publication__c];
        
        List<Map<String, String>> pcsPrintAdvCampaigns = new List<Map<String, String>>();
        List<Map<String, String>> pubTypeStatesList = new List<Map<String, String>>();
        List<Map<String, String>> pubTypeStatesSelDatesList = new List<Map<String, String>>();
        Map<String, Map<String, String>> pubTypeStatesMap = new Map<String, Map<String, String>>();
        Set<String> pubTypeStates = new Set<String>();
        //Calculate 'Total Print Discount Amount '
        SummaryTotals.put('PrintTotalPrintDiscountAmountExGst', 0.00 ) ;
        for(cscfga__Product_Configuration__c pc : pcsPrintAdvCampaign) {
            Map<String, String> pcData = new Map<String, String>();            
            String pubTypeState = pc.Publication_State__c + ' - ' + pc.Publication_Type__c;
            Map<String, String> pubTypeStateMap = pubTypeStatesMap.get( pubTypeState );
            if( pubTypeStateMap == null ) {
                pubTypeStates.add(pubTypeState);
                
            	pubTypeStateMap = new Map<String, String>();
            	pubTypeStateMap.put('pubTypeState', pubTypeState);
            	pubTypeStateMap.put('SubTotal_Total_Print_Duration_Price__c', '0.00');
            	pubTypeStateMap.put('SubTotal_Proposed_Discount_Amount__c', '0.00');
            	pubTypeStateMap.put('SubTotal_Line_Item_Duration_Price__c', '0.00');
                pubTypeStatesList.add(pubTypeStateMap);
                pubTypeStatesMap.put(pubTypeState, pubTypeStateMap);
            }
            Decimal SubTotal_Total_Print_Duration_Price = Decimal.valueOf(pubTypeStateMap.get('SubTotal_Total_Print_Duration_Price__c'));
            SubTotal_Total_Print_Duration_Price = SubTotal_Total_Print_Duration_Price + pc.Total_Print_Duration_Price__c;
            pubTypeStateMap.put('SubTotal_Total_Print_Duration_Price__c', String.valueOf(SubTotal_Total_Print_Duration_Price));
            
            Decimal SubTotal_Proposed_Discount_Amount = Decimal.valueOf(pubTypeStateMap.get('SubTotal_Proposed_Discount_Amount__c'));
            SubTotal_Proposed_Discount_Amount = SubTotal_Proposed_Discount_Amount + pc.Proposed_Discount_Amount__c;
            pubTypeStateMap.put('SubTotal_Proposed_Discount_Amount__c', String.valueOf(SubTotal_Proposed_Discount_Amount));
            
            Decimal SubTotal_Line_Item_Duration_Price = Decimal.valueOf(pubTypeStateMap.get('SubTotal_Line_Item_Duration_Price__c'));
            SubTotal_Line_Item_Duration_Price = SubTotal_Line_Item_Duration_Price + pc.Line_Item_Duration_Price__c;
            pubTypeStateMap.put('SubTotal_Line_Item_Duration_Price__c', String.valueOf(SubTotal_Line_Item_Duration_Price));
            
            
            pcData.put('Id', pc.Id);
            pcData.put('pubTypeState', pubTypeState);
            pcData.put('Publication_Type__c', pc.Publication_Type__c);
            pcData.put('Publication__c', pc.Publication__c);
            
            //Selected Dates
            List<String> dates = (List<String>)System.JSON.deserialize(pc.Selected_Dates__c, List<String>.class);
            if(dates.size() > 0) {
            	pcData.put('PublishDate', dates[0]);
            	pcData.put('EndDate', dates[dates.size()-1]);
            	pcData.put('InsertionDate', selectedDatesToString(dates));
            }
            
            pcData.put('Ad_Size__c', pc.Ad_Size__c);
            pcData.put('Section__c', pc.Section__c);
            pcData.put('Subsection__c', pc.Subsection__c);
            pcData.put('Ad_Size_Rate_Card__c', String.valueOf(pc.Ad_Size_Rate_Card__c));
            pcData.put('Proposed_Print_Discount__c', String.valueOf(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.Proposed_Print_Discount__c));
            pcData.put('Total_Print_Price__c', String.valueOf(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.Total_Print_Price__c));
            pcData.put('Proposed_Print_Price__c', String.valueOf(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.Proposed_Print_Price__c));
            pcData.put('Cycle__c', pc.Cycle__c);
            pcData.put('Duration__c', pc.Duration__c);
            pcData.put('Proposed_Discount__c', String.valueOf(pc.Proposed_Discount__c));
            pcData.put('Total_Print_Duration_Price__c', String.valueOf(pc.Total_Print_Duration_Price__c));
            pcData.put('Proposed_Discount_Amount__c', String.valueOf(pc.Proposed_Discount_Amount__c));
            pcData.put('Line_Item_Duration_Price__c', String.valueOf(pc.Line_Item_Duration_Price__c));
            pcData.put('Impressions_Quantity__c', String.valueOf(pc.Impressions_Quantity__c));
            pcData.put('Price_Per_Impression__c', String.valueOf(pc.Price_Per_Impression__c));
            pcData.put('Position__c', pc.Position__c);
            
            pcsPrintAdvCampaigns.add(pcData);
            
            //add SelectedDates record 
            if(pc.Impressions_Quantity__c > 1) {
            	Map<String, String> mapDates = new Map<String, String>();
                mapDates.put('parentId', pc.Id);
                mapDates.put('InsertionDates', selectedDatesToString(dates));
                
                pubTypeStatesSelDatesList.add(mapDates);
            }
            
            //Calculate 'Total Print Discount Amount '
            Decimal tempPrintTotalPrintDiscountAmountExGst = SummaryTotals.get('PrintTotalPrintDiscountAmountExGst');
            tempPrintTotalPrintDiscountAmountExGst = tempPrintTotalPrintDiscountAmountExGst + pc.Proposed_Discount_Amount__c;
            SummaryTotals.put('PrintTotalPrintDiscountAmountExGst', tempPrintTotalPrintDiscountAmountExGst);
        }
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004C7').Id, pubTypeStatesList);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004CC').Id, pcsPrintAdvCampaigns);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Em').Id, pubTypeStatesSelDatesList);
        
        //END - PRINT ADVERTISING CAMPAIGN 
        
        
        
        //START - BUNDLE CAMPAIGN "PRINT LED"
        
        List<cscfga__Product_Configuration__c> pcsBundlePrintLed = [SELECT
            	Id
            FROM cscfga__Product_Configuration__c
            WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :salesOrderId 
                    AND Name = 'Print Led' 
                    AND cscfga__Parent_Configuration__c = null];
        
        List<cscfga__Product_Configuration__c> pcsBundlePrintLedPrints = [SELECT
                                        Id,
                                        Name,
                                        cscfga__Parent_Configuration__c,
                                        cscfga__Parent_Configuration__r.Cycle__c,
                                        Publication_State__c, 
                                        Publication_Type__c, 
										Publication__c,
                                        Selected_Dates__c, 
                                        Impressions_Quantity__c,
                                        Ad_Size__c, 
                                        Section__c, 
                                        Subsection__c, 
                                        Platform__c,
                                        Cycle__c,
                                        Duration__c
                                    FROM cscfga__Product_Configuration__c
                                    WHERE cscfga__Parent_Configuration__c IN :pcsBundlePrintLed AND
                                    	Platform__c = 'Print'
                                    ORDER BY
                                        Publication_State__c, Publication_Type__c, Publication__c];
        
        List<Map<String, String>> pcsBundleLedPrintAdv = new List<Map<String, String>>();
        List<Map<String, String>> pcsBundleLedPrintAdvSelDates = new List<Map<String, String>>();
        List<Map<String, String>> pubTypeStatesBundleLedPrintList = new List<Map<String, String>>();
        Set<String> pubTypeStatesBundleLedPrint = new Set<String>();
        Set<String> pubTypeStatesBundleLedPrintAdvSelDates = new Set<String>();
        for(cscfga__Product_Configuration__c pc : pcsBundlePrintLedPrints) {
            Map<String, String> pcData = new Map<String, String>();
            
            String pubTypeState = pc.Publication_State__c + ' - ' + pc.Publication_Type__c;
            String pubTypeStateUnique = pubTypeState + ' - ' + pc.cscfga__Parent_Configuration__c;
            if( !pubTypeStatesBundleLedPrint.contains( pubTypeStateUnique ) ) {
                pubTypeStatesBundleLedPrint.add(pubTypeStateUnique);
                
            	Map<String, String> pubTypeStateMap = new Map<String, String>();
            	pubTypeStateMap.put('pubTypeState', pubTypeState);
            	pubTypeStateMap.put('pubTypeStateUnique', pubTypeStateUnique);
            	pubTypeStateMap.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
                pubTypeStatesBundleLedPrintList.add(pubTypeStateMap);
            }
            
            pcData.put('Id', pc.Id);
            pcData.put('pubTypeState', pubTypeState);
            pcData.put('pubTypeStateUnique', pubTypeStateUnique);
            pcData.put('Publication_State__c', pc.Publication_State__c);
            pcData.put('Publication_Type__c', pc.Publication_Type__c);
            pcData.put('Publication__c', pc.Publication__c);
            pcData.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
            
            //Selected Dates
            List<String> dates = (List<String>)System.JSON.deserialize(pc.Selected_Dates__c, List<String>.class);
            if(dates.size() > 0) {
            	pcData.put('PublishDate', dates[0]);
            	pcData.put('EndDate', dates[dates.size()-1]);
                //add SelectedDates record 
                if(pc.Impressions_Quantity__c > 1) {
            		Map<String, String> mapDates = new Map<String, String>();
                	mapDates.put('parentId', pc.Id);
            		mapDates.put('InsertionDates', selectedDatesToString(dates));
                    pcsBundleLedPrintAdvSelDates.add(mapDates);
                }
                /*
                if(!pubTypeStatesBundleLedPrintAdvSelDates.contains(pc.cscfga__Parent_Configuration__c) && pc.Impressions_Quantity__c > 1) {
                    pubTypeStatesBundleLedPrintAdvSelDates.add(pc.cscfga__Parent_Configuration__c);
            		Map<String, String> mapDates = new Map<String, String>();
                    mapDates.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
            		mapDates.put('InsertionDates', selectedDatesToString(dates));
                    pcsBundleLedPrintAdvSelDates.add(mapDates);
                }
				*/
            }
            
            pcData.put('Ad_Size__c', pc.Ad_Size__c);
            pcData.put('Section__c', pc.Section__c);
            pcData.put('Subsection__c', pc.Subsection__c);
            pcData.put('Impressions_Quantity__c', String.valueOf(pc.Impressions_Quantity__c));
            pcData.put('Cycle__c', pc.Cycle__c);
            pcData.put('cscfga__Parent_Configuration__r.Cycle__c', pc.cscfga__Parent_Configuration__r.Cycle__c);
            pcData.put('Duration__c', pc.Duration__c);
            
            pcsBundleLedPrintAdv.add(pcData);
        }
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Cv').Id, pubTypeStatesBundleLedPrintList);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004CM').Id, pcsBundleLedPrintAdv);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Ec').Id, pcsBundleLedPrintAdvSelDates);
        //END - BUNDLE CAMPAIGN "PRINT LED"
        
        
        
        //START - BUNDLE CAMPAIGN "XTEND LED"
        
        List<cscfga__Product_Configuration__c> pcsBundleXtendLed = [SELECT
            	Id
            FROM cscfga__Product_Configuration__c
            WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :salesOrderId 
                AND Name = 'Xtend Led' 
                AND cscfga__Parent_Configuration__c = null];
        
        List<cscfga__Product_Configuration__c> pcsBundleXtendLedPrints = [SELECT
                                        Id,
                                        Name,
                                        cscfga__Parent_Configuration__c,
                                        Publication_State__c, 
                                        Publication_Type__c, 
                                        Publication__c,
                                        Selected_Dates__c, 
                                        Impressions_Quantity__c,
                                        Ad_Size__c, 
                                        Section__c, 
                                        Subsection__c, 
                                        Platform__c,
                                        Cycle__c,
                                        Duration__c
                                    FROM cscfga__Product_Configuration__c
                                    WHERE cscfga__Parent_Configuration__c IN :pcsBundleXtendLed AND
                                    	Platform__c = 'Print'
                                    ORDER BY
                                        Publication_State__c, Publication_Type__c, Publication__c];
        
        List<Map<String, String>> pcsBundleXtendLedPrintAdv = new List<Map<String, String>>();
        List<Map<String, String>> pcsBundleXtendLedPrintAdvSelDates = new List<Map<String, String>>();
        List<Map<String, String>> pubTypeStatesBundleXtendLedList = new List<Map<String, String>>();
        Set<String> pubTypeStatesBundleXtendLed = new Set<String>();
        Set<String> pubTypeStatesBundleXtendLedPrintAdvSelDates = new Set<String>();
        for(cscfga__Product_Configuration__c pc : pcsBundleXtendLedPrints) {
            Map<String, String> pcData = new Map<String, String>();
            
            String pubTypeStateText = pc.Publication_State__c + ' - ' + pc.Publication_Type__c;
            String pubTypeStateUnique = pubTypeStateText + ' - ' + pc.cscfga__Parent_Configuration__c;
            if( !pubTypeStatesBundleXtendLed.contains( pubTypeStateUnique ) ) {
                pubTypeStatesBundleXtendLed.add(pubTypeStateUnique);
                
            	Map<String, String> pubTypeStateMap = new Map<String, String>();
            	pubTypeStateMap.put('pubTypeState', pubTypeStateUnique);
            	pubTypeStateMap.put('pubTypeStateText', pubTypeStateText);
            	pubTypeStateMap.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
                pubTypeStatesBundleXtendLedList.add(pubTypeStateMap);
            }
            
            pcData.put('pubTypeState', pubTypeStateUnique);
            pcData.put('Publication_State__c', pc.Publication_State__c);
            pcData.put('Publication_Type__c', pc.Publication_Type__c);
            pcData.put('Publication__c', pc.Publication__c);
            pcData.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
            
            //Selected Dates
            List<String> dates = (List<String>)System.JSON.deserialize(pc.Selected_Dates__c, List<String>.class);
            if(dates.size() > 0) {
            	pcData.put('PublishDate', dates[0]);
            	pcData.put('EndDate', dates[dates.size()-1]);
                /* WE TAKE THIS OUT AS THESE ARE EVERGREEN, INSERTION DATE NOT REQUIRED AS INPUT (MAIL) BY PARTHEEVA ON 29/10
                if( !pubTypeStatesBundleXtendLedPrintAdvSelDates.contains(pc.cscfga__Parent_Configuration__c) && pc.Impressions_Quantity__c > 1 ) {
                    pubTypeStatesBundleXtendLedPrintAdvSelDates.add(pc.cscfga__Parent_Configuration__c);
            		Map<String, String> mapDates = new Map<String, String>();
                    mapDates.put('cscfga__Parent_Configuration__c', pc.cscfga__Parent_Configuration__c);
            		mapDates.put('InsertionDates', selectedDatesToString(dates));
                    pcsBundleXtendLedPrintAdvSelDates.add(mapDates);
                }
				*/
            }
            
            pcData.put('Ad_Size__c', pc.Ad_Size__c);
            pcData.put('Section__c', pc.Section__c);
            pcData.put('Subsection__c', pc.Subsection__c);
            pcData.put('Impressions_Quantity__c', String.valueOf(pc.Impressions_Quantity__c));
            pcData.put('Cycle__c', pc.Cycle__c);
            pcData.put('Duration__c', pc.Duration__c);
            
            pcsBundleXtendLedPrintAdv.add(pcData);
        }
        
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004D0').Id, pubTypeStatesBundleXtendLedList);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004CX').Id, pcsBundleXtendLedPrintAdv);
        inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Eh').Id, pcsBundleXtendLedPrintAdvSelDates);
        
        //END - BUNDLE CAMPAIGN "XTEND LED"
        
        
        //START - XTEND DESCRIPTION
        
        Insertion_Order_Spec__c ios = [SELECT 
                                            Id, 
                                            Name,Line_Item_Columns__c
                                        FROM Insertion_Order_Spec__c
                                        WHERE Name = 'InsertionOrderSpec'];
        //this will now return all attribute names relevant for all 
        List<String> partsList = ios.Line_Item_Columns__c.split(',');
        partsList.add('Product Groups For IO'); //this must always be there
        Set<String> parts = new Set<String>(partsList);
        System.debug('parts: ' + parts);
        
        List<Map<String, String>> newsXtendList = new List<Map<String, String>>();
        List<Map<String, String>> newsXtendAlwaysOnList = new List<Map<String, String>>();
        List<Map<String, String>> newsXtendPrintLedBundleList = new List<Map<String, String>>();
        List<Map<String, String>> newsXtendLedBundleList = new List<Map<String, String>>();
        List<cscfga__Attribute__c> atts =[SELECT Id, 
                                                Name, 
                                                cscfga__Value__c,
                                          		cscfga__Product_Configuration__c,
        										cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c,
        										cscfga__Product_Configuration__r.cscfga__Parent_Configuration__r.Name,
        										cscfga__Product_Configuration__r.Name,
        										cscfga__Product_Configuration__r.Product_Type_Name__c,
                                                cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c,
                                          		cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date__c
                                            FROM cscfga__Attribute__c 
                                            WHERE 
                                                cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c  = :salesOrderId
            									AND (cscfga__Product_Configuration__r.Name = 'News Xtend' OR cscfga__Product_Configuration__r.Platform__c = 'Xtend'
                                                     OR cscfga__Product_Configuration__r.Platform__c = 'Xtend')
                                                AND Name IN :parts];
        System.debug('XTEND DESCRIPTION nr of attributes: ' + atts.size());
        if(atts.size() > 0) {
            //we are mapping the attributes
            //	per product type
            //		per parent (can be null)
            //			per Attribute name
            Map<String, Map<String, Map<String, List<cscfga__Attribute__c>>>> attributesMap = new Map<String, Map<String, Map<String, List<cscfga__Attribute__c>>>>();
            List<cscfga__Attribute__c> productGroupsForIOs = new List<cscfga__Attribute__c>();
            Map<String, String> mapAttrNameForProdConfId = new Map<String, String>();
            Boolean hasNewsXtend = false;
            Boolean hasNewsXtendAlwaysOn = false;
            Boolean hasNewsXtendInXtendLed = false;
            Boolean hasNewsXtendInPrintLed = false;
            
            Set<String> prodGroups = new Set<String>();
            //Loop these to get all the 'Product Groups For IO'
            for(cscfga__Attribute__c att : atts) {
                if(att.Name == 'Product Groups For IO') {
                    prodGroups.add(att.cscfga__Value__c);
                    productGroupsForIOs.add(att);
                    mapAttrNameForProdConfId.put(att.cscfga__Product_Configuration__c, att.cscfga__Value__c);
                }
                String mapName = '';
                if(isNewsXtend(att)) {
                    mapName = 'News Xtend';
                    hasNewsXtend = true;
                    System.debug('Has News Xtend');
                } else if (isNewsXtendAlwaysOn(att)) {
                    //is News Xtend Always On
                    mapName = 'News Xtend Always On';
                    hasNewsXtendAlwaysOn = true;
                    System.debug('Has News Xtend Always On');
                } else if (isNewsXtendInXtendLed(att)) {
                    //is News Xtend Led Bundle
                    mapName = 'News Xtend Led';
                    hasNewsXtendInXtendLed = true;
                    System.debug('News Xtend Led');
                } else if (isNewsXtendInPrintLed(att)) {
                    //is News Print Led Bundle
                    mapName = 'News Xtend Print Led';
                    hasNewsXtendInPrintLed = true;
                    System.debug('News Xtend Print Led');
                }
                if(isNewsXtend(att) || isNewsXtendAlwaysOn(att)) {
                    System.debug('yep, this is out of bundle');
                    //is News Xtend
                    //is News Xtend Always On
                    Map<String, Map<String, List<cscfga__Attribute__c>>> newsXtend = attributesMap.get(mapName);
                    if(newsXtend == null) {
                        newsXtend = new Map<String, Map<String, List<cscfga__Attribute__c>>>();
                        attributesMap.put(mapName, newsXtend);
                    }
                    Map<String, List<cscfga__Attribute__c>> attNames = newsXtend.get('null'); //never has a parent
                    if(attNames == null) {
                        attNames = new Map<String, List<cscfga__Attribute__c>>();
                        newsXtend.put('null', attNames);
                    }
                    List<cscfga__Attribute__c> attLocal = attNames.get(att.Name);
                    if(attLocal == null) {
                        attLocal = new List<cscfga__Attribute__c>();
                    }
                    attLocal.add(att);
                    attNames.put(att.Name, attLocal);
                                          
                } else if (isNewsXtendInXtendLed(att) || isNewsXtendInPrintLed(att)) {
                    System.debug('yep, this is in bundle');
                    //is News Xtend Led Bundle
                    Map<String, Map<String, List<cscfga__Attribute__c>>> newsXtend = attributesMap.get(mapName);
                    if(newsXtend == null) {
                        newsXtend = new Map<String, Map<String, List<cscfga__Attribute__c>>>();
                        attributesMap.put(mapName, newsXtend);
                    }
                    Map<String, List<cscfga__Attribute__c>> attNames = newsXtend.get(att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c);
                    if(attNames == null) {
                        attNames = new Map<String, List<cscfga__Attribute__c>>();
                        newsXtend.put(att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c, attNames);
                    }
                    List<cscfga__Attribute__c> attLocal = attNames.get(att.Name);
                    if(attLocal == null) {
                        attLocal = new List<cscfga__Attribute__c>();
                    }
                    attLocal.add(att);
                    attNames.put(att.Name, attLocal);
                       
                }
            }
            
            //Campaign Mgmt
            //	the idea is to select the rows for Campaign Mgmt, Dashboard, ... and combine them into 1 extra row for the data on the products
            NewsXtendIORef__c campaignMgmt = null;
            NewsXtendIORef__c dashboard = null;
            NewsXtendIORef__c conversionTracking = null;
            NewsXtendIORef__c creativeServices = null;
            Boolean isCampaignMgmt = false;
            if(salesOrder.Dashboard__c) {
                System.debug('yep, Dashboard__c');
                prodGroups.add('Dashboard');
                isCampaignMgmt = true;
            }
            if(salesOrder.Conversion_Tracking__c) {
                System.debug('yep, Conversion_Tracking__c');
                prodGroups.add('Conversion Tracking');
                isCampaignMgmt = true;
            }
            if(salesOrder.Creative_Services__c) {
                System.debug('yep, Creative_Services__c');
                prodGroups.add('Creative Services');
                isCampaignMgmt = true;
            }
            if(isCampaignMgmt) {
                System.debug('yep, isCampaignMgmt');
                prodGroups.add('Campaign Management');
            }
            
            List<NewsXtendIORef__c> NewsXtendIORefs = [SELECT 
                                Id, 
                                Name, 
                                Campaign_Element__c,
                                    Total_Value_Attribute_Name__c, 
                                Details_Rich_Text__c
                            FROM NewsXtendIORef__c 
                            WHERE
                                Name IN :prodGroups];
            
            Map<String, NewsXtendIORef__c> NewsXtendIORefMap = new Map<String, NewsXtendIORef__c>();
            List<Id> NewsXtendIORefIds = new List<Id>();
            for(NewsXtendIORef__c NewsXtendIORef : NewsXtendIORefs) {
                NewsXtendIORefMap.put(NewsXtendIORef.Name, NewsXtendIORef);
                NewsXtendIORefIds.add(NewsXtendIORef.Id);
                if(NewsXtendIORef.Name == 'Campaign Management') {
                	System.debug('IO Ref: Campaign Management');
                    campaignMgmt = NewsXtendIORef;
                }
                if(NewsXtendIORef.Name == 'Creative Services') {
                	System.debug('IO Ref: Creative Services');
                    creativeServices = NewsXtendIORef;
                }
                if(NewsXtendIORef.Name == 'Conversion Tracking') {
                	System.debug('IO Ref: Conversion Tracking');
                    conversionTracking = NewsXtendIORef;
                }
                if(NewsXtendIORef.Name == 'Dashboard') {
                	System.debug('IO Ref: Dashboard');
                    dashboard = NewsXtendIORef;
                }
            }
            csdg__Data_Source__c dsPic = dsMap.get('00D0k0000000rou_a7W0k00000004DZ');
            //Get all related pictures
            List<ContentDocumentLink> pics = [SELECT ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.Title, LinkedEntityId 
             FROM ContentDocumentLink 
             WHERE LinkedEntityId IN :NewsXtendIORefIds AND IsDeleted=false AND ContentDocument.LatestPublishedVersion.Title = :dsPic.csdg__Image_Name__c];
            
            List<Map<String, Object>> linkedPics = new List<Map<String, Object>>();
            for(ContentDocumentLink cdl : pics) {
                Map<String, Object> result = new Map<String, Object>();
                
                result.put('name', cdl.ContentDocument.LatestPublishedVersion.Title);
                result.put('base64', cdl.ContentDocument.LatestPublishedVersion.VersionData);
                result.put('parentId', cdl.LinkedEntityId);
                
                linkedPics.add(result);
            }
            //do this for all DS with news Xtend
            if(hasNewsXtend) {
            	inputMap.put(dsPic.Id, linkedPics);
            }
            if(hasNewsXtendAlwaysOn) {
            	inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004DP').Id, linkedPics);
            }
            if(hasNewsXtendInXtendLed) {
            	inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004Dj').Id, linkedPics);
            }
            if(hasNewsXtendInPrintLed) {
            	inputMap.put(dsMap.get('00D0k0000000rou_a7W0k00000004E3').Id, linkedPics);
            }
            
            //Campaign Mgmt
            //	Create 1 row for all items
            Map<String, String> campaingMgmtData = new Map<String, String>();
            Boolean isCampaignMgmtAdded = false; //we only want to add it to one list, so need to check if added or not
            if(isCampaignMgmt) {
               	System.debug('Yep, it has CampaignMgmt so lets process');
                campaingMgmtData.put('cscfga__Parent_Configuration__c', null);
                campaingMgmtData.put('Product_Type_Name__c', campaignMgmt.Name);
                campaingMgmtData.put('Campaign_Element__c', campaignMgmt.Campaign_Element__c);
                campaingMgmtData.put('NewsXtendIORef_Id', campaignMgmt.Id);
                String details = '';
                Boolean isFirst = true;
                if(salesOrder.Dashboard__c) {
                    details += dashboard.Details_Rich_Text__c;
                    isFirst = false;
                }
                if(salesOrder.Conversion_Tracking__c) {
                    if( !isFirst ) {
                        details += '<br>';
                    }
                    isFirst = false;
                    details += conversionTracking.Details_Rich_Text__c;
                }
                if(salesOrder.Creative_Services__c) {
                    if( !isFirst ) {
                        details += '<br>';
                    }
                    isFirst = false;
                    details += creativeServices.Details_Rich_Text__c;
                }
               	System.debug('Yep, it has CampaignMgmt so lets process: ' + details);
                campaingMgmtData.put('Details', details);
            }
            //Per NewsXtend item, we need maps
            //per parent-PC and ProductGroup (News Xtend will not have a Parent PC so they will only group per ProdGroup)
            Set<String> checkProdConfProcessed = new Set<String>();
            //loop through all attributes
            //	check type NewsXtend, NewsXtendAlwaysOn, ...
            for(cscfga__Attribute__c att : productGroupsForIOs) {
                String key = att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c + '_' + att.cscfga__Value__c;
                //Check that this value eg 'Audience Taeieted Display' is only processed 1 time per Parent. we only want to see it 1 time in the list on the IO
                if( !checkProdConfProcessed.contains(key) ) {
                    checkProdConfProcessed.add(key);
                    
                    //String key = att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c + '_' + 
                    Map<String, String> pcData = new Map<String, String>();
                    
                    NewsXtendIORef__c NewsXtendIORef = NewsXtendIORefMap.get(att.cscfga__Value__c);
                    if(NewsXtendIORef == null) {
                        NewsXtendIORef = new NewsXtendIORef__c();
                    }
                    String sumColumn = NewsXtendIORef.Total_Value_Attribute_Name__c;
                    System.debug('sumColumn: ' + sumColumn);
                    String details = NewsXtendIORef.Details_Rich_Text__c;
                    System.debug('details: ' + details);
                    pcData.put('cscfga__Parent_Configuration__c', att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c);
                    pcData.put('Product_Type_Name__c', att.cscfga__Product_Configuration__r.Product_Type_Name__c);
                    pcData.put('Campaign_Element__c', NewsXtendIORef.Campaign_Element__c);
                    pcData.put('NewsXtendIORef_Id', NewsXtendIORef.Id);
                    
                    String mapName = '';
                    String mapProdParent = 'null';
                    if(isNewsXtend(att)) {
                        //is News Xtend
                        System.debug('Nexs Xtend for map');
                        newsXtendList.add(pcData);
                        mapName = 'News Xtend';
                        mapProdParent = 'null';
                    } else if (isNewsXtendAlwaysOn(att)) {
                        //is News Xtend Always On
                        System.debug('Nexs Xtend Always On for map');
                        newsXtendAlwaysOnList.add(pcData);
                        mapName = 'News Xtend Always On';
                        mapProdParent = 'null';
                           
                    } else if (isNewsXtendInXtendLed(att)) {
                        //is News Xtend Led Bundle
                        System.debug('News Xtend Led Bundle On for map');
                        newsXtendLedBundleList.add(pcData);
                        mapName = 'News Xtend Led';
                        mapProdParent = att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c;
                		campaingMgmtData.put('cscfga__Parent_Configuration__c', mapProdParent);
                           
                    } else if (isNewsXtendInPrintLed(att)) {
                        //is News Print Led Bundle
                        System.debug('News Print Led Bundle On for map');
                        newsXtendPrintLedBundleList.add(pcData);
                        mapName = 'News Xtend Print Led';
                        mapProdParent = att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c;
                		campaingMgmtData.put('cscfga__Parent_Configuration__c', mapProdParent);
                    }
                    //do summation of all attributes
                    if(!String.isEmpty(sumColumn)) {
                        Map<String, List<cscfga__Attribute__c>> attNames = attributesMap.get(mapName).get(mapProdParent);
                        List<cscfga__Attribute__c> attsLocal = attNames.get(sumColumn);
                        Double val = 0;
                        for(cscfga__Attribute__c attLocal : attsLocal) {
                             if(mapAttrNameForProdConfId.get(attLocal.cscfga__Product_Configuration__c) == att.cscfga__Value__c) {
                                val += Double.valueOf(attLocal.cscfga__Value__c);
                            }
                        }
                        System.debug('Summation replacement: ' + val);
                        System.debug('Summation replacement details: ' + details);
                        details = details.replace('&lt;0&gt;', val.format());
                    }
                    System.debug('details: ' + details);
                    pcData.put('Details', details);
                }
            }

            //Campaign Mgmt
            //	add the line to the data
            
            if(hasNewsXtend && isCampaignMgmt && !isCampaignMgmtAdded) {
                System.debug('Adding line for News Xtend');
                newsXtendList.add(campaingMgmtData);
                isCampaignMgmtAdded = true;
            } else if (hasNewsXtendAlwaysOn && isCampaignMgmt && !isCampaignMgmtAdded) {
                System.debug('Adding line for News Xtend Always On');
                newsXtendAlwaysOnList.add(campaingMgmtData);
                isCampaignMgmtAdded = true;
            } else if (hasNewsXtendInXtendLed && isCampaignMgmt && !isCampaignMgmtAdded) {
                System.debug('Adding line for News Xtend in Xtend Led bundle');
                newsXtendLedBundleList.add(campaingMgmtData);
                isCampaignMgmtAdded = true;
            } else if (hasNewsXtendInPrintLed && isCampaignMgmt && !isCampaignMgmtAdded) {
                System.debug('Adding line for News Xtend in Print Led bundle');
                newsXtendPrintLedBundleList.add(campaingMgmtData);
                isCampaignMgmtAdded = true;
            }
        }
            
        String dsIdNewsXtendAlwaysOn = '00D0k0000000rou_a7W0k00000004EI';
        String dsIdNewsXtend = '00D0k0000000rou_a7W0k00000004ED';
        String dsIdNewsXtendPrintLedBundle = '00D0k0000000rou_a7W0k00000004ES';
        String dsIdNewsXtendLedBundle = '00D0k0000000rou_a7W0k00000004EN';
            
        inputMap.put(dsMap.get(dsIdNewsXtend).Id, newsXtendList);
        inputMap.put(dsMap.get(dsIdNewsXtendAlwaysOn).Id, newsXtendAlwaysOnList);
        inputMap.put(dsMap.get(dsIdNewsXtendPrintLedBundle).Id, newsXtendPrintLedBundleList);
        inputMap.put(dsMap.get(dsIdNewsXtendLedBundle).Id, newsXtendLedBundleList);
        //END - XTEND DESCRIPTION
        //
        return salesOrder;
    }
    
    private static boolean isNewsXtend(cscfga__Attribute__c att) {
        return att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c == null &&
               att.cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date__c != null;
    }
    
    private static boolean isNewsXtendAlwaysOn(cscfga__Attribute__c att) {
        return att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c == null &&
               att.cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date__c == null;
    }
    
    private static boolean isNewsXtendInPrintLed(cscfga__Attribute__c att) {
        return att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c != null &&
               att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__r.Name == 'Print Led';
    }
    
    private static boolean isNewsXtendInXtendLed(cscfga__Attribute__c att) {
        return att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c != null &&
               att.cscfga__Product_Configuration__r.cscfga__Parent_Configuration__r.Name == 'Xtend Led';
    }
    
    private static String selectedDatesToString(List<String> dates) {
        String insertionDate = '[';
        boolean first = true;
        for(String mydate : dates) {
            if( !first ) {
                insertionDate += ', ';
            }
            first = false;
            List<String> temps = mydate.split('-');
            insertionDate += temps[2];
            insertionDate += '/';
            insertionDate += temps[1];
            insertionDate += '/';
            insertionDate += temps[0];
        }
        insertionDate += ']';
        
        return insertionDate;
    }
}