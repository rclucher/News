/**
 * Created by miaaugustinovic on 05/06/2018.
 */

global with sharing class TechnicalProductModelsEditController {

    public cscfga__Product_Configuration__c currentProductConfiguration {get;set;}
    public Map<Id, MLE_Tab_Product_Association__c> mleTabProductAssociationMap { get; set; }
    public String errorMessage{ get; set; }
    public Id basketId;
    public String tabNames { get; set; }
    public String definitionId {get; set;}
    public String rpKey {get; set;}
    public List<TechnicalProductTabInformation> productTabInformationList{ get; set; }
    public String gif { get; set; }
    public Map<String, Integer> mleTechnicalProductConfigurationsNumberMap { get; set; }
    public String packagePrefix = getPrefix();
    public String packagePrefixForClass = (packagePrefix == '') ? '' : (packagePrefix + '.');
    public String productTabInformationListJson { get; set; }
    public String url = '';

    public Decimal totalPrintDurationPrice { get; set; }
    public String printStatus { get; set; }
    public String bookingContact { get; set; }
    public Decimal totalPrintPriceGST { get; set; }
    public Decimal proposedDiscount { get; set; }
    public Decimal proposedPrintPriceAmount { get; set; }
    public Decimal targetDiscount { get; set; }
    public Decimal targetPrintPriceAmount { get; set; }
    public List<SelectOption> bookingContactList {get; set;}
    public String salesOrderId {get; set;}
    public csmso__Sales_Order__c mySo {get; set;}

    /**
     * Constructor.
     */
    public TechnicalProductModelsEditController() {

        salesOrderId = ApexPages.currentPage().getParameters().get('salesOrderId');
        cscfga__Product_Basket__c productBasket = [SELECT Id FROM cscfga__Product_Basket__c WHERE csmso__Sales_Order__c = :salesOrderId];
        String productBasketId = productBasket.Id;
        basketId = productBasketId;

        csmso__Sales_Order__c salesOrder = [SELECT FLAG_Lock_Product_Configuration__c from csmso__Sales_Order__c WHERE Id = :salesOrderId];
        String FLAGLockProductConfiguration = salesOrder.FLAG_Lock_Product_Configuration__c;

        fetchSOFields();

        if (productBasketId != null) {

            mleTechnicalProductConfigurationsNumberMap = new Map<String, Integer>();
            mleTabProductAssociationMap = getTechnicalProductDefinitionsMap();
            productTabInformationList = new List<TechnicalProductTabInformation>();

            for (Id mleTabId : mleTabProductAssociationMap.keySet()) {

                MLE_Tab_Product_Association__c mleTabProductAssociation = mleTabProductAssociationMap.get(mleTabId);
                String configurationId = '';
                Integer configurationNumber = 0;
                Map<String, String> parameterValues = new  Map<String, String>();
                String tabName = '';
                String cssFile = '';
                
                System.debug('ovo je flag: ---+ ' + FLAGLockProductConfiguration);
                
                if (FLAGLockProductConfiguration == 'Locked') {
                    cssFile = 'cssMleOverrideSOLocked';
                } else {
                    cssFile = 'cssMleOverride';
                }

                parameterValues.put('definitionName', EncodingUtil.urlDecode(mleTabProductAssociation.Associated_Product_Definition__r.Name, 'UTF-8'));
                if (mleTabProductAssociation.Screen_Flow__c != null) {
                    parameterValues.put('ScreenFlowId', mleTabProductAssociation.Screen_Flow__c);
                }

                //tabName = mleTabProductAssociation.Associated_Product_Definition__r.Name;
                tabName = mleTabProductAssociation.Name;
                MleUrlBuilder mleBuilder = new MleUrlBuilder('csmle__', basketId, mleTabId);
                url = mleBuilder.setBatchSize(50).setSidebar(false).setShowHeader(false).setCssOverride(cssFile).setScriptPlugin('mleScriptPlugin').setConfigFilter(packagePrefixForClass + 'TechnicalMleFilter', parameterValues).build();

                Integer tabOrder = mleTabProductAssociation.Tab_Order__c != null ? (Integer) mleTabProductAssociation.Tab_Order__c : 999;

                TechnicalProductTabInformation tabInfo = new TechnicalProductTabInformation(tabName, mleTabId, configurationId, url, tabOrder, mleTabProductAssociation.Load_On_Select__c, configurationNumber);
               
                productTabInformationList.add(tabInfo);
            }

            productTabInformationList.sort();
            if (!productTabInformationList.isEmpty()) {
                productTabInformationList[0].setActive();
            }
            productTabInformationListJson = JSON.serialize(productTabInformationList);

        } else {
            logger('Current product configuration is NULL', ApexPages.severity.ERROR);
        }
    }

    public void fetchSOFields() {
        mySo =
        [SELECT Id, Name, Print_Status__c, Total_Print_Duration_Price__c, csmso__Booking_Contact__c, csmso__Booking_Contact__r.Name, Total_Print_Price_GST_inclusive__c, Proposed_Print_Discount__c,
                Proposed_Print_Price__c, Target_Discount__c, Target_Print_Price__c, Basket_Products__c
        FROM csmso__Sales_Order__c
        WHERE Id = :salesOrderId];

        totalPrintDurationPrice = mySo.Total_Print_Duration_Price__c;
        printStatus = mySo.Print_Status__c;
        bookingContact = mySo.csmso__Booking_Contact__r.Name;
        totalPrintPriceGST = mySo.Total_Print_Price_GST_inclusive__c;
        proposedDiscount = mySo.Proposed_Print_Discount__c;
        proposedPrintPriceAmount = mySo.Proposed_Print_Price__c;
        targetDiscount = mySo.Target_Discount__c;
        targetPrintPriceAmount = mySo.Target_Print_Price__c;
        
    }

    public PageReference refreshPrintFields() {

        fetchSOFields();



        return null;
    }

    public Boolean getHasPrintDisplay() {

        if (mySo.Basket_Products__c== null) return false;

        return mySo.Basket_Products__c.contains('Print Display');

    }



    public Map<Id,MLE_Tab_Product_Association__c> getTechnicalProductDefinitionsMap() {

        Map<Id, MLE_Tab_Product_Association__c> technicalProdDefMap = new Map<Id, MLE_Tab_Product_Association__c> ();
        Set<String> mleTechnicalProdDef = new Set<String>();
        List<MLE_Tab_Product_Association__c> listOfTechnicalCommercialJunctions = [
                select id, Name, Associated_Product_Definition__c, Associated_Product_Definition__r.name, Load_on_Select__c, Screen_Flow__c, Screen_Flow__r.name, Tab_Order__c
                from MLE_Tab_Product_Association__c
        ];

        for (MLE_Tab_Product_Association__c assoc : listOfTechnicalCommercialJunctions) {
            if (assoc.Associated_Product_Definition__c != null) {
                technicalProdDefMap.put(assoc.Associated_Product_Definition__c, assoc);
            }

            mleTechnicalProdDef.add(assoc.Associated_Product_Definition__c);
        }

        return technicalProdDefMap;
    }


    public void logger(String message) {
        logger(message, null);
    }

    public void logger(String message, ApexPages.severity severity) {
        if (severity == null) {
            severity = ApexPages.severity.ERROR;
        }
        ApexPages.addMessage(new ApexPages.message(severity,message));
    }

    public static String getPrefix() {
        Matcher spmMatcher =
                Pattern.compile('(.+)__MLE_Tab_Product_Association__c').matcher(MLE_Tab_Product_Association__c.sObjectType.getDescribe().getName());

        String packageNamespace = spmMatcher.matches() ? spmMatcher.group(1) : '';
        String packagePrefix = (packageNamespace == '') ? '' : packageNamespace;

        return packagePrefix;
    }
}