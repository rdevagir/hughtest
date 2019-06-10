@isTest
public with sharing class GRAXUtilsTest {
    @isTest
    static void createObjectInstanceTest() {
        System.assertNotEquals(null, GRAXUtils.createObjectInstance(GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c', null, true));
    }

    @isTest
    static void castGenericObjectToTypeTest() {
        System.assertEquals(null, GRAXUtils.castGenericObjectToType('', 'string'));
        System.assertEquals(true, GRAXUtils.castGenericObjectToType('true', 'boolean'));
        System.assertEquals(1261992, GRAXUtils.castGenericObjectToType('1261992', 'double'));
        System.assertEquals(1, GRAXUtils.castGenericObjectToType('1', 'integer'));
        System.assertEquals(1.5, GRAXUtils.castGenericObjectToType('1.5', 'decimal'));

        Datetime dt = Datetime.now();
        dt = dt.addSeconds(dt.second() * -1);

        Time t = dt.timeGmt();
        t = t.addMilliseconds(t.millisecond() * -1);

        System.assertEquals(dt, GRAXUtils.castGenericObjectToType(dt.format(), 'datetime'));
        System.assertEquals(dt.dateGmt(), GRAXUtils.castGenericObjectToType(dt.dateGmt().format(), 'date'));
        System.assertEquals(t, GRAXUtils.castGenericObjectToType(String.valueOf(t), 'time'));
    }

    @isTest
    static void getSObjectByIdTest() {
        GRAX_Data_Record__c gdr = new GRAX_Data_Record__c();
        insert gdr;

        System.assertEquals(gdr.Id, GRAXUtils.getSObjectById(gdr.Id).Id);
    }

    @isTest
    public static void formatDateTimeStringTest() {
        Test.startTest();

        String userTimeZone = 'America/New_York';

        System.assert(GRAXUtils.formatDateTimeString('2018-10-18', userTimeZone).startsWith('10/18/2018'));
        System.assert(GRAXUtils.formatDateTimeString('2018-10-18T12:52:34.000+0000', userTimeZone).startsWith('10/18/2018'));

        Test.stopTest();
    }
}