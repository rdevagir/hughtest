/*****************************************************************************************
Name              : GRAXSchedulerToProcessDynamicFlowTest
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner         09/03/2018           David Mackey          Scheduled Job to Trigger a Flow (https://app.asana.com/0/326600806074978/778127037078388/f)
******************************************************************************************/
@isTest
public class GRAXSchedulerToProcessDynamicFlowTest {
    @isTest
    static void GRAXSchedulerToProcessDynamicFlowTest1() {
        Test.startTest();
        
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

        String jobId = System.schedule('GRAXSchedulerToProcessDynamicFlow', CRON_EXP, new GRAXSchedulerToProcessDynamicFlow());

        Test.stopTest();
    }
}