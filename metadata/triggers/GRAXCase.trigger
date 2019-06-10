trigger GRAXCase on Case (after update,after insert,after delete,after undelete) {
    // -------------------------------------------------
    // https://GRAX.io/
    // Support Contact - Support At HardingPoint.com
    // -------------------------------------------------
    // try {
        String url = '';
        System.debug('[GRAX.io] Before GRAXApi.jsonContent');
        String content = GRAXApi.jsonContent(Trigger.new, Trigger.old);
        System.debug('[GRAX.io] BEFORE GRAXCloud.callout');
        GRAXCloud.callout(url, content);
        System.debug('[GRAX.io] AFTER GRAXCloud.callout');
    //} catch(exception ex) {
    //    // Handle all exceptions want to avoid breaking customers salesforce.
    //    System.debug('[Trigger GRAXCase] ' + ex.getMessage());
    //}
}