/*---------------------------------------------------------
  Author: David Dawson (BlueWolf) & Jamie Cooper (New Voice Media)
  Date: June 2016
  Description: Trigger Handler class for the NVM Call Summary object
  Changelog:
  - 10/06/2016 | David Dawson | migrated the ExtractSkill from the trigger itself into the trigger handler class.
    Also implemented indenting/formatting and commenting.
  - 2016-08-04 louis.wang@bluewolf.com - Check chkStr to see if it is blank first, as not every record has value for it.
                     - Add break once the string is found, to improve the performance
 ---------------------------------------------------------*/

public with sharing class NVMCallSummary_Helper {

  public void ExtractSkill(){
    //define a string constant for the regex-escaped | character
    final String CHKSTR_END_CHAR_REGEX = '\\|';
    final String MATCH_STRING= 'SkillTagger~ST ';

    //for each record
    for (NVMStatsSF__NVM_Call_Summary__c SS : (List<NVMStatsSF__NVM_Call_Summary__c>)Trigger.new) 
    {
      List<String> events = new List<String>();
      try 
      {
        // 2016-08-04 Item-00520 louis.wang@bluewolf.com - Not every record has value for chkStr. Check it so it does not break the trigger.
        String chkStr = SS.NVMStatsSF__ChkStr__c;
        if(!String.isBlank(chkStr))
        {
          events = chkStr.split(CHKSTR_END_CHAR_REGEX);
        }
      } 
      catch (Exception ex) 
      {
        events = new List<String>();
      } 
      //System.debug('One loop through');
      System.debug(events);//
      //events will be: “20150128092531-S1-0-000-Start OK”, “20150128092531-NA-0-001-SkillTagger~ST Consumer Overview”,”20150128092845-S-194-072-END~AN Thank you~Caller”
      //for each event:
      For (String s : events) {
        Integer marker = s.indexOf(MATCH_STRING); 
        // indexOf - Returns the index of the first occurrence of the specified substring. If the substring does not occur, this method returns -1.
        If(marker > -1) {
          SS.Associated_Skill__C = (s.subString(marker + MATCH_STRING.length())).trim();
          //System.debug('Entering substring within Events - this should amend the field value');
          system.debug('Skill is updated - ' + SS.Associated_Skill__C);
          // once the string is found, break the for-loop to improve the efficiency
          break;
        }//end if
      }//end loop over events
    }//end loop over trigger collection
  }

}