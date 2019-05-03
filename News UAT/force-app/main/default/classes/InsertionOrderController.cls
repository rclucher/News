/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class is a controller for the Visual Force Insertion Order Page
 * It searches throught the Line Items looking for each type and impression counter
 * Could be refactored to better manage changes in the matching InsertionOrder Visual Force page
 ---------------------------------------------------------*/

public with sharing class InsertionOrderController {

    public static final String SEASONAL_XTEND = 'Seasonal - News Xtend' ;
    public static final String SEASONAL_PRINT = 'Seasonal - Print Led'  ;
    public static final String EVERGREEN      = 'Evergreen';

    public Id salesOrderId {get;set;}
    public String platformSet {get;set;}
    public String[] attributeNames{get;set;}
    public String[] printAttributeNames{get;set;}
    public String[] digitalAttributeNames{get;set;}
    public String logoURL{get;set;}
    public List<NewsXtendIORef__c> IORefDescriptions {get;set;}
    public List<List<String>> IORefFormatedDescriptions {get;set;}
    public List<List<String>> printIORefFormatedDescriptions {get;set;}
    public List<List<String>> digitalIORefFormatedDescriptions {get;set;}
    public List<List<String>> IORefFormatedDescriptionsLimit {get;set;}
    //public Boolean containsBundles {get;set;}
    public DataErrorWrapper errorWrapper {get;set;}
    public csmso__Sales_Order__c workingSo {get;set;}

    private final String PRINT_PREFIX = 'Print Advertising';

    // NewsXtend enhancements

    // The preformated text to display for "Display" products on the Investment Summary
    public String ISDisplayStringText{get;set;}
    public String ISSearchStringText{get;set;}
    public String ISSocialStringText{get;set;}
    public String ISWebsiteStringText{get;set;}
    public String ISCampaignStringText{get;set;}
    public String ISLandingStringText{get;set;}
    public String ISEmailStringText{get;set;}
    public String strConvertedDate{get;set;}

    public Integer ISTotalDisplay{get;set;}
    public Integer ISTotalSocial{get;set;}

    public Decimal TotalValue {get;set;}
    public Decimal TotalGST {get;set;}
    public Decimal TotalValueGSTInclusive {get;set;}

    public Map<String,String> urlMap {get; set;}
    public Map<String,String> urlMapExLimit {get; set;}
    public Map<String,String> campMgmtMap {get; set;}
    
    public List<String> campaignStarts {get;set;}

	//added by DD for NX-304
	map<Integer,Decimal> mapIORefDescriptionsPrice = new map<Integer,Decimal>();
	//********************************

    //public DateTime currenttime {get; set;}
    public List<csmso__Upload_Approval__c> uaRec = new List<csmso__Upload_Approval__c>();

    public Boolean DisplayISSummaryFlag {
        get{
            If (ISTotalDisplay >0) {
                return(true);
            }
            else {
                return(false);
            }
        }
        set;}

    public Boolean SocialISSummaryFlag {
        get{
            If (ISTotalSocial >0) {
                return(true);
            }
            else {
                return(false);
            }
        }
        set;}

    public Boolean SearchISSummaryFlag {
        get{
            return(String.isNotEmpty(ISSearchStringText));
        }
        set;}

    public Boolean CampaignISSummaryFlag {get;set;}


    public Boolean LandingISSummaryFlag {
        get{
            return(String.isNotEmpty(ISLandingStringText));
        }
        set;}

    public Boolean EmailISSummaryFlag {
        get{
            return(String.isNotEmpty(ISEmailStringText));
        }
        set;}



    public InsertionOrderController (ApexPages.standardController controller) {
        //attributeNames = getColumnHeaders();//new String[] {'Description', 'Price'};
        urlMap = new  Map<String,String>();
        urlMapExLimit = new  Map<String,String>();
        campMgmtMap = new Map<String,String>();
        errorWrapper = new DataErrorWrapper();
        campaignStarts = new List<String>();

        applyInsertionOrderConfigurables();
        salesOrderId = controller.getRecord().Id;

        workingSo  = [SELECT Id, Platform_Set__c,Campaign_Products_Type__c  FROM csmso__Sales_Order__c WHERE Id = :salesOrderID LIMIT 1];
        platformSet = workingSo.Platform_Set__c;

        // need for awareness of Bundle in basket
        // used to decide how the Insertion attribute list will be populated, see getInsertions()

        /* not used anymore
        containsBundles = [SELECT Id FROM cscfga__Product_Configuration__c
        WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c =: salesOrderId
        AND (Bundle_Name__c != '' AND Bundle_Name__c != '/')].size() > 0 ? True : False;
		*/


        uaRec = [Select id, name, LastModifiedDate from csmso__Upload_Approval__c where csmso__Sales_Order__c =: salesOrderId];
        if(uaRec.size()>0)
        {
            DateTime currenttime =[Select LastModifiedDate from csmso__Upload_Approval__c where csmso__Sales_Order__c =: salesOrderId ORDER BY LastModifiedDate DESC LIMIT 1].LastModifiedDate;
            system.debug('----currenttime--'+currenttime );
            strConvertedDate = currenttime.format('dd/MM/YYYY HH:mm aaa','Australia/Sydney');
            system.debug('----Australia Time--'+strConvertedDate);
        }
        else
        {
            DateTime currenttime = System.now();
            system.debug('----currenttime--'+currenttime );
            strConvertedDate = currenttime.format('dd/MM/YYYY HH:mm aaa','Australia/Sydney');
            system.debug('----Australia Time--'+strConvertedDate);
        }
        /*DateTime currenttime = [Select LastModifiedDate from csmso__Sales_Order__c where id =: salesOrderId].LastModifiedDate;
        //DateTime uatime = [Select LastModifiedDate from csmso__Upload_Approval__c where csmso__Sales_Order__c =: salesOrderId].LastModifiedDate;

        system.debug('----currenttime--'+currenttime );
        strConvertedDate = currenttime.format('dd/MM/YYYY HH:mm aaa','Australia/Sydney');
        system.debug('----Australia Time--'+strConvertedDate);*/
        IORefDescriptions = findInsertionOrderElements();
    }

    public PageReference checkCampaignElements() {
        try {
            return getCampaignElements();

        } catch (InsertionOrderControllerException ioe) {

            errorWrapper.errorsFound = true;
            errorWrapper.errorMessage = ioe.getMessage();
            return null;
        }
    }

    // Search for the NewsXtend IO Types
    public PageReference getCampaignElements() {



        List<List<String>> result = new List<List<String>>();
        List<List<String>> printResult = new List<List<String>>();
        List<List<String>> digitalResult = new List<List<String>>();

        // Get all the Insertions
        try {

            if ( platformSet.contains('Xtend') )   result = getInsertions(attributeNames);
            if ( platformSet.contains('Print') )   printResult = getInsertions(printAttributeNames);
            if ( platformSet.contains('Digital') ) digitalResult = getInsertions(digitalAttributeNames);

        } catch ( InsertionOrderControllerException ioe) {
            throw new InsertionOrderControllerException(ioe.getMessage());
        }


        // Total social number of ads seen so far
        ISTotalSocial = 0;

        // Locate the correct position to be searching for
        String attributeName;
        Integer positionOfIOName;
        Integer positionOfTotalNumber;
        Integer positionOfISName;
        Integer positionOfHTMLIS;
		Integer positionOfPrice;

        positionofIOName=-1;
        positionofTotalNumber=-1;
        positionOfISName=-1;
        positionOfHTMLIS=-1;
		positionOfPrice=-1;

        for (Integer x=0; x < attributeNames.size(); x++) {
            attributeName = attributeNames[x];
            System.debug('Attribute Name:' + x + ':Result:' + attributeName +':');
            if (attributeName.equals('Product Groups For IO')) {
                positionOfIOName = x;
                System.debug('Found Product Groups for IO @ ' + x);
            }
            else if (attributeName.equals('Total Number')) {
                positionOfTotalNumber = x;
                System.debug('Found Total Number for IO @ ' + x);
            }
            else if (attributeName.equals('Product Groups For Investment Summary')) {
                positionOfISName = x;
                System.debug('Found Product Groups For Investment Summary @ ' + x);
            }
            else if (attributeName.equals('HTML IS')) {
                positionOfHTMLIS = x;
                System.debug('Found HTML IS @ ' + x);
            }
			else if (attributeName.equals('Price')) {
                positionOfPrice = x;
                System.debug('Price @ ' + x);
            }
            else {
                System.debug('AttributeName ' + attributeName + ' unexpected, potential configuration error');
            }
        }

        // Check we have found all the items we expected
        if ((positionOfIOName==-1) || (positionofTotalNumber==-1) || (positionofISName==-1) || (positionofHTMLIS==-1) || (positionOfPrice==-1)) {
            throw new InsertionOrderControllerException ('Attribute Name(s) in Insertion Order/Investment Summary specification missing, configuration error');
        }

        System.debug('Product Groups for IO @ ' + positionOfIOName + ' and Investment Summary @ ' + positionofISName);
        // Iterate over the result searching for each of the Media Type
        List<String> LineItem;
        String LineItemColumn;
        String IOName;
        String ISName;
        String HTMLISText;
        String TotalNumber;
		String TotalPrice;
        Integer localTotalNumber;
		Decimal localTotalPrice;

        // List of all the Investment Summary strings we see for the four types supported
        // This correlates to each Product Line record from the Xtend Product Ref catalouge
        List<String> DisplayStrings = new List<String>();
        List<String> SocialStrings = new List<String>();
    List<String> WebsiteStrings = new List<String>();
        List<String> CampaignStrings = new List<String>();
        List<String> SearchStrings = new List<String>();
        List<String> LandingStrings = new List<String>();
        List<String> EmailStrings = new List<String>();

        System.debug('Number of Insertion Line Items ' + result.size());

        for (Integer i=0; i < result.size(); i++) {
            LineItem = result[i];
            System.debug('Insertion Line Item ' + i + ' Result ' + LineItem);


            // Print product result skip > START
            // Product group for IO is 3rd attribute in IO spec record
            String prodGroupForIO = LineItem[2];

            if (String.isEmpty(prodGroupForIO)) {
                System.debug(' >> Skipping non Xtend products');
                continue;
            }
            // Print product current skip > END

            for (Integer j=0; j < LineItem.size(); j++) {
                LineItemColumn = LineItem[j];
                system.debug('Insertion Line Item Column ' + j + ' Result ' + LineItemColumn);
            }
            // We should have found an IOName and TotalNumber
            IOName = LineItem[positionofIOName];
            totalNumber = LineItem[positionofTotalNumber];
			TotalPrice = LineItem[positionOfPrice];
			System.debug('***TotalPrice=' + TotalPrice);
            ISName = LineItem[positionofISName];
            HTMLISText = LineItem[positionofHTMLIS];
            system.debug('Found IOName ' + IOName + ' and ISName ' + ISName + ' and associated TotalNumber ' + TotalNumber);
            system.debug('Found HTMLISText <start>' + HTMLISText + '<ends>');
            localTotalNumber = calculateCount(IOName,TotalNumber);
			localTotalPrice = calculatePrice(IOName,TotalPrice);

            system.debug('Search ISName <' + ISName +'> strings for <starts>' + HTMLISText + '<ends> to see if unique');
            If (ISName == 'Display') {
                if (!lookforDuplicate (HTMLISText, DisplayStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Display');
                    DisplayStrings.add(HTMLISText);
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
            else if (ISName == 'Search') {
                if (!lookforDuplicate (HTMLISText, SearchStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Search');
                    SearchStrings.add(HTMLISText);
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
            else If (ISName == 'Social') {
                if (!lookforDuplicate (HTMLISText, SocialStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Social');
                    SocialStrings.add(HTMLISText);
                    // Theres no automatic count of Social from the Product Model so sum it up here
                    ISTotalSocial += localTotalNumber;
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
            else If (ISName == 'Campaign Management') {
                if (!lookforDuplicate (HTMLISText, CampaignStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Campaing Management');
                    CampaignStrings.add(HTMLISText);
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
            else If (ISName == 'Landing Page') {
                if (!lookforDuplicate (HTMLISText, LandingStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Landing Page');
                    LandingStrings.add(HTMLISText);
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
            else If (ISName == 'Email') {
                if (!lookforDuplicate (HTMLISText, EmailStrings)) {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Email Page');
                    EmailStrings.add(HTMLISText);
                }
                else {
                    system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
                }
            }
      else If (ISName == 'Website') {
          if (!lookforDuplicate (HTMLISText, WebsiteStrings)) {
               system.debug('HTMLISText <start>' + HTMLISText + '<ends> is unique. Adding to Email Page');
               WebsiteStrings.add(HTMLISText);
          }
          else {
            system.debug('HTMLISText <start>' + HTMLISText + '<ends> is duplicate, ignoring');
          }
      }
            else
            {
                system.debug('ISName' + ISName + 'currently unmanaged, configuration error');
                throw new InsertionOrderControllerException ('ISName :' + ISName + ' currently unmanaged, configuration error');
            }
        }

        // Some fields on the SO look like products on the Insertion Order but are True/False flags on the SO itself
        // Find them and make them look like products to the formating engine below
        findServiceOrderAddOns(IORefDescriptions);

        // Format up the display strings for the Insertion Order
        system.debug('Completed search and count. Format strings for Insertion Order');

        for (Integer i=0; i < IORefDescriptions.size(); i++) {
            System.debug('Insertion Order Section (' + i + ') ' + IORefDescriptions[i].name + ' Quantity = ' + IORefDescriptions[i].Quantity__c + ' DispOrder = ' + IORefDescriptions[i].Display_Order__c);
        }

        // Ensure the sections of the Insertion Order are printed in desired order
        set<Integer> DisplayOrderSet = new set<Integer>();
        List<Integer> DisplayOrder = new List<Integer>();
        set<Integer> DisplayOrderMax = new set<Integer>();
        List<Integer> DisplayOrderMaxLimit = new List<Integer>();

        Integer smallestSeen;
        Integer doLimit;
        Integer smallestSection;
        Integer limitExSection;

        for (Integer i=0; i < IORefDescriptions.size(); i++) {
            if (result.size()==0) break; //skip if no Xtend Products
            smallestSeen = 1000;
            doLimit = 1000;
            smallestSection=-1;
            limitExSection=-1;
            for (Integer j=0; j < IORefDescriptions.size(); j++) {
                System.debug('Sorting @ Section (' + j + ') Quantity = ' + IORefDescriptions[j].Quantity__c + ' Order = ' + IORefDescriptions[j].Display_Order__c);
                If ((IORefDescriptions[j].Quantity__c>0) && (IORefDescriptions[j].Display_Order__c<smallestSeen)) {
                    System.debug('Found @ (' + j + ') smallestSeen (' + smallestSeen + ') for section (' + smallestSection + ')');
                    smallestSeen = Integer.valueOf(IORefDescriptions[j].Display_Order__c);
                    smallestSection = j;
                }
                else if((IORefDescriptions[j].Quantity__c>0) && (IORefDescriptions[j].Display_Order__c>smallestSeen)){
                    System.debug('==>Sorting @ Section (' + j + ')  Name = ' + IORefDescriptions[i].name + 'Quantity = ' + IORefDescriptions[j].Quantity__c + ' Order = ' + IORefDescriptions[j].Display_Order__c);
                    System.debug('==>Found @ (' + j + ') limit (' + doLimit + ') for section (' + smallestSection + ')');
                    doLimit = Integer.valueOf(IORefDescriptions[j].Display_Order__c);
                    system.debug('limit ==>'+doLimit);
                    if(doLimit >1000){
                        limitExSection = j;
                        DisplayOrderMax.add(limitExSection);
                        system.debug('limitExSection ==>'+limitExSection);
                    }
                }
            }
            system.debug('Completed pass (' + i + ') Smallest Seen (' + smallestSeen + ') for section ' + smallestSection);
            if (smallestSection == -1) {
                system.debug('Display Order sort complete with ' + displayOrder.size() + ' sections found to include');
                break;
            }
            System.debug('Display Order Smallest Seen (' + smallestSeen + ') for section ' + smallestSection + ' named ' + IORefDescriptions[smallestSection].name);
            IORefDescriptions[smallestSection].Display_Order__c=1000;
            DisplayOrderSet.add(smallestSection);
            system.debug('displayOrder==>'+DisplayOrderSet);
            //IORefDescriptions[limitExSection].Display_Order__c=1000;
            if (limitExSection != -1) {
                system.debug('Display Order sort complete with ' + displayOrder.size() + ' sections found to include');
                // DisplayOrderMax.add(limitExSection);
                system.debug('DisplayOrderMax==>'+DisplayOrderMax);
            }

        }
        //DisplayOrderMax.add(limitExSection);
        system.debug('FORDisplayOrderMax==>'+DisplayOrderMax);
        DisplayOrder.addAll(DisplayOrderSet);
        system.debug('DisplayOrder==>'+DisplayOrder);
        system.debug('DisplayOrderMaxLimit==>'+DisplayOrderMaxLimit);
        IORefFormatedDescriptions = new List<List<String>>();
        printIORefFormatedDescriptions = new List<List<String>>();
        digitalIORefFormatedDescriptions = new List<List<String>>();

        system.debug('Completed sort of order of Insertion Order sections. Found ' + displayOrder.size() +'. Format strings for Insertion Order');
        system.debug('Completed sort of order of Insertion Order sections. Found ' + DisplayOrderMax.size() +' exceeding Display Order. Format strings for Insertion Order');
        // Format the sections
        for (Integer i=0; i < displayOrder.size(); i++) {
            Integer displayNext = displayOrder[i];

            System.debug('Formating Insertion Order Section (' + i + ') ' + IORefDescriptions[displayNext].name);

            // Convert the Quantity (Impressions etc) assoicated with this IOSection to a string and replace '<0>' sequence with it
            String formatedDetails = IORefDescriptions[displayNext].Details__c.replace('<0>', string.valueof(IORefDescriptions[displayNext].Quantity__c));

			//added by DD NX-304
			System.debug('***formatedDetails before=' + formatedDetails);
			formatedDetails = formatedDetails.replace('<1>', string.valueof(mapIORefDescriptionsPrice.get(displayNext)));
			System.debug('***formatedDetails after=' + formatedDetails);


            List<String> columns = new List<String>();
            columns.add(urlMap.put(IORefDescriptions[displayNext].Campaign_Element__c, IORefDescriptions[displayNext].URL__c != null ? IORefDescriptions[displayNext].URL__c : 'No Image'));
            columns.add(IORefDescriptions[displayNext].Campaign_Element__c);
            columns.add(formatedDetails);
            //urlMap.put(IORefDescriptions[displayNext].Campaign_Element__c, IORefDescriptions[displayNext].URL__c != null ? IORefDescriptions[displayNext].URL__c : 'No Image');
            //columns.add(IORefDescriptions[displayNext].Fulfilment_Details__c);

            system.debug('This Insertion Order section contains ' + columns.size() + ' elements');
            for (Integer j=0; j < columns.size(); j++) {
                system.debug('Column ' + j + ' : ' + columns[j]);
            }
            IORefFormatedDescriptions.add(columns);
        }

        // Print products section
        Map<String,List<PrintWrapper>> typeStatePublicationMap = new Map<String, List<PrintWrapper>>();
        for (List<String> attributes : printResult) {
            /*  attributes indexes
                0    ,1   ,2            ,3                    ,4      ,5
                Type,State,Publication,Impressions Quantity,Ad Size,Selected Dates
             */

            if (String.isEmpty(attributes[0])) {
                System.debug(' >> Skipping non Print products');
                continue;
            }

            String typeState = attributes[0] + ' / '+  attributes[1];

            // if attribute cycle exists at location 6, take it's value, otherwise take '0'
            PrintWrapper pwObject = new PrintWrapper(attributes[2], Integer.valueOf(attributes[3]) ,attributes[4],attributes[5], attributes.size() > 6 ? attributes[6] : '0');
            
            campaignStarts.add(pwObject.Publication + ' estimated campaign start date: ' + pwObject.EstimatedStartDate);

            if ( typeStatePublicationMap.keySet().contains(typeState) ) {
                if ( pwObject.ImpressionsQuantity > typeStatePublicationMap.get(typeState)[0].ImpressionsQuantity ) {
                    typeStatePublicationMap.get(typeState).add(0,pwObject); //set primary publication according to total Quantity
                } else {
                    typeStatePublicationMap.get(typeState).add(pwObject);

                }
            } else {
                typeStatePublicationMap.put(typeState, new List<PrintWrapper>{ pwObject });
            }
        }

        if ( typeStatePublicationMap.keySet().size() > 0 ) {

            for (String typeState: typeStatePublicationMap.keySet()) {

                List<PrintWrapper> typeStateProductList = typeStatePublicationMap.get(typeState);

                for (Integer i=0; i< typeStateProductList.size();i++ ) {
                    PrintWrapper currentPrint = typeStateProductList[i];
                    currentPrint.setPublicationLevel(i);

                    List<String> print_columns =  new  List<String>();

                    String oneBreak =  '<br/>';
//                String ProductInfo = typeState + oneBreak;
//                ProductInfo += PRINT_PREFIX + oneBreak + '   - ';
//                ProductInfo += currentPrint.ProductLevel + oneBreak;
                    String ProductInfo = currentPrint.Publication.replace('<br/>','');
                    ProductInfo += '<br/> Position: The positioning and placement of<br/>an Advertisement is at the<br/>discretion of Publisher.';
                    urlMap.put(ProductInfo,'No Image');
                    print_columns.add(null); // can remain if no Image required
                    print_columns.add(ProductInfo);

//                String ProductDesc = currentPrint.ProductDescription + oneBreak + oneBreak;
                    String ProductDesc = currentPrint.AdSize;
                    //TODO:use impression Quantity when child bundle definitions are finalised
                    //ProductDesc += String.valueOf(currentPrint.ImpressionsQuantity) + ' Impression(s)';
                    //ProductDesc += String.valueOf(currentPrint.SelectedDates.split(',').size()) + ' Insertion(s) per week';
                    ProductDesc += ', total ' + String.valueOf(currentPrint.ImpressionsQuantity) + ' insertions';
                    if(currentPrint.Cycle == '0') {
                        ProductDesc += ', 1 per week';
                    } else {
                        ProductDesc +=  getIsEvergreen() ? ' (monthly) ' : ', '  + currentPrint.Cycle;
                    }

                    print_columns.add(ProductDesc);


                    printIORefFormatedDescriptions.add(print_columns);
                }
            }
        }

        // Digital product sections
        Map<String,DigitalWrapper> digitalWrapperMap = new Map<String, DigitalWrapper>();

        for (List<String> attributes : digitalResult) {
              /*  attributes indexes
               * 0                   , 1                 , 2    , 3
               * Digital Product Name,Insertion Quantity,Price, Duration Months
               * */
            String  digitalProduct = attributes[0];
            Integer digitalQuantity = Integer.valueOf(attributes[1]);
            Decimal digitalMonthDuration = Decimal.valueOf(attributes[3]);

            if ( !digitalWrapperMap.containsKey(digitalProduct)) {
                digitalWrapperMap.put(digitalProduct, new digitalWrapper(digitalProduct, digitalQuantity, digitalMonthDuration ));
            } else {
                //need to add each digital Month Duration since we could have two seasonal print leds with different Month Duration
                digitalWrapperMap.get(digitalProduct).addItemsQuantity(digitalQuantity, digitalMonthDuration);
            }


        }


        List<String> digital_columns =  new List<String>();
        for ( DigitalWrapper digitalItem : digitalWrapperMap.values()) {


            digital_columns = new List<String>();

            String digitalProduct = digitalItem.ProductName;
            urlMap.put(digitalProduct,'No Image');
            digital_columns.add(null);
            digital_columns.add(digitalProduct);

            String digitalDescription    = 'Number of digital Items in Order: ' + digitalItem.Items;
            digitalDescription          += '<br/> Quantity of ' + digitalItem.TotalQuantity + ' total campaign';
            digitalDescription          += '<br/> (' + digitalItem.Quantity + ' per month)';

            digital_columns.add(digitalDescription);

            digitalIORefFormatedDescriptions.add(digital_columns);
        }


        System.debug('URLMap-->' + urlMap);
        System.debug('-->'+IORefFormatedDescriptions);
        System.debug('PRINT DeSC : '+ printIORefFormatedDescriptions);
        System.debug('DIGITAL DeSC : '+ digitalIORefFormatedDescriptions);

        DisplayOrderMaxLimit.addAll(DisplayOrderMax);
        system.debug('DisplayOrderMaxLimit==>'+DisplayOrderMaxLimit);
        IORefFormatedDescriptionsLimit  = new List<List<String>>();
        if(DisplayOrderMaxLimit.size()>0){
            for(Integer k=0; k < DisplayOrderMaxLimit.size(); k++){
                Integer displaylim = DisplayOrderMaxLimit[k];
                System.debug('sizeofDisplayOrderMaxLimit-->'+ DisplayOrderMaxLimit.size());
                System.debug('Formating Insertion Order separate Section (' + k + ') ' + IORefDescriptions[displaylim].name);
                // Convert the Quantity (Impressions etc) assoicated with this IOSection to a string and replace '<0>' sequence with it
                String formatedDetailsExList = IORefDescriptions[displaylim].Details__c.replace('<0>', string.valueof(IORefDescriptions[displaylim].Quantity__c));

				//added by DD NX-304
				System.debug('***formatedDetailsExList before=' + formatedDetailsExList);
				formatedDetailsExList = formatedDetailsExList.replace('<1>', string.valueof(mapIORefDescriptionsPrice.get(displaylim)));
				System.debug('***formatedDetailsExList after=' + formatedDetailsExList);

                List<String> columns = new List<String>();
                //columns.add(urlMapExLimit.put(IORefDescriptions[displaylim].Campaign_Element__c, IORefDescriptions[displaylim].URL__c != null ? IORefDescriptions[displaylim].URL__c : 'No Image'));
                columns.add(IORefDescriptions[displaylim].Campaign_Element__c);
                columns.add(formatedDetailsExList);
                //urlMapExLimit.put(IORefDescriptions[displaylim].Campaign_Element__c, IORefDescriptions[displaylim].URL__c != null ? IORefDescriptions[displaylim].URL__c : 'No Image');

                system.debug('This Insertion Order section contains disp order>1000 ele ' + columns.size() + ' elements');
                for (Integer l=0; l < columns.size(); l++) {
                    system.debug('Column for table2 ' + l + ' : ' + columns[l]);
                }
                IORefFormatedDescriptionsLimit.add(columns);
            }
            String cm = '';
            Integer i = 0;
            for (List<String> columns : IORefFormatedDescriptionsLimit) {
                System.debug('Columns : ' + columns);
                Integer j = 0;
                System.debug('1.i=' + i);
                System.debug('1.j=' + j);
                System.debug('1.cm : ' + cm);
                for (String s : columns) {
                    System.debug('2.i=' + i);
                    System.debug('2.j=' + j);
                    System.debug('2.S : ' + s);
                    System.debug('2.cm : ' + cm);
                    if (i == 0 && j == 1) {
                        cm += ' -<br/>';
                    }
                    else if (i == 0) {
                        //cm += ' <br/>';
                    }
                    else if (i > 0 && j == 0) {
                        cm += '<br/><br/>';
                    }
                    else if (i > 0 && j > 0) {
                        cm += ' -<br/>';
                    }
                    cm += s;
                    j++;
                }
                i++;
            }
            System.debug('cm -->' + cm );
            campMgmtMap.put('                                                      Campaign Management',cm);
        }
        System.debug('campMgmtMap-->' + campMgmtMap);
        System.debug('urlMapExLimit-->' + urlMapExLimit);
        System.debug('IORefFormatedDescriptionsLimit-->'+IORefFormatedDescriptionsLimit);

        system.debug('Completed search and count. Format strings for IS');
        system.debug('Format Display String with ' + DisplayStrings.size() + ' sub sections');
        system.debug('Format Social String with ' + SocialStrings.size() + ' sub sections');
    system.debug('Format Social String with ' + WebsiteStrings.size() + ' sub sections');
        system.debug('Format Search String with ' + SearchStrings.size() + ' sub sections');
        system.debug('Format Campaign String with ' + CampaignStrings.size() + ' sub sections');
        system.debug('Format Landing String with ' + LandingStrings.size() + ' sub sections');
        system.debug('Format Email String with ' + EmailStrings.size() + ' sub sections');

        // Format up the display strings for the Insertion Summary
        ISDisplayStringText = '';
        ISSearchStringText = '';
    ISWebsiteStringText = '';
        ISSocialStringText = '';
        ISCampaignStringText = '';
        ISLandingStringText = '';
        ISEmailStringText = '';

        system.debug('HTML Text for Display <start>' + ISDisplayStringText + '<ends>');
        for (Integer j=0; j < DisplayStrings.size(); j++) {
            ISDisplayStringText += DisplayStrings[j];
        }
        system.debug('HTML Text for Social <start>' + ISSocialStringText + '<ends>');
        for (Integer j=0; j < SocialStrings.size(); j++) {
            ISSocialStringText += SocialStrings[j];
        }
    system.debug('HTML Text for Social <start>' + ISWebsiteStringText + '<ends>');
    for (Integer j=0; j < WebsiteStrings.size(); j++) {
        ISWebsiteStringText += WebsiteStrings[j];
    }
        system.debug('HTML Text for Search<start>' + ISSearchStringText + '<ends>');
        for (Integer j=0; j < SearchStrings.size(); j++) {
            ISSearchStringText += SearchStrings[j];
        }
        system.debug('HTML Text for Campaign <start>' + ISCampaignStringText + '<ends>');
        for (Integer j=0; j < CampaignStrings.size(); j++) {
            ISCampaignStringText += CampaignStrings[j];
        }
        system.debug('HTML Text for Landing <start>' + ISLandingStringText + '<ends>');
        for (Integer j=0; j < LandingStrings.size(); j++) {
            ISLandingStringText += LandingStrings[j];
        }
        system.debug('HTML Text for Email<start>' + ISEmailStringText + '<ends>');
        for (Integer j=0; j < EmailStrings.size(); j++) {
            ISEmailStringText += EmailStrings[j];
        }
        system.debug('HTML Text for Display <start>' + ISDisplayStringText + '<ends>');
        system.debug('HTML Text for Search <start>' + ISSearchStringText + '<ends>');
        system.debug('HTML Text for Social <start>' + ISSocialStringText + '<ends>');
    system.debug('HTML Text for Website <start>' + ISWebsiteStringText + '<ends>');
        system.debug('HTML Text for Campaign <start>' + ISCampaignStringText + '<ends>');
        system.debug('HTML Text for Landing <start>' + ISLandingStringText + '<ends>');
        system.debug('HTML Text for Email <start>' + ISEmailStringText + '<ends>');


        csmso__Sales_Order__c so = [select Id, Name, Total_Impressions__c, Total_GST_inclusive__c, csmso__Total_Price__c,  GST__c, Campaign_Length__c, csmso__Status__c, Margin_Flag__c, Dashboard__c, Conversion_Tracking__c, Creative_Services__c from csmso__Sales_Order__c where id = :salesOrderId];

        // Check that the Sales Order is actually in a valid state
        /* T-26364 - original code
        If (((so.csmso__Status__c == 'Draft') || (so.csmso__Status__c == 'Externally Rejected') || (so.csmso__Status__c == 'Internally Rejected')) && (so.Margin_Flag__c  == 'Margin TOO LOW'))  {
          System.debug('Can not generate Sales Order, Margin to low and not approved:' + so.Margin_Flag__c );
          throw new InsertionOrderControllerException ('Please obtain approval for low margin.');
        } */
        // T-26364 new code, added check for Campaign length
        If ((((so.csmso__Status__c == 'Draft') || (so.csmso__Status__c == 'Externally Rejected') || (so.csmso__Status__c == 'Internally Rejected')) && ((so.Margin_Flag__c  == 'Margin TOO LOW'))) || (so.csmso__Status__c == 'Draft' && so.Campaign_Length__c != null))  {
            System.debug('Can not generate Sales Order, Margin to low and/or Campaign length is less than 3 months and not approved:' + so.Margin_Flag__c );
            throw new InsertionOrderControllerException ('Please obtain approval for Low margin or Seasonal campaign.');// T-26364 2016-08-08 'lenght' to 'length'
        }
        //end of T-26364 changes


        // Total Impressions
        //ISTotalDisplay =  so.Total_Impressions__c.intValue();

        //system.debug('Total Social ' + ISTotalSocial + ' Total Display ' + ISTotalDisplay);
/*
        if(so.Campaign_Length__c != null){
            TotalValueGSTInclusive = so.Total_GST_inclusive__c * so.Campaign_Length__c;
            TotalValue = so.csmso__Total_Price__c * so.Campaign_Length__c;
            TotalGST = so.GST__c * so.Campaign_Length__c;
        }
        else{
            TotalValueGSTInclusive = so.Total_GST_inclusive__c * 4;
            TotalValue = so.csmso__Total_Price__c * 4;
            TotalGST = so.GST__c * 4;
        }


        // Should we be displaying anything related to the Campaign
        CampaignISSummaryFlag = String.isNotEmpty(ISCampaignStringText) || so.Dashboard__c || so.Conversion_Tracking__c || so.Creative_Services__c;

        system.debug('Total Value ' + TotalValue + ' Total GST ' + TotalGST + ' Total GST Inclusive ' + TotalValueGSTINclusive);*/

        return null;


    }


// Search the current set of strings we're planning on displaying to see if we have a duplicate
    private Boolean lookforDuplicate(String foundthisHTML, List<String> StringsAlreadyFound) {
        Boolean foundMatch;

        System.debug('Searching for ' + foundThisHTML);

        foundMatch = false;
        for (Integer k=0; k < StringsAlreadyFound.size(); k++) {
            System.debug('Comparing' + foundThisHTML + ' vs ' + StringsAlreadyFound[k]);
            If (foundthisHTML == StringsAlreadyFound[k]) {
                foundMatch=true;
                break;
            }
        }
        System.debug('Searching status ' + foundMatch);
        return (foundMatch);
    }

    private integer calculateCount(String foundThisIOName, string foundThisTotalNumber) {
        // Search for a matching IO Name and perform Impression etc summation
        // Some Inserton Items are just true/false, some are counters
        Integer localTotalNumber;
        Boolean foundMatch;

        localTotalNumber=0;
        system.debug('Searching for IOName ' + foundThisIOName + ' and TotalNumber ' + foundThisTotalNumber);
        if(String.isBlank(foundThisIOName)) {
            system.debug('IOName is blank or null ');
            return localTotalNumber;
        }
        if ( String.isBlank(foundThisTotalNumber)) {
            system.debug('TotalNumber is not blank or null. May be unused for this Product ?');

        }  else if (foundThisTotalNumber.isNumeric()){
            localTotalNumber = Integer.valueOf(foundThisTotalNumber);
            system.debug('localTotalNumber ' + localTotalNumber + ' for IOName '  + foundThisIOName);
        }

        // See whether we have a section in the Insertion Order that deals with these
        foundMatch=false;
        for (Integer i=0; i < IORefDescriptions.size(); i++) {
            If (IORefDescriptions[i].name.equals(foundThisIOName)) {
                IORefDescriptions[i].Quantity__c+=localTotalNumber;
                System.debug('Insertion Order Description Match (' + i + ') Result ' + IORefDescriptions[i].name + ' Quantity = ' + IORefDescriptions[i].Quantity__c);
                foundMatch=true;
            }
        }
        If (!foundMatch) {
            System.debug('No Insertion Order Description Match for ' + foundThisIOName);
            throw new InsertionOrderControllerException ('No Insertion Order Description Match for :' + foundThisIOName + ', configuration error');
        }
        return localTotalNumber;
    }


	private Decimal calculatePrice(String foundThisIOName, string foundThisTotalPrice) {
        // Search for a matching IO Name and perform Impression etc summation
        // Some Inserton Items are just true/false, some are counters
        Decimal localPrice;
        Boolean foundMatch;

		System.debug('***foundThisIOName=' + foundThisIOName);
		System.debug('***foundThisTotalPrice=' + foundThisTotalPrice);


        localPrice=0;
        system.debug('Searching for IOName ' + foundThisIOName + ' and TotalNumber ' + foundThisTotalPrice);
        if(String.isBlank(foundThisIOName)) {
            system.debug('IOName is blank or null ');
            return localPrice;
        }
        if ( String.isBlank(foundThisTotalPrice)) {
            system.debug('TotalPrice is not blank or null. May be unused for this Product ?');

        }  else if (foundThisTotalPrice.replace('.','').isNumeric()){
            localPrice = Decimal.valueOf(foundThisTotalPrice);
            system.debug('localPrice ' + localPrice + ' for IOName '  + foundThisIOName);
        }

        // See whether we have a section in the Insertion Order that deals with these
        foundMatch=false;
        for (Integer i=0; i < IORefDescriptions.size(); i++) {
            If (IORefDescriptions[i].name.equals(foundThisIOName)) {
				System.debug('***localPrice=' + localPrice);
				Decimal tmpLocalPrice = mapIORefDescriptionsPrice.get(i) + localPrice;
				mapIORefDescriptionsPrice.put(i, tmpLocalPrice);
                System.debug('Insertion Order Description Match (' + i + ') Result ' + IORefDescriptions[i].name + ' Price = ' + mapIORefDescriptionsPrice.get(i));
                foundMatch=true;
            }
        }
        If (!foundMatch) {
            System.debug('No Insertion Order Description Match for ' + foundThisIOName);
            throw new InsertionOrderControllerException ('No Insertion Order Description Match for :' + foundThisIOName + ', configuration error');
        }
        return localPrice;
    }



    /**
     *  Fetch attributes and their values for the Sales order. If SO id is missing return empty list.
     *
     * @return List containing a Lists of Strings that containg config attributes(from attributeNames) and their values
     */
    public List<List<String>> getInsertions() {
        List<List<String>> result = new List<List<String>>();
        if (salesOrderId == null){
            return result;
        }

        result = getConfigAttributesGridWithRelatedPCs(salesOrderId,attributeNames);
        /*if (containsBundles) {

        }  else {

            result = csmso.SalesOrderSupport.getConfigAttributesGrid(salesOrderId, attributeNames);
        }*/

        return result;
    }

    /**
    *  Fetch attributes and their values for the Sales order. If SO id is missing return empty list.
    * @param  attributeNameList List of Strings containing attribute names to fetch
    * @return List containing a Lists of Strings that contain config attributes(from passed attribute Names) and their values
    */
    public List<List<String>> getInsertions(List<String> attributeNameList) {
        List<List<String>> result = new List<List<String>>();
        if (salesOrderId == null){
            return result;
        }
        try {

            result = getConfigAttributesGridWithRelatedPCs(salesOrderId, attributeNameList);

        } catch (InsertionOrderControllerException ioe) {
            throw  new InsertionOrderControllerException(ioe.getMessage());
        }

        /*if (containsBundles) {
            System.debug('*** getInsertions from Bundles');

        }  else {
            System.debug('*** getInsertions without Bundles');
            result = csmso.SalesOrderSupport.getConfigAttributesGrid(salesOrderId, attributeNameList);
        }*/

        return result;
    }
    /**
    *  Method to fetch Insertion Order Spec and populate attributeNames and printAttributeNames properties. Throws exception if missing.
    *  @return Void
    * */
    public void applyInsertionOrderConfigurables() {
        for (Insertion_Order_Spec__c insertionSpec : [SELECT Id, Line_Item_Columns__c, Logo_URL__c FROM Insertion_Order_Spec__c ]){
            logoURL = insertionSpec.Logo_URL__c;
            String lineItemColumns = insertionSpec.Line_Item_Columns__c;

            if (lineItemColumns.contains('Product Groups For IO')) {
                attributeNames = lineItemColumns.split(',');
            }

            if (lineItemColumns.contains('Publication State')) {
                printAttributeNames = lineItemColumns.split(',');

            }

            if (lineItemColumns.contains('Digital Product Name')) {
                digitalAttributeNames = lineItemColumns.split(',');
            }
        }
        if (attributeNames == null && printAttributeNames == null && digitalAttributeNames == null){
            throw new InsertionOrderControllerException ('Please check the \'Line Item Columns\' field for the \'InsertionOrder Spec\' record, none found.');
        }
    }

    /**
     *
     *  Locate and load all the Insertion Order Elements that describe the individual sections of an Insertion Order
     *
     *  @return List of NewsXtendIORef records with Quantity set to 0
     **/
    public List<NewsXtendIORef__c> findInsertionOrderElements() {

        List<NewsXtendIORef__c> myIORefDescriptions = new List<NewsXtendIORef__c>();

        myIORefDescriptions = [SELECT Id, Name, Campaign_Element__c, Details__c, Quantity__c, Display_Order__c, URL__c FROM NewsXtendIORef__c];

        for (Integer i=0; i < myIORefDescriptions.size(); i++) {
            System.debug('Insertion Order Description (' + i + ') Result ' + myIORefDescriptions[i]);

            // Set the number of these that the user has requested to 0
            myIORefDescriptions[i].Quantity__c = 0;

			//added by DD NX-304
			mapIORefDescriptionsPrice.put(i,0);
			//******************
        }
        return (myIORefDescriptions);
    }

    /**  See if any of the on/off flags for the Sales Order are on.
    * and show those as products
    *
    * @param myIORefDescriptions List of NewsXtendIORef__c records
    */
    public void findServiceOrderAddOns(List<NewsXtendIORef__c> myIORefDescriptions) {

        csmso__Sales_Order__c so = [select Id, Name, Dashboard__c, Conversion_Tracking__c, Creative_Services__c from csmso__Sales_Order__c where id = :salesOrderId];

        for (Integer i=0; i < myIORefDescriptions.size(); i++) {
            System.debug('Insertion Order Description (' + i + ') Result ' + myIORefDescriptions[i]);
            if (((myIORefDescriptions[i].name == 'Dashboard') && (so.Dashboard__c)) ||
                    ((myIORefDescriptions[i].name == 'Conversion Tracking') && (so.Conversion_Tracking__c)) ||
                    ((myIORefDescriptions[i].name == 'Creative Services' ) && (so.Creative_Services__c)))
            {
                myIORefDescriptions[i].Quantity__c = 1;
                System.debug('Insertion Order Description ( ' + myIORefDescriptions[i].name + ' SO Order Add on enabled');
            }
        }
    }

    /**
     *
     *
     * @param salesOrderId
     * @param attributeList
     *
     */
    public List<List<String>> getConfigAttributesGridWithRelatedPCs(String salesOrderId, List<String> attributeList ) {

        String lineItemColumns = String.valueOf(attributeList);
        String platform = '';

        if (lineItemColumns.contains('Product Groups For IO')) {
            platform = 'Xtend';
        } else if (lineItemColumns.contains('Publication State')) {
            platform = 'Print';
        } else if (lineItemColumns.contains('Digital Product Name')) {
            platform = 'Digital';
        }



        Map<Id, cscfga__Product_Configuration__c> Product_configurationsByIds = new Map<Id, cscfga__Product_Configuration__c>([SELECT Id,Impressions_Quantity__c FROM cscfga__Product_Configuration__c
        WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c =: salesOrderId
        AND Line_Item_Platform__c =: platform
        AND (Bundle_Name__c = '/' OR Bundle_Name__c = null)]);
        System.debug('*** getConfigAttributesGridWithRelatedPCs FOR PLATFORM : ' + platform + ' with ' + Product_configurationsByIds.keySet().size() + ' PCs');
        List<List<String>>   currentProductGrid = new List<List<String>>();
        List<String> attValues = new List<String>();

        for (Id pcID : Product_configurationsByIds.keySet()) {
            attValues = new List<String>();

            System.debug('*** getConfigAttributesGridWithRelatedPCs pcID > ' + pcID);
            for (String attName : attributeList) {
                System.debug('*** getConfigAttributesGridWithRelatedPCs attName > ' + attName);
                Boolean attributeMissing = false;
                cscfga__Attribute__c attribute;
                try {
                 	attribute = csmso.SalesOrderSupport.getAttributeByName(String.valueOf(pcId), attName);
                } catch(Exception soex) {
                    attributeMissing = true;
                }
                String attValue = null;
                if(!attributeMissing && attribute != null)
                    attValue = attribute.cscfga__Value__c;

                // throwing errors for non Xtend null attributes, Xtend should be handled correctly in original code
                if (!attributeMissing && attValue == null && (platform == 'Print' || platform == 'Digital')) {
                    throw new InsertionOrderControllerException('Please check configuration with \n ID ' + pcID +'\n attribute ' + attName + '\n is null');
                }

                if(!attributeMissing)
                	attValues.add(attValue);

                //03/09/2018 PM udpate for bundle print (both bundle and bespoke populate impressions quantity on PC)
                if (attributeMissing && platform == 'Print' && attName == 'Insertions') {
                    attValues.add(String.valueOf(Product_configurationsByIds.get(pcID).Impressions_Quantity__c));
                }
            }
            System.debug('*** getConfigAttributesGridWithRelatedPCs for ' + platform  + ' : ' + attValues);
            currentProductGrid.add(attValues);
        }

        System.debug(attValues.size());

        return currentProductGrid;
    }

    public Boolean getIsSeasonalPrint() {
        String productType =  workingSo.Campaign_Products_Type__c;
        return productType == (SEASONAL_PRINT);

    }

    public Boolean getIsSeasonalXtend() {
        String productType =  workingSo.Campaign_Products_Type__c;
        return productType == (SEASONAL_XTEND);

    }

    public Boolean getIsEvergreen() {
        String productType =  workingSo.Campaign_Products_Type__c;
        return productType == (EVERGREEN);

    }


    public Boolean getContainsPrintOrDigital() {
        return ( !printIORefFormatedDescriptions.isEmpty() || !digitalIORefFormatedDescriptions.isEmpty() );
    }

    public class InsertionOrderControllerException extends Exception{
        //intentionally left blank
    }

    public class LineItemWrapper {

        //public csmso.SalesOrderSupport.SalesOrderBookingWrapper wrapper{get;set;}

        public List<String> getColumns() {
            return null;
        }
    }

    public class PrintWrapper {
        // Type,State,Publication,Impressions Quantity,Ad Size,Selected Dates
        public String  Publication         {get; set;}
        public Integer ImpressionsQuantity {get; set;}
        public String  AdSize              {get; set;}
        public String  SelectedDates       {get; set;}
        public String  ProductDescription  {get; set;}
        public String  ProductLevel  {get; set;}
        public String  EstimatedStartDate {get;set;}
        public String  Cycle {get;set;}

        private final String PRIMARY_PRINT = 'Reach a highly engaged audience by advertising regularly in the newspaper.' +
                'Through strong creative executions, make your customers aware of your product ' +
                'and keep top of mind when they are ready to buy.';
        private final String ADDED_PRINT = 'Extend your audience through advertising in one of our other publications in your target area.';

        public PrintWrapper(String Publication, Integer ImpressionsQuantity, String AdSize, String SelectedDates, String Cycle) {
            this.Publication = Publication ;
            this.ImpressionsQuantity = ImpressionsQuantity ;
            this.AdSize = AdSize ;
            this.SelectedDates = SelectedDates ;
            this.Cycle = Cycle;
            if(!SelectedDates.split(',').isEmpty()) {
                Date startDate = Date.valueOf(SelectedDates.split(',')[0].replaceAll('"', '').substring(1));
                this.EstimatedStartDate = startDate.format();
            }
            	
        }

        public void setPublicationLevel(Integer index) {
            ProductLevel = (index == 0) ? 'Primary Publication' : 'Additional Publication';
            ProductDescription =  (index == 0) ? PRIMARY_PRINT : ADDED_PRINT;
        }
    }


    public class DigitalWrapper {

        public String  ProductName  {get; set;}
        public Integer Quantity    {get; set;}
        public Integer TotalQuantity    {get; set;}
        public Integer Items       {get;set;}

        public DigitalWrapper(String ProductName, Integer Quantity, Decimal MonthDuration) {
            this.ProductName = ProductName;
            this.Quantity    = Quantity;
            this.TotalQuantity = Integer.valueOf( Quantity * MonthDuration);
            System.debug('DigitalWrapper: New "' + this.ProductName +
                         '" , Qty: '             + this.Quantity +
                         ', MonthDuration :'     + MonthDuration +
                         ', TotalQty: '          + this.TotalQuantity );
            this.Items = 1;
        }

        public void addItemsQuantity(Integer Quantity, Decimal MonthDuration) {
            this.Items +=1;
            this.Quantity +=Quantity;
            this.TotalQuantity += Integer.valueOf(( Quantity * MonthDuration));
            System.debug('DigitalWrapper: Adding quantity "' + this.ProductName +
                         '" , Qty: '             + Quantity +
                         ', MonthDuration :'     + MonthDuration +
                         ', TotalQty: '          + this.TotalQuantity );
        }
    }

    public class DataErrorWrapper {
        public Boolean errorsFound {get;set;}
        public String  errorMessage {get; set;}


        public DataErrorWrapper() {
            errorsFound = false;
        }

    }

}