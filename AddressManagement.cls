/**********************************************************************************************************************
// Updated :
//      August 21,2013 : KapiL Choudhary(JDC) : Update Code to Add logic for function "updateMDM" [T-166679].
//      August 30, 2013  KapiL Choudhary(JDC) : Updated for the Task T-179024.
//      August 30, 2013  KapiL Choudhary(JDC) : Craete a new function "fetchTwoLetterCode" for the Task T-182702.

        04/14/2015 : Leena Mandadapu : SMS-835 : Updated to add logic for Block Address Check box field.
***********************************************************************************************************************/

public with sharing class AddressManagement {
    //CM Improve code coverage SMS-4770
    public static boolean isTestException = false;
    public class myException extends Exception {} 
    
    public static void beforeInsert(List<Address__c> addressList){
    updateFields(addressList);   
    } 

    public static void beforeUpdate(List<Address__c> addressList, Map<Id, Address__c> oldAddressMap){
    updateFields(addressList);  
  }   

    public static void afterInsert(List<Address__c> addressList){
      
      // Notify MDM when there's a new address
      updateStagingObject(addressList);
      updateObjects(addressList);
      
      //LM 04/14/2015: check if the block Address field is check. If checked = true then call method to insert into Blocked Address object
      Address__c oldAddress;
      Map<Id,Address__c>blockedAddressUpdMap = new Map<Id,Address__c>();
      system.debug('<<<<<<<< Address List >>>>>>>>>'+addressList);
      
      for(Address__c addrRec : addressList) {
      	system.debug('<<<<<<< Address Record >>>>>>>'+addrRec);
      	system.debug('<<<<<<< Block Address Field Value >>>>>>>'+addrRec.Block_Address__c); 
      	if(addrRec.Block_Address__c) {
      	   //call method to add and Block the record in the Blocked Address Object	
      	   blockedAddressUpdMap.put(addrRec.Id,addrRec);
      	} 
      }
      
      if(blockedAddressUpdMap <> null && blockedAddressUpdMap.keyset().size()>0) {
      	 system.debug('<<<<<<<<<< Blocked Address Map =>>>>>>>>>>>>'+blockedAddressUpdMap);
      	 addressBlockUnblock(blockedAddressUpdMap);
      }
    } 

    public static void afterUpdate(List<Address__c> addressList, Map<Id, Address__c> oldAddressMap){
      //LM 04/14/2015: check if the block Address field is check. If checked = true then call method to insert into Blocked Address object
      Address__c oldAddress;
      Map<Id,Address__c>blockedAddressUpdMap = new Map<Id,Address__c>();
      system.debug('<<<<<<<< Address List >>>>>>>>>'+addressList);
      system.debug('<<<<<<<< Old Address Map >>>>>>'+oldAddressMap);
      
      for(Address__c addrRec : addressList) {
      	oldAddress = oldAddressMap.get(addrRec.Id);
      	system.debug('<<<<<<< Address Record >>>>>>>'+addrRec);
      	system.debug('<<<<<<< Block Address Field Value >>>>>>>'+addrRec.Block_Address__c); 
      	if(addrRec.Block_Address__c <> null && oldAddress.Block_Address__c <> addrRec.Block_Address__c) {
      	   //call method to add and Block the record in the Blocked Address Object	
      	   blockedAddressUpdMap.put(addrRec.Id,addrRec);
      	} 
      }
      
      if(blockedAddressUpdMap <> null && blockedAddressUpdMap.keyset().size()>0) {
      	 system.debug('<<<<<<<<<< Blocked Address Map =>>>>>>>>>>>>'+blockedAddressUpdMap);
      	 addressBlockUnblock(blockedAddressUpdMap);
      }
  }   
  
  //LM 04/15/2015 : Created for Retailer service case creation blocking functionality.
  public static void addressBlockUnblock(Map<Id,Address__c> blockedAddressUpdMap){
  
  	 List<Blocked_Address__c> updateblockedaddrList = new List<Blocked_Address__c>(); // for updating the records
  	 Map<Id,Blocked_Address__c> existingRecordsMap = new Map<Id,Blocked_Address__c>(); //for storing the existing records
  	 system.debug('<<<<<<<Blocked Address Map = >>>>>>>>>>'+blockedAddressUpdMap);
  	 
  	 for(Blocked_Address__c existingRecords : [SELECT Id, Status__c, AddressLookup__c, Address_Line_1__c, Address_Line_2__c,Postal_Code__c FROM Blocked_Address__c]) {
  	     existingRecordsMap.put(existingRecords.AddressLookup__c,existingRecords);                                  	
  	 }
  	 system.debug('<<<<<<<<< Existing Records = >>>>>>>>>>>'+existingRecordsMap);
  	 
  	 for(string addrLookupId : blockedAddressUpdMap.keyset()){
  	 	  if(existingRecordsMap.keyset().size()>0 && existingRecordsMap.containsKey(addrLookupId)) {	
  	 	      system.debug('<<<<<<<<< Existing Record in blocked Address =>>>>>>>>'+existingRecordsMap.get(addrLookupId));
  	 	      system.debug('<<<<<<<<< Existing record Id =>>>>>>>>>>>'+existingRecordsMap.get(addrLookupId).Id);
  	 	      system.debug('<<<<<<<<< Blocked Address Map Key value=>>>>>>>>'+blockedAddressUpdMap.get(addrLookupId).Block_Address__c);
  	 	      Blocked_Address__c blockedaddrObj = new Blocked_Address__c(Id=existingRecordsMap.get(addrLookupId).Id,
  	 	                                                                 status__c=blockedAddressUpdMap.get(addrLookupId).Block_Address__c ? 'Blocked' : 'Unblocked' 
  	 	                                                                );
  	 	      updateblockedaddrList.add(blockedaddrObj);
  	 	  } else if(blockedAddressUpdMap.get(addrLookupId).Block_Address__c) {
  	 	  	  system.debug('<<<<<<<<< Blocked Address Map Key =>>>>>>>>'+blockedAddressUpdMap.get(addrLookupId));
  	 	  	  Blocked_Address__c blockedaddrObj = new Blocked_Address__c(AddressLookup__c=addrLookupId,
  	 	  	                                                             status__c=blockedAddressUpdMap.get(addrLookupId).Block_Address__c ? 'Blocked' : 'Unblocked',
  	 	  	                                                             Address_Line_1__c = (blockedAddressUpdMap.get(addrLookupId).Address_Line_1__c.tolowercase()).replaceAll('[^a-zA-Z0-9]',''),
  	 	  	                                                             Address_Line_2__c = blockedAddressUpdMap.get(addrLookupId).Address_Line_2__c <> null ? (blockedAddressUpdMap.get(addrLookupId).Address_Line_2__c.tolowercase()).replaceAll('[^a-zA-Z0-9]','') : 'blank',
  	 	  	                                                             Postal_Code__c = blockedAddressUpdMap.get(addrLookupId).Postal_Code__c.normalizeSpace().tolowercase()
  	 	  	                                                             );
  	 	      updateblockedaddrList.add(blockedaddrObj);
  	 	  }	  
  	 	} 	
  	 system.debug('<<<<<<<Blocked Address to Upsert = >>>>>>>>>>'+updateblockedaddrList);
  	
  	 //Upsert the records into Block Address Object
     if(updateblockedaddrList <> null && updateblockedaddrList.size() > 0) {
      try {
          //CM
          if (test.isRunningTest() && isTestException){
              throw new myException('test block address code coverage');
          }
  	     upsert updateblockedaddrList;
      }catch (Exception dml) {
      	    ExceptionHandler.logException(dml);
            Apex_Log__c apexlog = new Apex_Log__c();
            apexlog.Message__c = dml.getStackTraceString();
            apexlog.Exception_Cause__c = String.valueOf(dml.getLineNumber());
            apexlog.Class_Name__c = 'Address Management';
            apexlog.method_name__c = 'addressBlockUnblock';
            apexlog.Exception_Type__c = dml.getTypeName();
            apexlog.Exception_Message__c = dml.getMessage();
            insert apexlog;
      }  
     } //else - no action
  }
  
  public static String getAddressName(Address__c address){
    
    if(address==null){
      return null;
    }
     
     boolean addressExists=false;

     
      String addressName = '';
      
      if(address.Address_Line_1__c != null && address.Address_Line_1__c != ''){
        addressName = address.Address_Line_1__c;
        addressExists = true;
      }
      
      if(address.City__c != null && address.City__c != ''){
        
        if(addressExists){
          addressName += ', ' + address.City__c;
        }else{
        addressName += address.City__c;
        }
        
        addressExists = true;
      }
      
      if(address.State__c != null && address.State__c != ''){

      if(addressExists){
        addressName += ', ' + address.State__c;
      }else{
        addressName += address.State__c;
      }
      
        addressExists = true;
 
        }
        
    if(address.Country__c != null && address.Country__c != ''){
      
      if(!addressExists){
        addressName += address.Country__c;
      }
      
      addressExists = true;
      
      }
        
        return addressName;
  }

  public static void updateFields(List<Address__c> addressList){
      
      
      for(Address__c address :addressList){  
        
        address.Name = getAddressName(address);    
      
        if(address.Country__c == null){
          address.X2_Letter_Country_Code__c = '';  
        }else{
          address.X2_Letter_Country_Code__c = fetchTwoLetterCode(address.Country__c);  
        }//end-if
        
      }//end-for
  }  
  
    private static string fetchTwoLetterCode(string countryCode){
      
      for(Country__c crt : Country__c.getall().values()){
        if(crt.X3_Letter_Code__c == countryCode){
          return crt.X2_Letter_Code__c;
        }else if(crt.Name == countryCode){
          return crt.X2_Letter_Code__c;
        }else if(crt.X2_Letter_Code__c == countryCode){
          return crt.X2_Letter_Code__c;
        }

      }//end-for
      
      return '';
    }
    
    private static Staging_Address__c createStagingAddress(Address__c address ){
      
      Staging_Address__c stAddmgt = new Staging_Address__c();
      
    stAddmgt.Address_1__c     = address.Address_Line_1__c;
    stAddmgt.Address_2__c    = address.Address_Line_2__c;
    stAddmgt.Address_3__c     = address.Address_Line_3__c;
    stAddmgt.City__c         = address.City__c;
    stAddmgt.Country_Code__c  = address.Country__c;
    stAddmgt.Province_Code__c = address.State__c;
    stAddmgt.Zip_Code__c      = address.Postal_Code__c;
    stAddmgt.Address_Type__c  = address.Address_Type__c;
    
    if(address.MDM_ID__c==null){
      stAddmgt.MDM_Address_ID__c = 'NEW-RECORD';    
    }else{
      stAddmgt.MDM_Address_ID__c = address.MDM_ID__c;
      }
      
    stAddmgt.MDM_Contact_ID__c = address.MDM_Contact_ID__c;
    stAddmgt.Address__c = address.Id;
             
      return stAddmgt;
    }
   
    private static void insertStagingAddress(list<Staging_Address__c> staAddMgmtlist){
      
      if(!staAddMgmtlist.isEmpty()){
        
        try{          
          insert staAddMgmtlist;
        }
        catch(Exception Ex){
          system.debug(':::::::::::::::::::::Exception Occurred:::::::::::::::::');
        }
      }
    }

    public static void UpdateObjects(List<Address__c> addressList){

    List<Id> contactIds = new List<Id>();
    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    List<Contact> updateContactList = new List<Contact>();
    

      for(Address__c address :addressList){
    
      if (address.Consumer__c != null){
        contactIds.add(address.Consumer__c);
      }//end-if
    
      }//end-for
      
      
      if(contactIds.size()>0){
        for(Contact con: [Select Id, Bill_To__c, Ship_To__c from Contact where id in: contactIds]){
        
          contactMap.put(con.Id, con);    
          
        }//end-for
      }//end-if
      
      Contact currentContact;
      boolean updateContact;
      Set<Id> consumerIds = new Set<Id>();
      for(Address__c address :addressList){
        
      currentContact = contactMap.get(address.Consumer__c);
      updateContact = false;
       
      if (currentContact != null && address.Address_Type__c == 'Billing'){
        
        currentContact.Bill_To__c = address.Id;
        updateContact = true;
         
      }//end-if

      if (currentContact != null && address.Address_Type__c == 'Shipping'){

        currentContact.Ship_To__c = address.Id;
        updateContact = true;

      }//end-if


      if (currentContact != null && currentContact.Bill_To__c == null){
        
        currentContact.Bill_To__c = address.Id;
        updateContact = true;
         
      }//end-if

      if (currentContact != null && currentContact.Ship_To__c == null){

        currentContact.Ship_To__c = address.Id;
        updateContact = true;

      }//end-if

      if(updateContact && !consumerIds.contains(currentContact.Id)){
        updateContactList.add(currentContact);
        consumerIds.add(currentContact.Id);
      }
      }//end-for

    if(updateContactList.size()>0){
      update updateContactList;
    }
    }
    
    public static void updateStagingObject(List<Address__c> addressList){
      
      list<Staging_Address__c> staAddMgmtlist = new list<Staging_Address__c>();
      
      
      for(Address__c address :addressList){
    
       // MDM can be called only for address with MDM Contact ID 
      
        if(address.MDM_Contact_ID__c != null && address.MDM_Contact_ID__c != ''){ 
          
          // DO NOT CALL MDM if there's a MDM ID because the record was created from consumer lookup or consumer refresh
          if(address.MDM_ID__c == null){
          staAddMgmtlist.add(createStagingAddress(address));  
          }
        }
      }
      
      insertStagingAddress(staAddMgmtlist);
    }     
}