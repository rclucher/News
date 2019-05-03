@isTest
public class AT_FormattedDate_Test {

    @isTest
    public static void Unit1(){
        AT_FormattedDate AT_FD = new AT_FormattedDate();
        AT_FD.date_time=DateTime.now();
        AT_FD.getFormattedDatetime();
    }
    
    @isTest
    public static void Unit2(){
        AT_FormattedDate AT_FD = new AT_FormattedDate();
        AT_FD.date_time=DateTime.now();
        AT_FD.defined_format='HH:MM';
        AT_FD.getFormattedDatetime();
    }

}