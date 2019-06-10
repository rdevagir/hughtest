/*****************************************************************************************
Name              : GRAXSchedulerToResendDataRecordsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       04/17/2018				David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
******************************************************************************************/
@istest
public with sharing class GRAXSchedulerToResendDataRecordsTest {
    static testmethod void GRAXSchedulerToResendDataRecordsTest() {
        Test.startTest();
        
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

        String jobId = System.schedule('ResendDataRecords', CRON_EXP, new GRAXSchedulerToResendDataRecords());

        Test.stopTest();
    }
}