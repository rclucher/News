/**
 * Class used for billing file csv generation
 */
public class CS_BillingFileCSVGenerator {
    @TestVisible
    private static String header = 'Site,Debtor,Parent,Publication,Pub Name,Pub Date,Booked Date,Processing Date,STMT Appearance Date,Ad Type,Section,Package Code,Package Desc,Document Type,Caption,STMT Charge,Class Code,Class Desc,Sales Rep Code,Sales Rep Desc,Book Point,Price Code,Placed By,Order No,Receipt No,Size,Page No,Authority,Ad Number,Sub Booking,Insert No,Insert Serial ID,Rollup Field,Rollup Type';
    
    /**
     * Generates CSV file
     * @param billingFile
     * @return String
     */
    public static String generateCSV(Billing_File__c billingFile) {
        String csvFile = '';
        String rows = '';
        Id billingFileId = billingFile.Id;
        String paymentQuery = 'select ' + CS_Utils.getSobjectFields('Payment_Schedule__c');
        paymentQuery += ', Payment__r.Advertiser_Account_Adpoint_ID__c, Payment__r.Payer_Account_Adpoint_ID__c, Payment__r.Order__r.Opportunity__r.Name,Payment__r.Order__r.Opportunity__r.ClientPOReference__c';
        paymentQuery += ', Payment__r.Start_Date__c, Payment__r.Amount__c, Payment__r.Primary_Contact_on_SO__c, Payment__r.Order__r.Opportunity__r.Owner.Name';
        paymentQuery += ', Payment__r.Name,Payment__r.JDE_Publication_Code__c';
        paymentQuery += ' from Payment_Schedule__c where id in ';
        paymentQuery += ' (select Payment_Schedule__c from PS_Billing_File_Association__c where Billing_File__c = :billingFileId)';
        List<Payment_Schedule__c> paymentSchedules = Database.query(paymentQuery);
        
        for (Payment_Schedule__c ps : paymentSchedules) {
            Decimal amount = ps.Amount__c;
            if (amount == null) {
                amount = 0;
            }
            if (amount >= 0.005 || amount <= -0.005) {
                String soNumber = '';
                if (ps.Payment__r.Name.split('-').size() == 3) {
                    soNumber = ps.Payment__r.Name.split('-')[1].deleteWhitespace() + '-' + ps.Payment__r.Name.split('-')[2].deleteWhitespace();
                }
                rows += '\n';
                rows += 'NET' + ','; // Site
                rows += ps.Payment__r.Advertiser_Account_Adpoint_ID__c + ','; // Debtor
                rows += ps.Payment__r.Payer_Account_Adpoint_ID__c + ','; // Parent
                rows += ps.Payment__r.JDE_Publication_Code__c + ','; // Publication
                rows += 'Xtend' + ','; // Pub Name
                rows += datetime.newInstance(ps.Schedule_Start_Date__c.year(), ps.Schedule_Start_Date__c.month(), ps.Schedule_Start_Date__c.day()).format('yyyyMMdd') + ','; // Pub Date
                rows += datetime.newInstance(ps.Payment__r.Start_Date__c.year(), ps.Payment__r.Start_Date__c.month(), ps.Payment__r.Start_Date__c.day()).format('yyyyMMdd') + ','; // Booked Date
                rows += System.now().format('yyyyMMdd') + ','; // Processing Date
                rows += datetime.newInstance(ps.Billing_Date__c.year(), ps.Billing_Date__c.month(), ps.Billing_Date__c.day()).format('yyyyMMdd') + ','; // STMT Appearance Date
                rows += 'OL' + ','; // Ad Type
                rows += '' + ','; // Section
                rows += '' + ','; // Package Code
                rows += '' + ','; // Package Desc
                rows += 'RI' + ','; // Document Type
                rows += ps.Payment__r.Order__r.Opportunity__r.Name + ','; // Caption
                
                rows += amount.setScale(2) + ','; // STMT Charge
                rows += 'XTND' + ','; // Class Code
                rows += 'Xtend' + ','; // Class Desc
                rows += '' + ','; // Sales Rep Code
                rows += ps.Payment__r.Order__r.Opportunity__r.Owner.Name + ','; // Sales Rep Desc
                rows += '' + ','; // Book Point
                rows += '' + ','; // Price Code
                rows += ps.Payment__r.Primary_Contact_on_SO__c + ','; // Placed By
                rows += ps.Payment__r.Order__r.Opportunity__r.ClientPOReference__c+ ','; // Order No
                rows += '' + ','; // Receipt No
                rows += 'WEB' + ','; // Size
                rows += '' + ','; // Package No
                rows += '' + ','; // Authority
                rows += soNumber; // Ad Number
                rows += '' + ','; // Sub Booking
                rows += '' + ','; // Insert No
                rows += '' + ','; // Insert Serial Id
                rows += '' + ','; // Roll Up Field
                rows += '' + ','; // Roll Up Type
            }
        }
        csvFile += header;
        csvFile += rows;
        csvFile = csvFile.replace('null','');
        return csvFile;
    }


}