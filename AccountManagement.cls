// Updated:
//			08/21/2013 : KapiL Choudhary(JDC) : Update Code to Add logic for function "updateMDM" [T-166679].
//			09/06/2013 : Urminder(JDC) : update for unformat phone and unformat alt phone number [T-180475].
//          08/09/2016 : Leena Mandadapu : SMS-6156 : Revised Data Model
//			01/09/2017 : Aaron Briggs : SMS-6731 : Modified updateStagingObject to prevent sending MDM Blacklisted Phone Numbers
public with sharing class AccountManagement {
    
    public static void beforeInsert(List<Account> accountList){
        initFields(accountList);
    } 
    
    public static void beforeUpdate(List<Account> accountList, Map<Id, Account> oldAccountMap){
        updateFields(accountList);	
        updateLATAMLocations(accountList, oldAccountMap);
    }   
    
    public static void afterInsert(List<Account> accountList){} 
    
    public static void afterUpdate(List<Account> accountList, Map<Id, Account> oldAccountMap){
        // notify MDM when a contact has been updated
        updateStagingObject(accountList, oldAccountMap);	
    }   
    
    public static void updateStagingObject(List<Account> accountList, Map<Id, Account> oldAccountMap){
        list<Staging_Contact__c> staContactlist = new list<Staging_Contact__c>();
        
        for(Account acc :accountList){
            // MDM can be called only for contacts with MDM Contact ID
            if(acc.MDM_ID__pc != null && acc.MDM_ID__pc != ''){
                if(oldAccountMap.get(acc.id).PersonEmail != acc.PersonEmail 
                   || oldAccountMap.get(acc.id).Phone != acc.Phone){
                       Staging_Contact__c staCon = new Staging_Contact__c();
                       staCon.MDM_Contact_ID__c	= acc.MDM_ID__pc;
                       staCon.Email_Address__c = acc.PersonEmail;
                       staCon.Contact__c = acc.PersonContactId;
                       
                       //AB : 01/07/17 : Do Not Pass Phone Number to MDM if in Blacklist
                       if(!String.isBlank(acc.Phone)){
                           Pattern p = Pattern.compile('[^0-9]');
                           String numericPhone = p.matcher(acc.Phone).replaceAll('');
                           
                           system.debug('-----------------> numericPhone: '+numericPhone);
                           Phone_Number_Blacklist__c pnb = Phone_Number_Blacklist__c.getValues(numericPhone);
                           
                           if(pnb != null){
                               staCon.Phone__c = null;
                           } else{
                               staCon.Phone__c = acc.Phone_Unformatted__pc;
                           }
                       }
                       
                       staContactlist.add(staCon);
                   }
            }
        }
        
        if(!staContactlist.isEmpty()){
            try{
                insert staContactlist;
            }
            catch(Exception Ex){
                system.debug(':::::::::::::::::: After Update:::Exception Occurred:::::::::::::::::');
            }
        }
    } 
    
    public static void initFields(List<Account> accountList){
        for(Account a : accountList){
            if(a.Phone == null) {
                a.Phone_Unformatted__pc = null;	
            } else {
                a.Phone_Unformatted__pc = getUnformattedPhone(a.Phone);
            }
            
            if(a.Alt_Phone__pc == null) {
                a.Alt_Phone_Unformatted__pc = null;
            } else {
                a.Alt_Phone_Unformatted__pc = getUnformattedPhone(a.Alt_Phone__pc);
            }
        }
    }

    public static void updateFields(List<Account> accountList){
        
        Set<Id> addressIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Address__c> addressMap = new Map<Id, Address__c>();
        
        for(Account a : accountList){
            
            accountIds.add(a.Id);    				
            
            // put billing and shipping ids in addressIds
            if(a.Bill_To__pc <> null) {
                addressIds.add(a.Bill_To__pc);
            }else{
                a.PersonOtherStreet = '';
                a.PersonOtherCity = '';
                a.PersonOtherState = '';
                a.PersonOtherCountry = '';
                a.PersonOtherPostalCode = '';
            }
            
            if(a.ship_To__pc <> null) {
                addressIds.add(a.Ship_To__pc);
            }else{
                a.PersonMailingStreet = '';
                a.PersonMailingCity = '';
                a.PersonMailingState = '';
                a.PersonMailingCountry = '';
                a.PersonMailingPostalCode = '';
            }
            
        }
        
        // do a query with addressIds and put results in addressMap
        for(Address__c addr : [select Id, City__c, State__c, Country__c,Postal_Code__c,
                               Address_Line_1__c, Address_Line_2__c, Address_Line_3__c 
                               from Address__c 
                               where Id IN : addressIds]) {
                                   addressMap.put(addr.Id, addr);
                               }
        Address__c addr;
        
        for(Account a : accountList){
            
            // get address record for each address id and populate billing and shipping address fields
            if(addressMap.containsKey(a.Bill_To__pc)) {
                addr = addressMap.get(a.Bill_To__pc);
                a.PersonOtherStreet = '';
                a.PersonOtherStreet += addr.Address_Line_1__c == null ? '' : addr.Address_Line_1__c + ' ';
                a.PersonOtherStreet += addr.Address_Line_2__c == null ? '' : addr.Address_Line_2__c + ' ';
                a.PersonOtherStreet += addr.Address_Line_3__c == null ? '' : addr.Address_Line_3__c;
                a.PersonOtherCity = addr.City__c;
                a.PersonOtherState = addr.State__c;
                a.PersonOtherCountry = addr.Country__c;
                a.PersonOtherPostalCode = addr.Postal_Code__c;
            }
            
            if(addressMap.containsKey(a.Ship_To__pc)) {
                addr = addressMap.get(a.Ship_To__pc);
                a.PersonMailingStreet = '';
                a.PersonMailingStreet += addr.Address_Line_1__c == null ? '' : addr.Address_Line_1__c + ' ';
                a.PersonMailingStreet += addr.Address_Line_2__c == null ? '' : addr.Address_Line_2__c + ' ';
                a.PersonMailingStreet += addr.Address_Line_3__c == null ? '' : addr.Address_Line_3__c;
                a.PersonMailingCity = addr.City__c;
                a.PersonMailingState = addr.State__c;
                a.PersonMailingCountry = addr.Country__c;
                a.PersonMailingPostalCode = addr.Postal_Code__c;
            }
            
            if(a.Phone == null) {
                a.Phone_Unformatted__pc = null;	
            } else {
                a.Phone_Unformatted__pc = getUnformattedPhone(a.Phone);
            }
            
            if(a.Alt_Phone__pc == null) {
                a.Alt_Phone_Unformatted__pc = null;
            } else {
                a.Alt_Phone_Unformatted__pc = getUnformattedPhone(a.Alt_Phone__pc);
            }
        }
    }
    
    public static String getUnformattedPhone(String phone){
        return phone.replace('(','').replace(')','').replace('-','').replaceAll(' ','');
    }
    
    public static void updateLATAMLocations(List<Account> newList, map<Id, Account> oldMap) {
        list<Case> caseList = new list<Case>();
        map<String, list<LATAM_Country_ASC_Location_Mapping__c>> ascLocationMap = new map<String, list<LATAM_Country_ASC_Location_Mapping__c>>();
        map<Id, String> updatedContactCountryMap = new map<Id, String>();
        for(Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);
            if(acc.LATAM_Country__pc <> oldAcc.LATAM_Country__pc) {
                updatedContactCountryMap.put(acc.PersonContactId, acc.LATAM_Country__pc);
            }
        }
        
        for(LATAM_Country_ASC_Location_Mapping__c ascLoc : LATAM_Country_ASC_Location_Mapping__c.getAll().values()) {
            if(!ascLocationMap.containsKey(ascLoc.Country__c)) {
                ascLocationMap.put(ascLoc.Country__c, new list<LATAM_Country_ASC_Location_Mapping__c>());
            }
            ascLocationMap.get(ascLoc.Country__c).add(ascLoc);
        }
        
        //LM 08/09/2016: Updated select statement where clause to include the new Diagnosis-HD record type
        for(Case cs : [select LATAM_ASC_Locations__c, RecordTypeId, LATAM_Country__c, ContactId from Case 
                       where (RecordTypeId = : CaseManagement.RT_HARDWARE_NETWORKING_ID  OR RecordTypeId =: GeneralUtiltyClass.RT_DIAGNOSIS_HD_ID) and 
                       ContactId IN : updatedContactCountryMap.keySet()]) {
                           String country = updatedContactCountryMap.get(cs.ContactId);
                           cs.LATAM_ASC_Locations__c = '';
                           if(country <> null && ascLocationMap.containsKey(country)) {
                               for(LATAM_Country_ASC_Location_Mapping__c ascLoc : ascLocationMap.get(country)) {
                                   //System.assert(false,ascLoc.Name + '=========ascLoc.ASC_Location_URL__c============' + ascLoc.ASC_Location_URL__c);
                                   cs.LATAM_ASC_Locations__c = ' <a href="http://' + ascLoc.ASC_Location_URL__c + '" target="_blank">' + ascLoc.Name + '</a>';
                               }
                           }
                           caseList.add(cs);
                       }
        try {
            if(!caseList.isEmpty()) update caseList;
        } catch(Exception ex) {
            System.debug('__________ERROR WHILE UPDATING CASE RECORDS_____' + ex.getMessage());
        }
        
    }

}