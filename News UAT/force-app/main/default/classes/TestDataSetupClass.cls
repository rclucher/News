@isTest
public class TestDataSetupClass{

    /*
     * method to create a test account
     * IV 12/03: Added Billing_Statue__c due to Validation Rule 'Credit_Check_to_Allow_SO_Go_Post_Draft' failing on Account
     * IV 12/03: Added No_Parent_Account__c due to Validation Rule 'Enforce_Business_Parent_Account ' failing on Account
     */
     public static Account createAccount(){

        Account testAccount = new Account(name = 'testAccountForSalesOrderSupportTest',
                                          website = 'www.cloudsense.com',
                                          Billing_Status__c = 'Green',
                                          No_Parent_Account__c = true,
                                          Is_Digital__c = true,
                                          Adpoint_Id__c = '99999');
 //                                         Industry_Code__c = 'a1Y90000000I5r5');
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        testAccount.RecordTypeId = rtypes.Id;
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
        testAccount.Industry_Code__c = indCode.Id;
        return testAccount;
    }
    
    /*method to create a test contact*/
    public static Contact createContact(Account acc){
        Contact testContact = new Contact(FirstName='test', LastName ='Con', Email = 'test@email.com', AccountID = acc.Id);
        return testContact ;
    }

    /*method to create a test contact with AdPointId*/
    public static Contact createContactForIntegration(Account acc){
        Contact testContact = new Contact(FirstName='test', LastName ='Con', Email = 'test@email.com', AccountID = acc.Id, AdPoint_Id__c='testExternalId');
        return testContact ;
    }

    /*method to create a test user*/
    public static User createUser(){
        return new User(FirstName='test', LastName ='Con', Email = 'test@email.com');
    }

    /*method to create a ecommerce order request*/
    public static csb2c__Inbound_Ecommerce_Order_Request__c createOrderRequest(Account newAccount, cscfga__Product_Basket__c prodBasket) {
        return new csb2c__Inbound_Ecommerce_Order_Request__c(csb2c__Account__c=newAccount.Id, csb2c__Product_Basket__c=prodBasket.Id);
    }

    /*
     * method to create a test opportunity
     * IV 12/03: Added Amount due to 'Credit_Check_to_Allow_SO_Go_Post_Draft' Validation Rule failing on Opportunity
     * IV 12/03: Set Stage__c to 'Draft' due to Validation Rules such as 'OpLine_Products_Required_At_Review'
     * IV 12/03: Added Record Type 'Multi-channel' due to Validation Rules such as 'OpLine_Products_Required_At_Review'
     */
    public static Opportunity createOpportunity(Account acc, Contact con) {
        Id recordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Multi-Channel').getRecordTypeId();

        Opportunity testOpportunity = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id,Contact__c = con.Id, StageName = 'Draft', CloseDate = System.today(), Amount = 100.00, RecordTypeId = recordType);
        return testOpportunity ;
    }
    
    /*method to create a test Sales Order*/
    public static csmso__Sales_Order__c createSalesOrder(Account acc, Opportunity opp){   
        csmso__Sales_Order__c testSalesOrder = new csmso__Sales_Order__c();
        testSalesOrder.csmso__Advertiser__c = acc.Id;
        testSalesOrder.csmso__Status__c = 'Active';
        testSalesOrder.csmso__Opportunity__c = opp.Id;
        testSalesOrder.Campaign_Start_Date__c = Date.newInstance(1960, 2, 17);
        //testSalesOrder.Campaign_End_Date2__c = Date.newInstance(1960, 5, 17);
        return testSalesOrder;        
    }
    
    /*method to create a test ProductBasket*/
     public static cscfga__Product_Basket__c createProdBasket(csmso__Sales_Order__c so){
         cscfga__Product_Basket__c testProdBasket = new cscfga__Product_Basket__c ();
        testProdBasket.csmso__Sales_Order__c= so.Id;   
        return testProdBasket ;
     }

     /*method to create a test ProductBasket without sales order*/
    public static cscfga__Product_Basket__c createProdBasketNoSO(){
        cscfga__Product_Basket__c testProdBasket = new cscfga__Product_Basket__c ();
        //testProdBasket.csmso__Sales_Order__c= so.Id;   
        return testProdBasket ;
    }
     
      /*method to create a test Product Configuration*/
    public static cscfga__Product_Configuration__c createProdConfig(cscfga__Product_Basket__c  ProdBasket){
       cscfga__Product_Configuration__c  testProdConfig = new cscfga__Product_Configuration__c();
       testProdConfig.cscfga__Product_Basket__c = ProdBasket.id;
       return testProdConfig ;
    }
    
    /*method to create a test product category*/
    public static cscfga__Product_Category__c createProdCateg(){
        cscfga__Product_Category__c testProdCateg = new cscfga__Product_Category__c();        
        return testProdCateg ;        
    }
    
    /*method to create a test product Definition*/
    public static cscfga__Product_Definition__c createProDef(cscfga__Product_Category__c prodCateg){
        cscfga__Product_Definition__c testProDef = new cscfga__Product_Definition__c();
        testProDef.cscfga__Product_Category__c= prodCateg.Id;
        testProDef.cscfga__Description__c= 'testDescription';
        return testProDef ;        
    }
    
    /*method to create a test Attribute Definition*/
    public static cscfga__Attribute_Definition__c createAttrDef(cscfga__Product_Definition__c proDef ){
        cscfga__Attribute_Definition__c testAttrDef = new cscfga__Attribute_Definition__c();
        testAttrDef.cscfga__Product_Definition__c = proDef.Id;
        testAttrDef.Name= 'Available Amount';
        return testAttrDef ;        
    }
    /*method to create a test Attribute Definition with name*/
    public static cscfga__Attribute_Definition__c createAttrDefWithName(cscfga__Product_Definition__c proDef, String attName){
        cscfga__Attribute_Definition__c testAttrDef = new cscfga__Attribute_Definition__c();
        testAttrDef.cscfga__Product_Definition__c = proDef.Id;
        testAttrDef.Name= attName;
        return testAttrDef ;        
    }
    
     /*method to create a test Attribute*/
    public static cscfga__Attribute__c createAttr(cscfga__Product_Configuration__c prodConfig,csmso__Sales_Order__c so,cscfga__Attribute_Definition__c testAttrdef){
        cscfga__Attribute__c testAttr = new cscfga__Attribute__c();
        testAttr.cscfga__Product_Configuration__c= prodConfig.Id; 
        //testAttr.cscfga__Value__c = testFulfilmentItem.Id;
    //testAttr.Name = 'Fulfilment Item';
        //testAttr.Sales_Order_ID__c = so.Id;
        testAttr.cscfga__Attribute_Definition__c = testAttrDef.Id;
        return testAttr;
    }

    /*method to create a test Attribute withoutO SO*/
    public static cscfga__Attribute__c createAttrNoSO(cscfga__Product_Configuration__c prodConfig, cscfga__Attribute_Definition__c testAttrdef){
        cscfga__Attribute__c testAttr = new cscfga__Attribute__c();
        testAttr.cscfga__Product_Configuration__c= prodConfig.Id; 
        //testAttr.cscfga__Value__c = testFulfilmentItem.Id;
    //testAttr.Name = 'Fulfilment Item';
        //testAttr.Sales_Order_ID__c = so.Id;
        testAttr.cscfga__Attribute_Definition__c = testAttrDef.Id;
        return testAttr;
    }
    
    
    /*method to create a test Upload Approval*/
    public static csmso__Upload_Approval__c createUploadApproval(csmso__Sales_Order__c so){
        csmso__Upload_Approval__c testUploadApproval = new csmso__Upload_Approval__c (Name='testName');
        testUploadApproval.csmso__Sales_Order__c = so.Id;
        return testUploadApproval ;
    }
    
    /*method to create a test Click Approve contact role Setting*/
    public static CSCAP__Click_Approve_Setting__c createClkAppSet(){
        CSCAP__Click_Approve_Setting__c testClkAppSet = new CSCAP__Click_Approve_Setting__c();
        testClkAppSet.Name='IO Email Approval Setting';
        return testClkAppSet;
        
    }
    
    /*method to create a test Click Approve contact role Setting*/
    public static CSCAP__ClickApprove_Contact_Role__c createClkAppConRoleSet(csmso__Upload_Approval__c testUploadApproval){
        CSCAP__ClickApprove_Contact_Role__c testClkAppConRoleSet = new CSCAP__ClickApprove_Contact_Role__c();
        testClkAppConRoleSet.Upload_Approval__c = testUploadApproval.Id;
        return testClkAppConRoleSet;        
    }
    
    /*method to create a test Insertion_Order_Spec__c*/
    public static Insertion_Order_Spec__c createInsertOrderSpec(){
        Insertion_Order_Spec__c testInsertOrderSpec = new Insertion_Order_Spec__c();
        testInsertOrderSpec.Logo_URL__c = 'www.google.com';
        testInsertOrderSpec.Line_Item_Columns__c = 'Description,Date Range,Price';
        return testInsertOrderSpec;        
    }   
    
    /*method to create a test NewsXtendIORef__c*/
    public static NewsXtendIORef__c createNewsXtendIORef(){
        NewsXtendIORef__c testNewsXtendIORef = new NewsXtendIORef__c();
        testNewsXtendIORef.Name = 'test';
        testNewsXtendIORef.Campaign_Element__c = 'testCampaign';
        testNewsXtendIORef.Display_Order__c = 10;
        return testNewsXtendIORef;
    }        
    
    // still used for Provider, Product Type, Network product filters
    /*method to create a test NewsXtendIORef__c*/
    public static News_Xtend_Product_Ref__c createNewsXtendProductRef(){
        News_Xtend_Product_Ref__c testNewsXtendProductRef = new News_Xtend_Product_Ref__c();
        testNewsXtendProductRef.Name = 'testProRef';
        return testNewsXtendProductRef;
    }

    /*method to create a test Business Unit*/
    public static csmso__Business_Unit__c createBusinessUnit() {
        csmso__Business_Unit__c bu = new csmso__Business_Unit__c();
        bu.Name = 'Test Business Unit';
        bu.csmso__Sales_Ledger_Code__c = '0001';

        return bu;
    }
    
    /*method to create a test Product Node*/
    public static csmso__Product_Node__c createProductNode(String name, csmso__Business_Unit__c bu) {
    	csmso__Product_Node__c pn = new csmso__Product_Node__c();
    	pn.Name = name;
        pn.csmso__Business_Unit__c = bu.Id;
        pn.csmso__Media_Types__c   = 'Test Media Type';
    	
        return pn;
    }

    /*method to create a test Node Advert Assignment*/
    public static csmso__Node_Advert_Assignment__c createNodeAdvAssignment(String name, csmso__Product_Node__c pn) {
        csmso__Node_Advert_Assignment__c nAa = new csmso__Node_Advert_Assignment__c();
        nAa.Name = name;
        nAa.csmso__Title_Product_Node__c = pn.Id;

        return nAa;
    }
    
    /*method to create a test Order*/
    public static Order__c createOrder(Opportunity opp){
        Order__c testOrder = new Order__c();
        //testOrder.Name = 'testProRef';
        testOrder.Opportunity__c = opp.id;
        testOrder.Status__c = 'In Progress';
        //testOrder.Order_Status__c = 'Manual Approval';
        return testOrder;
    }
    
    /*method to create a test Payment*/
    public static Payment__c createPayment(Order__c order){
        Payment__c testPayment = new Payment__c();
        testPayment.Name = 'testPayment';
        testPayment.Order__c = order.id;
        return testPayment;
    }
    
    /*method to create a test Payment Schedule*/
    public static Payment_Schedule__c createPaymentSch(Payment__c payment){
        Payment_Schedule__c testPaymentSch = new Payment_Schedule__c();
        testPaymentSch.Name = 'testPaymentSch';
        testPaymentSch.Payment__c = payment.id;
        return testPaymentSch;
    }
    
    /*method to create a test Payment Schedule*/
    public static Payment_Line_Item__c createPaymentLineItem(Payment_Schedule__c paymentSch){
        Payment_Line_Item__c testPaymentLineItem = new Payment_Line_Item__c();
        testPaymentLineItem.Name = 'testPaymentlineItem';
        testPaymentLineItem.Payment_Schedule__c  = paymentSch.id;
        return testPaymentLineItem;
    }

    /*method to create a test Product Order*/
    public static Product_Order__c createProductOrder(Order__c order) {
        Product_Order__c po = new Product_Order__c();
        po.Order__c = order.Id;
   
        return po;
    }

    /*
     * create custom setting needed by ProductNodeTriggers and AttributeMediaTriggers triggers
     */
    public static csmso__SalesOrderAPI__c createSalesOrderAPI() {
        csmso__SalesOrderAPI__c soApi = new csmso__SalesOrderAPI__c();
        soApi.csmso__No_Triggers__c = false;

        return soApi;
    }

    /*
     * create Publication Product
     */
    public static Publication_Product__c createPublicationProduct(Product2 product) {
        Publication_Product__c pp = new Publication_Product__c(
                                                               Active__c = true,
                                                               Ad_Type__c = 'Display',
                                                               Publication__c = 'Publication Name',
                                                               Product__c = product.Id);
  
        return pp;
    }

    /*
     * create Product2
     */
    public static Product2 createProduct2(String name) {
        Product2 p = new Product2(Name = 'Test Product',
                                  Family = 'Digital', 
                                  Category__c = 'Digital',
                                  Region__c = name, // due to External_Id__c field in Product2 object Workflow Rule
                                  Booking_System__c = 'AdPoint',
                                  IsActive = True);
  
        return p;
    }

        /*
     * create Product2
     */
    public static Product2 createProduct2WithName(String name) {
        Product2 p = new Product2(Name = name,
                                  Family = 'Digital', 
                                  Category__c = 'Digital',
                                  Region__c = name, // due to External_Id__c field in Product2 object Workflow Rule
                                  Booking_System__c = 'AdPoint',
                                  IsActive = True);
  
        return p;
    }

    /*
     * create PriceBook
     */
    public static Pricebook2 createPriceBook() {
        Pricebook2 pb = new Pricebook2(Name = 'Test Price Book',
                                       Description = 'Standard Pricebook', 
                                       IsActive = true);
  
        return pb;
    }

    /*
     * create PricebookEntry
     */
    public static PriceBookEntry createPriceBookEntry(Product2 product2) {
        PriceBookEntry pe = new PriceBookEntry(Product2Id = product2.Id,
                                               PriceBook2Id = Test.getStandardPricebookId(),
                                               UnitPrice = 0,
                                               UseStandardPrice = false,
                                               IsActive = true);
  
        return pe;
    }
        
    @future
    public static void createWStest(){
        Account acc = createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '234';
        acc.Is_Digital__c = true;
        insert acc;
        
        Account payerAcc = createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = '7010';
        payerAcc.Is_Digital__c = true;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        csmso__Sales_Order__c so = createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;        
    }

    public static cspmb__Price_Item__c createPriceItem(String name, String segment, String state, String clientOutcome, String mediaType,
        String bundleName, String impact, String duration, Date startDate, Date endDate, Boolean isActive, Boolean insertRecord) {
        cspmb__Price_Item__c priceItem = new cspmb__Price_Item__c(Name = name, 
                                Segment__c = segment,
                                State__c = state,
                                Client_Outcome__c = clientOutcome,
                                Media_Type__c = mediaType,
                                Bundle_Name__c = bundleName,
                                Impact__c = impact,
                                Duration__c = duration,
                                cspmb__Effective_Start_Date__c = startDate, 
                                cspmb__Effective_End_Date__c = endDate,
                                cspmb__Is_Active__c = isActive);
        //insert if needed
        if (insertRecord) {
            insert priceItem;
        }
        return priceItem;
    }

    public static cspmb__Price_Item_Add_On_Price_Item_Association__c createPriceItemAddOnPriceItemAssociation(Id priceItemId, Id addonPriceItemId, Boolean insertRecord) {
        cspmb__Price_Item_Add_On_Price_Item_Association__c priceItemAddonPriceItemAssoc = new cspmb__Price_Item_Add_On_Price_Item_Association__c(
            cspmb__Price_Item__c = priceItemId,
            cspmb__Add_On_Price_Item__c = addonPriceItemId);
        //insert if needed
        if (insertRecord) {
            insert priceItemAddonPriceItemAssoc;
        }
        return priceItemAddonPriceItemAssoc;
    }

}