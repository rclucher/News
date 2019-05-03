/**
 * Created by petar.mikic on 15/12/2017.
 */

global without sharing class ButtonSOPricingCalculator implements  csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderID) {
        csmso__Sales_Order__c salesOrder = [SELECT  ID,
                csmso__From__c,
                csmso__To__c,
                Platform_Set__c,
                Client_Gross_Revenue__c,
                Client_Current_Discount_FY__c, //Client Print Discount
                Share_of_Wallet__c,
                Print_Customer_Tier__c,
                csmso__Advertiser__r.Digital_Customer_Tier__c,  // will be replaced by SO field
                Customer_Segment__c,
                Customer_State__c,
                Calculated_Target_Discount__c,
                Print_Status__c,
                Proposed_Print_Discount__c
        FROM csmso__Sales_Order__c WHERE Id =: salesOrderID];

        if (String.isNotEmpty(salesOrder.Platform_Set__c) && salesOrder.Platform_Set__c.contains('Print')) {


            if (salesOrder.Proposed_Print_Discount__c == null ) {
                return '{"status": "ok" , "message" : "Proposed Discount has no value to distribute to Line items."}';
            }

            SalesOrder_Helper.propagateProposedPrintDiscount(salesOrder);

            return '{"status": "ok" , "message" : "Proposed Discount distributed to Line items."}';
        }


        return '{"status": "ok" , "message" : "No print products to update."}';


    }

    public static void runCVSRecalculation(Map<String,List<Client_Value_Point__c>> cvpNameMap, List<Client_Value_Score__c> cvsList, csmso__Sales_Order__c salesOrder){

        Decimal maxDiscountThreshold = salesOrder.Calculated_Target_Discount__c;
        Decimal TargetDiscount = 0;

        Decimal clientValuePoints = calculateClientValuePoints(cvpNameMap, salesOrder);
        Decimal clientValueScore =  calculateClientValueScore(cvsList, clientValuePoints, salesOrder);


        Decimal PP_Difference = (salesOrder.Client_Current_Discount_FY__c - maxDiscountThreshold);

        // discounting x PP factor
        Decimal PP_Factor = Decimal.valueOf(Label.Discount_Framework_X_Factor);

        Decimal X_Percentage = Math.min(PP_Factor, PP_Difference);

        TargetDiscount = salesOrder.Client_Current_Discount_FY__c - X_Percentage + clientValueScore;

        salesOrder.Client_Value_Score__c         = clientValueScore;
        salesOrder.Target_Discount__c            = TargetDiscount;
        salesOrder.Print_Status__c               = 'Target discount recalculated.';

        if (!Trigger.isExecuting) {
            System.debug('Rule *** Using client discount with X% and CSV');
            System.debug('Rule *** CD  : ' + salesOrder.Client_Current_Discount_FY__c);
            System.debug('Rule *** MDT : ' + maxDiscountThreshold);
            System.debug('Rule *** PP Difference: ' + PP_Difference);
            System.debug('Rule *** PP Factor: ' + PP_Factor);
            System.debug('Rule *** X% : ' + X_Percentage);
            System.debug('Rule *** Setting TD to:' + TargetDiscount);

        }
    }

    public static Decimal calculateClientValuePoints(Map<String,List<Client_Value_Point__c>> cvpNameMap, csmso__Sales_Order__c salesOrder) {


         /* Setting "Number Of Publications "value*/
        Decimal numbOfPubsPointsScore     =  0;

        try {
            numbOfPubsPointsScore = getNumberOfPublicationsScore(cvpNameMap, salesOrder);

        } catch (Exception e) {
            throw new DiscountParamException('Error with fetching client value points for "Number of Publications".' + e.getStackTraceString());
        }


         /* Setting "Insertion Count" value*/

        Decimal insertionCountPointsScore = 0;

        try {
            insertionCountPointsScore = getInsertionCountScore(cvpNameMap, salesOrder);

        } catch (Exception e) {
            throw new DiscountParamException('Error with fetching client value points for "Insertion Count".' + e.getStackTraceString());
        }


         /* Map for selecting Client Value Score points*/
        Decimal walletShareAndProducMixPointsScore = 0;

        walletShareAndProducMixPointsScore  = getSummarizedProductMixAndShareScore(cvpNameMap,salesOrder);


        /* Adding Up total score */
        Decimal clientValuePointsTotalscore = 0;

        clientValuePointsTotalscore += numbOfPubsPointsScore;
        clientValuePointsTotalscore += insertionCountPointsScore;
        clientValuePointsTotalscore += walletShareAndProducMixPointsScore;


        System.debug('CVP total score: ' + clientValuePointsTotalscore);

        return clientValuePointsTotalscore;
    }

    public static Discount_Threshold__c calculatePrintDiscountThreshold(csmso__Sales_Order__c salesOrder) {

        system.debug('Customer tier >' + salesOrder.Print_Customer_Tier__c);
        system.debug('Customer segment >' + salesOrder.Customer_Segment__c);

        try {

            Discount_Threshold__c discountThreshold = [SELECT Id, Amount_Level_1__c,Amount_Level_2__c,Amount_Level_3__c,
                    Discount_Level_1__c, Discount_Level_2__c,Discount_Level_3__c
            FROM Discount_Threshold__c
            WHERE Platform__c = 'Print'
            AND Segment__c= :salesOrder.Customer_Segment__c
            AND Customer_Tier__c = :salesOrder.Print_Customer_Tier__c][0];

            System.debug('Discount Threshold rec:' + discountThreshold);

            return discountThreshold;

        } catch (Exception e) {
            throw new DiscountParamException('Error in fetching discount threshold record for Platform "Print", Segment '
                    + salesOrder.Customer_Segment__c
                    + ' and Tier '
                    + salesOrder.Print_Customer_Tier__c );
        }



    }

    public static Decimal calculateClientValueScore(List<Client_Value_Score__c> cvsList, Decimal clientValuePoints,csmso__Sales_Order__c salesOrder) {

        Decimal clientValueScore = 0;

        System.debug('Customer Tier :' + salesOrder.Print_Customer_Tier__c);

        try {

            for (Client_Value_Score__c cvs:cvsList) {
                if ( (cvs.Customer_Tier__c == salesOrder.Print_Customer_Tier__c)
                        && (cvs.Points_From__c == null || cvs.Points_From__c <= clientValuePoints)
                        && (cvs.Points_To__c == null || cvs.Points_To__c >= clientValuePoints) ) {

                    clientValueScore = cvs.Discount__c; // not checking for null, field is mandatory
                    break;
                }
            }


        } catch (Exception e) {
            throw  new DiscountParamException('Error in getting client value score for Print platform with a score of ' + String.valueOf(clientValuePoints) );
        }

        System.debug('Client Value Score Discount :' + clientValueScore);

        return clientValueScore;
    }

    /*
    *  method to receive Map of Client Value Points with Name key for provided platform
    * **/
    public static Map<String,List<Client_Value_Point__c>> getPlatformClientValuePointsMap(String platform) {

        Map<String,List<Client_Value_Point__c>> cvpNameMap = new Map<String, List<Client_Value_Point__c>>();

        for (Client_Value_Point__c cvp: [SELECT  Id, Name__c,Value__c, Score__c, Platform__c FROm Client_Value_Point__c WHERE Platform__c =: platform]) {

            if ( !cvpNameMap.containsKey(cvp.Name__c)) { cvpNameMap.put(cvp.Name__c,new List<Client_Value_Point__c>());}

            cvpNameMap.get(cvp.Name__c).add(cvp);
        }

        return cvpNameMap;
    }


    /*
    *  Getting score for Numb of pubs from CVP Map
    * */
    public static Decimal getNumberOfPublicationsScore(Map<String,List<Client_Value_Point__c>> cvpNameMap, csmso__Sales_Order__c salesOrder) {

        List<Client_Value_Point__c> pubPoints = cvpNameMap.get('Number of Publications');

        Decimal NumbOfPubsScore = 0;
        Integer numOfPubs           =  Integer.valueOf(salesOrder.Print_Publication_Count__c);
        String  strNumOfPubs        =  String.valueOf(numOfPubs);

        String  tempVal            = '';

        for (Client_Value_Point__c pubPoint: pubPoints) {
            tempVal = pubPoint.Value__c;

            // if value is "1","2" or "3"
            if (tempVal == strNumOfPubs) {
                NumbOfPubsScore = pubPoint.Score__c;
                break;
            }

            // if value is "4+", remove + sign and check if >=
            if (tempVal.contains('+') && (numOfPubs >= Integer.valueOf(tempVal.remove('+')))) {
                NumbOfPubsScore = pubPoint.Score__c;
                break;
            }
        }
        if (!Trigger.isExecuting) {
            System.debug('CVP # of Pubs (' + salesOrder.Print_Publication_Count__c +') :' + NumbOfPubsScore );
        }

        return NumbOfPubsScore;
    }

    /*
     * Getting score for Insertion count from CVP Map
     */
    public static Decimal getInsertionCountScore(Map<String,List<Client_Value_Point__c>> cvpNameMap, csmso__Sales_Order__c salesOrder) {

        //spliting "A-B Insertions" Value__c to define range
        List<Client_Value_Point__c> icPoints = cvpNameMap.get('Insertion Count');

        List<String> insertionCountRange = new List<String>();
        Integer numOfInsertions = Integer.valueOf(salesOrder.Print_Impressions_Count__c);
        Decimal insertionCountScore = 0;

        for (Client_Value_Point__c insertPoint: icPoints) {

            insertionCountRange = insertPoint.Value__c.splitByCharacterType();  // "16+ " returns (16, +) ; "5-9" returns (5, -, 9)

            if (insertionCountRange.size()==2 && numOfInsertions >= Integer.valueOf(insertionCountRange[0]) ) { //got max value i.e. 16+
                insertionCountScore = insertPoint.Score__c;
                break;

            } else { //assuming we got 3 options, checking against index 0 and 2 i.e "5-9" returns (5, -, 9)
                if (numOfInsertions >= Integer.valueOf(insertionCountRange[0])
                        && numOfInsertions <= Integer.valueOf(insertionCountRange[2])) {
                    insertionCountScore = insertPoint.Score__c;
                    break;
                }
            }
        }

        if (!Trigger.isExecuting) {
            System.debug('CVP Insertions (' + salesOrder.Print_Impressions_Count__c +') :' + insertionCountScore );
        }

        return insertionCountScore;
    }

    /*
     *  Getting added score for Share of Wallet and Product Mix
     */
    public static Decimal getSummarizedProductMixAndShareScore(Map<String,List<Client_Value_Point__c>> cvpNameMap,csmso__Sales_Order__c salesOrder) {


        Decimal mixScore = 0;
        Decimal sowScore = 0;

        List<Client_Value_Point__c> sowPoints = cvpNameMap.get('Share of Wallet');
        List<Client_Value_Point__c> mixPoints = cvpNameMap.get('Product Mix');

        for (Client_Value_Point__c mixPoint: mixPoints) {
            if (mixPoint.Value__c == salesOrder.Platform_Set__c) {
                mixScore = mixPoint.Score__c;
                break;
            }
        }


        for (Client_Value_Point__c sowPoint: sowPoints) {
            if (sowPoint.Value__c == salesOrder.Share_of_Wallet__c) {
                sowScore = sowPoint.Score__c;
                break;
            }
        }
        if (!Trigger.isExecuting) {
            System.debug('CVP Platform (' + salesOrder.Platform_Set__c +') :' + mixScore);
            System.debug('CVP Share Of Wallet (' + salesOrder.Share_of_Wallet__c +') :' + sowScore );
        }
        return (mixScore+sowScore);
    }



    public class DiscountParamException extends  Exception {}
}