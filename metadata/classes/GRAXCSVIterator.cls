/*****************************************************************************************
Name              : GRAXCSVIterator
Description       : This APEX Class contains functions to read a CSV file
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich        07/31/2017
2. Leandro Brunner          06/18/2018
******************************************************************************************/
global class GRAXCSVIterator implements Iterator<List<String>>, Iterable<List<String>> {
    public class MyException extends Exception {}
    public static final String COMMA = ',';
    public static final String CR = '\r';
    public static final String DQUOTE = '\"';
    public static final String LF = '\n';
    public static String CRLF = CR + LF;
    public static final String DQUOTEDQUOTE = DQUOTE + DQUOTE;
    public static final String UTF8_BOM = '\uFEFF';

    private String csvText;
    private Integer cellNumber;
    private Integer rowNumber = 0;
    private CSVValue csvValue;

    public GRAXCSVIterator(String csvText) {
        if(csvText.startsWith(UTF8_BOM)){
        	csvText = csvText.substring(UTF8_BOM.length());
        }

        if (!csvText.endsWith(CRLF)) {
          csvText = csvText + CRLF;
        }

        this.csvText = csvText;
    }

    global Boolean hasNext() {
        if(this.csvValue <> null) {
            return this.csvText.length() > this.csvValue.biteSize();
        }

        return this.csvText.length() > CRLF.length();
    }

    global List<String> next() {
        List<String> rowValues = new List<String>();

        csvValue = new CSVValue();

        Integer cellBiteSize = 0;
        Boolean isCRLF = false;
        while (!isCRLF) {
            csvValue = readCSVValue(this.csvText);

            rowValues.add(csvValue.value);

            isCRLF = csvValue.delimiter == CRLF || csvValue.delimiter == LF;

            cellBiteSize = csvValue.biteSize();

            if(cellBiteSize >= this.csvText.length()) {
                this.csvText = '';
            } else {
                this.csvText = this.csvText.subString(cellBiteSize);
            }
        }

        this.rowNumber++;
        System.debug(this.rowNumber);

        if(this.cellNumber == null) {
            this.cellNumber = rowValues.size();
        } else if(this.cellNumber <> rowValues.size()) {
            throw new MyException('An error was found when parsing the CSV file. Row Number: ' + String.valueOf(this.rowNumber));
        }

        return rowValues;
    }
    
    global Iterator<List<String>> Iterator() {
        return this;
    }

    /**
     * Returns the first String value read from a String representation of
     * data contained in an IETF RFC 4180-compliant CSV file.
     *
     * The data is assumed to be terminated with a CRLF.
     *
     * @param  data the textual CSV data in one long string
     * @return      the first CSV value read from <code>data</code>.
     *              null is returned if no value is discerned.
     */
    public static CSVValue readCSVValue(String data) {
        if(!data.endsWith(CRLF)){
        	throw new MyException('The data row does not end with a valid line break.');
        }
        
        CSVValue csvValue = new CSVValue();
        
        if (data.startsWith(DQUOTE)) {
          csvValue.enclosed = true;
          
            Integer searchIndex = 1;      // starting index to search
            Integer dquoteIndex = -1;     // index of DQUOTE
            Integer dquotesIndex = -1;    // index of DQUOTEDQUOTE
                            
            Boolean closerFound = false;
            
            while (!closerFound) {
                dquoteIndex = data.indexOf(DQUOTE, searchIndex);
                
                dquotesIndex = data.indexOf(DQUOTEDQUOTE,
                        searchIndex);
                
                //System.debug('Data: ' + data);
                if (dquoteIndex == dquotesIndex && dquoteIndex != -1) {
                    searchIndex = dquotesIndex
                            + DQUOTEDQUOTE.length();
                }
                else {
                    closerFound = true;
                }
            }
            
            csvValue.value = data.substring(
                    DQUOTE.length(), dquoteIndex)
                            .replaceAll(DQUOTEDQUOTE, DQUOTE);
            
            Integer commaIndex = data.indexOf(COMMA, dquoteIndex);
            Integer crlfIndex = data.indexOf(CRLF, dquoteIndex);
            Integer lfIndex = data.indexOf(LF, dquoteIndex);
            
            if (commaIndex != -1 && commaIndex < lfIndex && commaIndex < crlfIndex) {
                csvValue.delimiter = COMMA;
            }
            else {
                csvValue.delimiter = lfIndex < crlfIndex ? LF : CRLF;
            }
        }
        else {
          csvValue.enclosed = false;
          
            Integer commaIndex = data.indexOf(COMMA);
            Integer crlfIndex = data.indexOf(CRLF);
            Integer lfIndex = data.indexOf(LF);
            
            if (commaIndex != -1 && commaIndex < lfIndex && commaIndex < crlfIndex) {
                csvValue.value = data.substring(0, commaIndex);
                csvValue.delimiter = COMMA;
            }
            else {
                csvValue.value = data.substring(0, crlfIndex);
                csvValue.delimiter = lfIndex < crlfIndex ? LF : CRLF;
            }
        }
        
        //System.debug('Returning: ' + csvValue);
        
        return csvValue;
    }
    
    /**
     * CSVValue is a class structure containing information about a CSV
     * value that was read from a CSV file, including such information as
     * whether the value was encapsulated in double-quotes.
     */
    public class CSVValue {
        /**
         * The field value that was read from the CSV file.
         */
        public String value;
        
        /**
         * Whether the value was surrounded by double-quotes.
         */
        public Boolean enclosed;
        
        /**
         * The comma or CRLF delimiter that identified the end of the CSV value.
         */
        public String delimiter;
        
        /**
         * Default constructor, setting all members to null.
         */
        public CSVValue() {
            this(null, null, null);
        }
        
        /**
         * Constructor.
         *
         * @param value     the field value
         * @param enclosed  whether the value was surrounded by double-quotes
         * @param delimiter the delimiter that identified the end
         *                  of the CSV value
         */
        public CSVValue(String value, Boolean enclosed, String delimiter) {
            this.value = value;
            this.enclosed = enclosed;
            this.delimiter = delimiter;
        }
        
        /**
         * Returns the number of characters to remove from the data
         * String which produced the CSVValue in order to reach the next
         * value in the data String.
         */
        public Integer biteSize() {
          Integer biteSize = value
                 .replaceAll(DQUOTE, DQUOTEDQUOTE).length()
                         + delimiter.length();
          
          if (enclosed) {
            biteSize += DQUOTE.length() * 2;
          }
          
          //System.debug('biteSize: ' + biteSize);
          
          return biteSize;
        }
        
    }
}