/*****************************************************************************************
Name              : GRAXSettingsUT
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/

@isTest
private class GRAXSettingsUT {
    
    @isTest
    static void ConstructorTest() {
    		GRAXSettings.debug('ConstructorTest', 'Unit Test', '',1);
        GRAXSettings gxs = new GRAXSettings();
        gxs = new GRAXSettings('Account');
        gxs = new GRAXSettings('ConstructorTest', 'Account');
    }
    
    @isTest
    static void IsConfigured() {
    		GRAXSettings.debug('IsConfigured', 'Unit Test', '',1);
        GRAXSettings.IsConfigured();
    }
}