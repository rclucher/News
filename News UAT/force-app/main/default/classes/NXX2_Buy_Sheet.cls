/*------------------------------------------------------------
Author:        Rinaldo Clucher
Company:       Salesforce
Description:   Class to set BuySheet specific fields in the Product Order Object.
                
Test Class:    NXX2_Buy_Sheet_Test

History
<Date>      <Authors Name>     <Brief Description of Change>
20/10/2018  Rinaldo Clucher        Created
------------------------------------------------------------*/

public class NXX2_Buy_Sheet {

	static String[] attrName = new String[]{'Total Impressions', 'Total Cost','Provider Name', 'Product Line Name', 'Product Type Name', 'Product Name','Network Name','Discount', 'Cost Model', 'Price', 'CPM', 'Cost CPM'};
    
	// Return the list of Product COnfiguration records and with reletated details record for a specific Order.
	static Map<Id, list <cscfga__Product_Configuration__c> > ProdConfigListMap(list <Product_Order__c> productOrders){
    
		Map <Id, list <cscfga__Product_Configuration__c> > productConfigMap = new Map <Id, list <cscfga__Product_Configuration__c> >();
        list <ID> salesOrderIds = new list <ID>();
        list <ID> productConfigIds = new list <ID>();
            
		// Create List Sales Orders IDs & Product Configuration IDs related to the list of Product Orders
        for (Product_Order__c productOrder : productOrders){
           if (productOrder.Order__r.Sales_Order__c != null)
                salesOrderIds.add(productOrder.Order__r.Sales_Order__c);
           if (productOrder.Product_Configuration__c != null)
                productConfigIds.add(productOrder.Product_Configuration__c);
        }
        System.debug('*** ProdConfigListMap - Sales_Order__c :' + salesOrderIds);
        System.debug('*** ProdConfigListMap - Product_Configuration__c :' + productConfigIds);
        
        list<cscfga__Product_Configuration__c> allProdConfig =  [SELECT ID, Name, 
                                                                cscfga__Description__c,  
                                                                cscfga__Product_Basket__r.csmso__Sales_Order__r.Name, 
                                                                cscfga__Product_Basket__r.csmso__Sales_Order__c, 
                                                                cscfga__Configuration_Status__c,
                                                                    (SELECT  Name, 
                                                                         cscfga__Value__c, 
                                                                         cscfga__Attribute_Definition__r.Name, 
                                                                         cscfga__Product_Configuration__r.Name
                                                                    FROM cscfga__Attributes__r 
                                                                    WHERE cscfga__Attribute_Definition__r.Name IN : attrName
                                                                    ORDER BY cscfga__Attribute_Definition__r.Name DESC NULLS LAST )
                                                                FROM cscfga__Product_Configuration__c 
                                                                WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c in :salesOrderIds
                                                                AND   id in :productConfigIds         
                                                                AND  Line_Item_Platform__c = 'Xtend'];
        
        
        System.debug('*** Number of Product Configurations Retrieved relating to Product Order :' + allProdConfig.size());

        // Create a map of Product Order and the list of related Product Configurations
        for (Product_Order__c productOrder : productOrders){
            for(cscfga__Product_Configuration__c pc: allProdConfig)
            {	if ( productOrder.Product_Configuration__c == pc.id )
            	{
                    if ( !productConfigMap.containsKey(productOrder.Id) )                	
                        productConfigMap.put(productOrder.Id,new list<cscfga__Product_Configuration__c>{pc});
                    else
                        productConfigMap.get(productOrder.Id).add(pc);                                    
                }
            }            
        }
        System.debug('*** Number of Product Configurations Map Entries Created relating to Product Order :' + productConfigMap.size());
       
        return productConfigMap;
	}    

    /* Search for a sepcific attibute and it's value in the List of Product Configuration Attributes*/
    public static String findAttribute(cscfga__Product_Configuration__c prodConf, string attrName){

        system.debug('Searching for: ' + attrName);
        for (Integer i=0; i < prodConf.cscfga__Attributes__r.size(); i++) {
            if (prodConf.cscfga__Attributes__r[i].name == attrName) {
                system.debug('Found : ' + attrName + ' value ' + prodConf.cscfga__Attributes__r[i].cscfga__Value__c);
                return(prodConf.cscfga__Attributes__r[i].cscfga__Value__c);
            }
        }
        system.debug('Searching for: ' + attrName + ' failed');
        return ' ';
    }

    // SetProductFields sets specific fields in Product order by referencing the ProductConfigurations associated to the Product Order
    @InvocableMethod(label='Set Buysheet Fields' 
                     description='Sets the Buysheet specific fields in the Product Order record')    
    public static Void SetProductFields (List<ID> productOrderId) {

        List<Product_Order__c> productOrders = [SELECT ID, Order__r.Sales_Order__c, Product_Configuration__c, Buy_Sheet_Extracted__c FROM Product_Order__c WHERE Id in :productOrderId ];

        // Create a Map of a list of all Product COnfigurations that relate to indicidual Product Orders 
		Map <Id, list <cscfga__Product_Configuration__c> > productConfigMap = ProdConfigListMap(productOrders);
		        
        System.debug('*** Buy Sheet Field - Number of Product Orders changed is :' + productOrders.size());
        
        // For each product order in the list set the required attribute field
        for (Product_Order__c productOrder : productOrders){
 
            /* Set Buysheet Extracted Flag so that the PO record is extracted */
            System.debug('*** Set Buy Sheet Field - ' + productOrder.id);
            productOrder.Buy_Sheet_Extracted__c = false;
                
            if (productConfigMap.containsKey(productOrder.Id)){

                List<cscfga__Product_Configuration__c> ProdConfigList = productConfigMap.get(productOrder.Id);
                
                System.debug('*** Number of Product Configuration Records - ' + ProdConfigList.size());            
                
                if ( ProdConfigList.size() > 0 ){
                    productOrder.Product_Type_Name__c = findAttribute(ProdConfigList[0],'Product Type Name');            
                    productOrder.Product_Name__c = findAttribute(ProdConfigList[0],'Product Name');            
                    productOrder.Network_Name__c = findAttribute(ProdConfigList[0],'Network Name');            
                    productOrder.Discount__c = findAttribute(ProdConfigList[0],'Discount');            
                    productOrder.Cost_Model__c = findAttribute(ProdConfigList[0],'Cost Model');            
            
                    System.debug('*** Product Type Name - ' + findAttribute(ProdConfigList[0],'Product Type Name'));
                    System.debug('*** Product Name - ' + findAttribute(ProdConfigList[0],'Product Name'));
                    System.debug('*** Network Name - ' + findAttribute(ProdConfigList[0],'Network Name'));
                    System.debug('*** Discount - ' + findAttribute(ProdConfigList[0],'Discount'));
                    System.debug('*** Cost Model - ' + findAttribute(ProdConfigList[0],'Cost Model'));
                }
                System.debug('*** Updating Product Order - ' + productOrder);
            }	
       	}
     	If (productOrders.size() > 0) 
            Update(productOrders);
	}
}