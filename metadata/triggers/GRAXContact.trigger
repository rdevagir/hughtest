trigger GRAXContact on Contact (after update,after insert,after delete,after undelete) {
    // -------------------------------------------------
    // https://GRAX.io/
    // Support Contact - Support At HardingPoint.com
    // -------------------------------------------------
    try {
        String url = '';
        String content = GRAXApi.jsonContent(Trigger.new, Trigger.old);
        GRAXCloud.callout(url, content);
    } catch(exception ex) {
        // Handle all exceptions want to avoid breaking customers salesforce.
        System.debug('[Trigger GRAXContact] ' + ex.getMessage());
    }
}