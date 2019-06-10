@isTest
private class GRAXExceptionUT {
	@isTest
    static void test()
    {
    		String SampleMessage = 'GRAX Exception Test';
    		Double SampleDouble = 3.1415;
        try
        {
            throw new GRAXException(SampleMessage,SampleDouble);
        }
        catch(Exception e)
        {
            system.assertEquals(SampleMessage, e.getMessage());
            GRAXException me = (GRAXException) e;
            system.assertEquals(SampleMessage, me.getMessage());
            system.assertEquals(SampleDouble, me.d);
        }
    }
}