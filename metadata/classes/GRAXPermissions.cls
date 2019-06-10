/*****************************************************************************************
Name              : GRAXPermissions
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       08/15/2018             David Mackey        Create necessary "Permission Sets" (https://app.asana.com/0/326600806074978/749901377818186/f)
2. Leandro Brunner       05/08/2019             David Mackey        "Override Child Objects for Archive" Permission (https://app.asana.com/0/326600806074978/1120957110975898/f)
******************************************************************************************/
public with sharing class GRAXPermissions {
    private static final String psAdmin = 'GRAX_Admin';
    private static final String psLimitedAdmin = 'GRAX_Limited_Admin';
    private static final String psDataAdmin = 'GRAX_Data_Admin';
    private static final String psUser = 'GRAX_User';
    private static final String psAdvancedUser = 'GRAX_Advanced_User';
    private static final String psArchiveMaster = 'GRAX_Archive_Master';

    private static Map<Id, Set<String>> permissionsSetByUser = new Map<Id, Set<String>>();

    private Id userId;

    public GRAXPermissions(Id userId) {
        this.userId = userId;

        loadPermissionsSetOfUser(userId);
    }

    private static void loadPermissionsSetOfUser(Id userId) {
        if(!permissionsSetByUser.containsKey(userId)) {
            permissionsSetByUser.put(userId, new Set<String>());
        } else {
            for(PermissionSetAssignment psa : [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name LIKE 'GRAX%']) {
                permissionsSetByUser.get(userId).add(psa.PermissionSet.Name);
            }
        }
    }

    private static Boolean containsAnyPermissionSet(Id userId, Set<String> permissionSets) {
        for(String ps : permissionSets) {
           if(permissionsSetByUser.get(userId).contains(ps)) {
               return true;
           }
        }

        return false;
    }

    // Get if the user can access the Backup page.
    public static Boolean hasAdminPermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdmin, psLimitedAdmin});
    }

    public Boolean getIsAdmin() {
        return hasAdminPermission(this.userId);
    }

    // Get if the user can access the Attachments Preview / Download
    public static Boolean hasDataAdminPermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdmin, psDataAdmin});
    }

    public Boolean getIsDataAdmin() {
        return hasDataAdminPermission(this.userId);
    }

    // Get if the user can access the Backup page.
    public static Boolean hasBackupPagePermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdmin, psLimitedAdmin});
    }

    public Boolean getIfhasBackupPagePermission() {
        return hasBackupPagePermission(this.userId);
    }

    // Get if the user can do Backups of records.
    public static Boolean hasBackupPermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdmin, psLimitedAdmin});
    }

    public Boolean getIfhasBackupPermission() {
        return hasBackupPermission(this.userId);
    }

    // Get if the user can archive records.
    public static Boolean hasBackupArchivePermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdmin});
    }

    public Boolean getIfhasBackupArchivePermission() {
        return hasBackupArchivePermission(this.userId);
    }


    // Get if the user can access the Restore page.
    public static Boolean hasRestorePagePermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psUser, psAdvancedUser, psLimitedAdmin, psAdmin});
    }

    public Boolean getIfhasRestorePagePermission() {
        return hasRestorePagePermission(this.userId);
    }

    // Get if the user can restore records.
    public static Boolean hasRestorePermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psAdvancedUser, psLimitedAdmin, psAdmin});
    }

    public Boolean getIfhasRestorePermission() {
        return hasRestorePermission(this.userId);
    }

    // Get if the user can override the archive process.
    public static Boolean hasArchiveMasterPermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psArchiveMaster});
    }

    public Boolean getIsArchiveMaster() {
        return hasArchiveMasterPermission(this.userId);
    }

    public static Boolean hasOverrideArchivePermission(Id userId) {
        loadPermissionsSetOfUser(userId);

        return containsAnyPermissionSet(userId, new Set<String>{psArchiveMaster});
    }

    public Boolean getIfhasOverrideArchivePermission() {
        return hasOverrideArchivePermission(this.userId);
    }
}