//
//  do_Contact_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Contact_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonhelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import <AddressBook/AddressBook.h>

@interface do_Contact_SM()
@property (nonatomic,strong)NSMutableArray *filterArray;
@end

@implementation do_Contact_SM
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
//异步
- (instancetype)init
{
    if (self = [super init]) {
        [self loadPerson];
    }
    return self;
}
- (void)addData:(NSArray *)parms
{
    @synchronized(self) {
        ABAddressBookRef addressBookRef = ABAddressBookCreate();
        if (![self policyValidate:addressBookRef]) {
            return;
        }
        //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        //参数字典_dictParas
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        NSString *_callbackName = [parms objectAtIndex:2];
        //回调函数名_callbackName
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        //_invokeResult设置返回值
        //自己的代码实现
        NSArray *addressbooks = [doJsonHelper GetOneArray:_dictParas :@"paras"];
        NSMutableArray *recordIDs = [[NSMutableArray alloc]initWithCapacity:addressbooks.count];
        for (NSDictionary *bookDict in addressbooks) {
            NSString *abName = [doJsonHelper GetOneText:bookDict :@"name" :@""];
            NSString *abPhone = [doJsonHelper GetOneText:bookDict :@"phone" :@""];
            NSString *abEmail = [doJsonHelper GetOneText:bookDict :@"email" :@""];
            //创建一条记录
            ABRecordRef recordRef= ABPersonCreate();
            if (![abName isEqualToString:@""]) {
                ABRecordSetValue(recordRef, kABPersonLastNameProperty, (__bridge CFTypeRef)(abName), NULL);
            }
            if (![abPhone isEqualToString:@""]) {
                ABMutableMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(phones,(__bridge_retained CFStringRef)abPhone, kABWorkLabel, NULL);
                
                ABRecordSetValue(recordRef, kABPersonPhoneProperty, phones,NULL);
            }
            if (![abEmail isEqualToString:@""]) {
                ABMutableMultiValueRef emails = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(emails,(__bridge_retained CFStringRef)abEmail, kABWorkLabel, NULL);
                ABRecordSetValue(recordRef, kABPersonEmailProperty, emails, NULL);
            }
            ABAddressBookAddRecord(addressBookRef, recordRef, NULL);
            CFRelease(recordRef);
            //保存通讯录，提交更改
            ABAddressBookSave(addressBookRef, NULL);
            ABRecordID recordID = ABRecordGetRecordID(recordRef);
            [recordIDs addObject:@(recordID)];
        }
        CFRelease(addressBookRef);
        [_invokeResult SetResultArray:recordIDs];
        [_scritEngine Callback:_callbackName :_invokeResult];
    }
    
}
- (void)deleteData:(NSArray *)parms
{
    @synchronized(self) {
        ABAddressBookRef addressBookRef = nil;
        addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        if (![self policyValidate:addressBookRef]) {
            return;
        }
        //判断当前系统的版本
        //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        //参数字典_dictParas
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        
        NSArray *addressbooks = [doJsonHelper GetOneArray:_dictParas :@"ids"];
        BOOL result = YES;
        CFErrorRef *error;
        ABRecordRef recordRef = NULL;
        for (NSString *bookID in addressbooks)
        {
            recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef,[bookID intValue]);
            if (recordRef == NULL) {
                continue;
            }
            result = ABAddressBookRemoveRecord(addressBookRef, recordRef, error);//删除
            if (!result) {
                break;
            }
            //            CFRelease(recordRef);
        }
        //删除所有
        if (!addressbooks) {
            CFArrayRef allLinkPeople = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            //获取联系人总数
            CFIndex number = ABAddressBookGetPersonCount(addressBookRef);
            
            for (NSInteger i=0; i<number; i++)
            {
                ABRecordRef  people = CFArrayGetValueAtIndex(allLinkPeople, i);
                if (people == NULL) {
                    continue;
                }
                result = ABAddressBookRemoveRecord(addressBookRef, people, error);//删除
                if (!result) {
                    break;
                }
            }
        }
        CFErrorRef error1;
        
        ABAddressBookSave(addressBookRef, &error1);//删除之后提交更改
        NSString *_callbackName = [parms objectAtIndex:2];
        //回调函数名_callbackName
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        //_invokeResult设置返回值
        [_invokeResult SetResultBoolean:result];
        //自己的代码实现
        [_scritEngine Callback:_callbackName :_invokeResult];
        //        CFRelease(recordRef);
        CFRelease(addressBookRef);
    }
}
- (void)getData:(NSArray *)parms
{
    @synchronized(self) {
        //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        //参数字典_dictParas
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        
        NSString *_callbackName = [parms objectAtIndex:2];
        NSString *value = [doJsonHelper GetOneText:_dictParas :@"value" :@""];
        NSArray *types = [doJsonHelper GetOneArray :_dictParas :@"types"];
        if (!types) {
            types = [doJsonHelper GetOneArray:[doJsonHelper GetOneNode:_dictParas :@"value"] :@"types"];
            value = @"";
        }
        NSString *factor;
        //回调函数名_callbackName
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        //_invokeResult设置返回值
        //自己的代码实现
        
        NSMutableArray *resultArray = [self getAllPerson];
        @try {
            if ([value isEqualToString:@""]||!value) {
                [_invokeResult SetResultArray:resultArray];
                [_scritEngine Callback:_callbackName :_invokeResult];
            }
            else
            {
                if (types.count == 0)
                {
                    factor  = [NSString stringWithFormat:@"name CONTAINS[d]\"%@\" OR SELF  CONTAINS[d]\"%@\" OR SELF CONTAINS[d]\"%@\"",value,value,value];
                }
                else if(types.count == 1)
                {
                    factor  = [NSString stringWithFormat:@"%@  CONTAINS[d]\"%@\"",[types objectAtIndex:0],value];
                }
                else if (types.count == 2)
                {
                    factor  = [NSString stringWithFormat:@"%@ CONTAINS[d]\"%@\" OR %@  CONTAINS[d]\"%@\"",[types objectAtIndex:0],[types objectAtIndex:1],value,value];
                }
                else
                {
                    factor  = [NSString stringWithFormat:@"name CONTAINS[d]\"%@\" OR phone  CONTAINS[d]\"%@\" OR email CONTAINS[d]\"%@\"",value,value,value];
                }
                NSPredicate *pre = [NSPredicate predicateWithFormat:factor];
                NSArray *tempArr = [self.filterArray filteredArrayUsingPredicate:pre];
                NSMutableArray *results = [NSMutableArray array];
                for (int i = 0; i < resultArray.count; i ++) {
                    NSDictionary *dict1 = [resultArray objectAtIndex:i];
                    NSString *id1 = [dict1 objectForKey:@"id"];
                    NSString *id2;
                    for (int j = 0; j < tempArr.count; j ++) {
                        NSDictionary *dict2 = [tempArr objectAtIndex:j];
                        id2 = [dict2 objectForKey:@"id"];
                        if ([id1 isEqualToString:id2]) {
                            [results addObject:dict1];
                            break;
                        }
                    }
                }
                [_invokeResult SetResultArray:results];
                [_scritEngine Callback:_callbackName :_invokeResult];
            }
        }
        @catch (NSException *exception) {
            [[doServiceContainer Instance].LogEngine WriteError:exception :@"GetData方法参数错误"];
            [_invokeResult SetResultArray:resultArray];
            [_scritEngine Callback:_callbackName :_invokeResult];
        }
        @finally {
            
        }
    }
}
- (void)getDataById:(NSArray *)parms
{
    @synchronized(self) {
        ABAddressBookRef addressBookRef = ABAddressBookCreate();
        if (![self policyValidate:addressBookRef]) {
            return;
        }
        //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        //参数字典_dictParas
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        //自己的代码实现
        
        NSString *_callbackName = [parms objectAtIndex:2];
        NSString *ID = [doJsonHelper GetOneText:_dictParas :@"id" :@""];
        ABRecordRef people = ABAddressBookGetPersonWithRecordID(addressBookRef,[ID intValue]);
        //获取当前联系人名字
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(people, kABPersonLastNameProperty));
        //获取emails
        NSMutableArray * emailArr = [[NSMutableArray alloc]init];
        //获取当前联系人的邮箱 注意是数组
        ABMultiValueRef emails= ABRecordCopyValue(people, kABPersonEmailProperty);
        for (NSInteger j=0; j<ABMultiValueGetCount(emails); j++) {
            [emailArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(emails, j))];
        }
        //获取当前联系人的电话 数组
        NSMutableArray * phoneArr = [[NSMutableArray alloc]init];
        ABMultiValueRef phones= ABRecordCopyValue(people, kABPersonPhoneProperty);
        for (NSInteger j=0; j<ABMultiValueGetCount(phones); j++) {
            [phoneArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j))];
        }
        NSMutableDictionary *resNode = [NSMutableDictionary dictionary];
        if (people) {
            [resNode setObject:ID forKey:@"id"];
            if (lastName) {
                [resNode setObject:lastName forKey:@"name"];
            }
            else
            {
                [resNode setObject:@"" forKey:@"name"];
            }
            [resNode setObject:phoneArr forKey:@"phone"];
            [resNode setObject:emailArr forKey:@"emails"];
        }
        
        
        //回调函数名_callbackName
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        //_invokeResult设置返回值
        [_invokeResult SetResultNode:resNode];
        [_scritEngine Callback:_callbackName :_invokeResult];
        CFRelease(addressBookRef);
    }
    
}
- (void)updateData:(NSArray *)parms
{
    @synchronized(self) {
        ABAddressBookRef addressBookRef = ABAddressBookCreate();
        if (![self policyValidate:addressBookRef]) {
            return;
        }
        //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
        NSDictionary *_dictParas = [parms objectAtIndex:0];
        //参数字典_dictParas
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        NSString *callBackName = [parms objectAtIndex:2];
        //自己的代码实现
        NSString *ID = [doJsonHelper GetOneText:_dictParas :@"id" :@""];
        
        NSDictionary *paraDict = [doJsonHelper GetOneNode :_dictParas :@"paras"];
        ABRecordRef recordsRef = ABAddressBookGetPersonWithRecordID(addressBookRef,[ID intValue]);
        NSString *name = [doJsonHelper GetOneText:paraDict :@"name" :@""];
        NSString *phone = [doJsonHelper GetOneText:paraDict :@"phone" :@""];
        NSString *email = [doJsonHelper GetOneText:paraDict :@"email" :@""];
        if (recordsRef) {
            if (![name isEqualToString:@""]) {
                ABRecordSetValue(recordsRef, kABPersonLastNameProperty, (__bridge CFTypeRef)(name), NULL);
            }
            if (![phone isEqualToString:@""]) {
                ABMutableMultiValueRef phones = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(phones,(__bridge_retained CFStringRef)phone, kABWorkLabel, NULL);
                ABRecordSetValue(recordsRef, kABPersonPhoneProperty, phones,NULL);
            }
            if (![email isEqualToString:@""]) {
                ABMutableMultiValueRef emails = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(emails,(__bridge_retained CFStringRef)email, kABWorkLabel, NULL);
                ABRecordSetValue(recordsRef, kABPersonEmailProperty,emails, NULL);
            }
        }
        CFErrorRef error;
        BOOL result =  ABAddressBookSave(addressBookRef,&error);
        CFRelease(addressBookRef);
        if (!recordsRef) {
            result = NO;
        }
        doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
        [invokeResult SetResultBoolean:result];
        [_scritEngine Callback:callBackName :invokeResult];
    }
}
/**
 *  得到所有联系人
 */
- (NSMutableArray *)getAllPerson
{
    self.filterArray = [NSMutableArray array];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (![self policyValidate:addressBookRef]) {
        return nil;
    }
    CFArrayRef allLinkPeople = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    //获取联系人总数
    CFIndex number = ABAddressBookGetPersonCount(addressBookRef);
    //进行遍历
    NSMutableArray *allPersons = [NSMutableArray array];
    for (NSInteger i=0; i<number; i++)
    {
        NSMutableDictionary *personDic = [NSMutableDictionary dictionary];
        NSMutableDictionary *filterDict = [NSMutableDictionary dictionary];
        ABRecordRef  people = CFArrayGetValueAtIndex(allLinkPeople, i);
        int recordID = ABRecordGetRecordID(people);
        //获取当前联系人名字
        NSString*firstName=(__bridge NSString *)(ABRecordCopyValue(people, kABPersonFirstNameProperty));
        NSString*lastName=(__bridge NSString *)(ABRecordCopyValue(people, kABPersonLastNameProperty));
        
        if (!firstName) {
            firstName = @"";
        }
        if (!lastName) {
            lastName = @"";
        }
        lastName = [NSString stringWithFormat:@"%@%@",lastName,firstName];
        //获取emails
        NSMutableArray * emailArr = [[NSMutableArray alloc]init];
        //获取当前联系人的邮箱 注意是数组
        ABMultiValueRef emails= ABRecordCopyValue(people, kABPersonEmailProperty);
        NSMutableString *emailStr = [[NSMutableString alloc]init];
        for (NSInteger j=0; j<ABMultiValueGetCount(emails); j++) {
            NSString *emailTemp = [NSString stringWithFormat:@"%@&",(__bridge NSString*)(ABMultiValueCopyValueAtIndex(emails,j))];
            [emailStr appendString:emailTemp];
            
            [emailArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(emails, j))];
        }
        //获取当前联系人的电话 数组
        NSMutableArray * phoneArr = [[NSMutableArray alloc]init];
        ABMultiValueRef phones= ABRecordCopyValue(people, kABPersonPhoneProperty);
        NSMutableString *phoneStr = [[NSMutableString alloc]init];
        for (NSInteger j=0; j<ABMultiValueGetCount(phones); j++) {
            NSString *phoneTemp = [NSString stringWithFormat:@"%@*",(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j))];
            [phoneStr appendString:phoneTemp];
            [phoneArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j))];
        }
        [personDic setObject:[NSString stringWithFormat:@"%d",recordID] forKey:@"id"];
        [filterDict setObject:[NSString stringWithFormat:@"%d",recordID] forKey:@"id"];
        if (lastName) {
            [personDic setObject:lastName forKey:@"name"];
            [filterDict setObject:lastName forKey:@"name"];
        }
        else
        {
            [personDic setObject:@"" forKey:@"name"];
            [filterDict setObject:@"" forKey:@"name"];
        }
        [personDic setObject:phoneArr forKey:@"phone"];
        [personDic setObject:emailArr forKey:@"email"];
        
        [filterDict setObject:phoneStr forKey:@"phone"];
        [filterDict setObject:emailStr forKey:@"email"];
        
        [allPersons addObject:personDic];
        [self.filterArray addObject:filterDict];
    }
    CFRelease(addressBookRef);
    return allPersons;
}


- (void)loadPerson
{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (![self policyValidate:addressBookRef]) {
        return;
    }
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error){
            
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            NSException *exception = [NSException exceptionWithName:@"Contact" reason:@"没有权限访问通讯录" userInfo:nil];
            [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
            doInvokeResult* _result = [[doInvokeResult alloc]init];
            [_result SetException:exception];
        });
    }
    CFRelease(addressBookRef);
}
- (BOOL)policyValidate:(ABAddressBookRef)addressBookRef
{
    if (!addressBookRef) {
        NSException *exception = [NSException exceptionWithName:@"Contact" reason:@"没有权限访问通讯录" userInfo:nil];
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
        return NO;
    }
    return YES;
}
@end
