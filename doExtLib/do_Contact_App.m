//
//  do_Contact_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Contact_App.h"
static do_Contact_App* instance;
@implementation do_Contact_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Contact_App alloc]init];
    return instance;
}
@end
