@isTest
public class GRAXPermissionsTest {
    private static Integer s_num = 1;

    public static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);

        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }

    @isTest
    public static void GRAXPermissionsTest1() {
        GRAXPermissions gp = new GRAXPermissions(getFakeId(User.getSObjectType()));

        System.assertEquals(false, gp.getIsAdmin());
        System.assertEquals(false, gp.getIfhasBackupPagePermission());
        System.assertEquals(false, gp.getIfhasBackupPermission());
        System.assertEquals(false, gp.getIfhasBackupArchivePermission());
        System.assertEquals(false, gp.getIfhasRestorePagePermission());
        System.assertEquals(false, gp.getIfhasRestorePermission());
    }
}