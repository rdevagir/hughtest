/*****************************************************************************************
Name              : GRAXCSVIteratorTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
2. Leandro Brunner          06/25/2018
******************************************************************************************/
@isTest
public with sharing class GRAXCSVIteratorTest {

    @isTest
    public static void GRAXCSVIteratorTest1() {
        String csv = '';

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest2() {
        List<String> lines = new List<String>{
            '"lowercase","UPPERCASE"',
            '"test","TEST"'
        };

        String csv = String.join(lines, '\r\n') + '\r\n';

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());

        List<String> csvItValue1 = csvIt.next();
        System.assertEquals('lowercase', csvItValue1.get(0));
        System.assertEquals('UPPERCASE', csvItValue1.get(1));

        List<String> csvItValue2 = csvIt.next();
        System.assertEquals('test', csvItValue2.get(0));
        System.assertEquals('TEST', csvItValue2.get(1));

        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest3() {
        List<String> lines = new List<String>{
            '"lowercase","UPPERCASE"',
            '"test","TEST"'
        };

        String csv = String.join(lines, '\n');

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());

        List<String> csvItValue1 = csvIt.next();
        System.assertEquals('lowercase', csvItValue1.get(0));
        System.assertEquals('UPPERCASE', csvItValue1.get(1));

        List<String> csvItValue2 = csvIt.next();
        System.assertEquals('test', csvItValue2.get(0));
        System.assertEquals('TEST', csvItValue2.get(1));

        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest4() {
        List<String> lines = new List<String>{
            'lowercase,UPPERCASE',
            'test,TEST'
        };

        String csv = String.join(lines, '\r\n') + '\r\n';

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());

        List<String> csvItValue1 = csvIt.next();
        System.assertEquals('lowercase', csvItValue1.get(0));
        System.assertEquals('UPPERCASE', csvItValue1.get(1));

        List<String> csvItValue2 = csvIt.next();
        System.assertEquals('test', csvItValue2.get(0));
        System.assertEquals('TEST', csvItValue2.get(1));

        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest5() {
        List<String> lines = new List<String>{
            '"lowercase","UPPERCASE"',
            '"test","TEST"'
        };

        String csv = String.join(lines, '\n');

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());

        Integer i = 0;
        
        while(csvIt.hasNext() && i < 2) {
            csvIt.next();
            i++;
        }
        
        System.assertEquals(2, i);
        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest6() {
        List<String> lines = new List<String>{
            '"lowercase","UPPERCASE"',
            '"test ""quotes""","TEST ""QUOTES"""'
        };

        String csv = String.join(lines, '\r\n') + '\r\n';

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());

        List<String> csvItValue1 = csvIt.next();
        System.assertEquals('lowercase', csvItValue1.get(0));
        System.assertEquals('UPPERCASE', csvItValue1.get(1));

        List<String> csvItValue2 = csvIt.next();
        System.assertEquals('test "quotes"', csvItValue2.get(0));
        System.assertEquals('TEST "QUOTES"', csvItValue2.get(1));

        System.assertEquals(false, csvIt.hasNext());
    }

    @isTest
    public static void GRAXCSVIteratorTest7() {
        List<String> lines = new List<String>{
            '"lowercase"',
            '"test","TEST"'
        };

        String csv = String.join(lines, '\r\n');

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        System.assertEquals(true, csvIt.hasNext());
        
        csvIt.next();

        Boolean pass = false;

        try {
            csvIt.next();
        } catch (Exception e) {
            pass = true;
        }

        System.assert(pass);
    }

    @isTest
    public static void GRAXCSVIteratorTest8() {
        String csv = '\uFEFF';

        GRAXCSVIterator csvIt = new GRAXCSVIterator(csv);

        Boolean pass = false;

        try {
            GRAXCSVIterator.readCSVValue(csv);
        } catch (Exception e) {
            pass = true;
        }

        System.assert(pass);
    }

}