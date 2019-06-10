@isTest
public class GRAXAccountReportingCtrlTest {
    @isTest
    public static void GRAXAccountReportingCtrlTest1() {
        GRAXAccountReportingCtrl gar = new GRAXAccountReportingCtrl(new ApexPages.StandardController(new Account()));

        gar.getSettings();
    }
}