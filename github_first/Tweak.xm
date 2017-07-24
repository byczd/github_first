/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

#import "dlfcn.h"

static CFStringRef (*MGCopyAnswer)(CFStringRef);

%hook UIDevice

-(NSString *)uniqueIdentifier
{
NSLog(@"-------------hook-UIDevice-uniqueIdentifier");
    if (kCFCoreFoundationVersionNumber > 800)
    {
        NSLog(@"-------------UIDevice-uniqueIdentifier:version is >=iOS8");
//return (id)[[UIDevice currentDevice] _deviceInfoForKey:@"UniqueDeviceID"];
/*-------不能调用_deviceInfoForKey,这是私有api，在当前所用的xcode下的uikit的头文件中是没有的
即在/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.0.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIDevice.h中是没有的，所以编译的时候此处会出错
把从iphone5c的uikit里面导出来的，或从xcode的uikit.framework中导出来的私有UIDevice.h放到/opt/theos/vendor/include/UIKit/UIDevice+Pri.h也没有用，编译时：
/opt/theos/vendor/include/UIKit/NSObject.h:8:9: fatal error: 'SpringBoard-Structs.h' file
not found


--------和xcode里一样的写法不行：
        void *myGestalt=(void *)dlopen("/usr/lib/libMobileGestalt.dylib",RTLD_GLOBAL | RTLD_LAZY);
//need #import "dlfcn.h" //RTLD_NOW
        NSLog(@"--UIDevice-uniqueIdentifier:myGestalt-Address=%p",myGestalt);
        MGCopyAnswer=dlsym(myGestalt, "MGCopyAnswer");
        //编译的时候，上句会出错:
//assigning to 'CFStringRef (*)(CFStringRef)' (aka 'const __CFString
*(*)(const __CFString *)') from incompatible type 'void *'

        NSLog(@"--UIDevice-uniqueIdentifier:MGCopyAnswer-Address=%p",MGCopyAnswer);
        if (MGCopyAnswer)
        {
            NSLog(@"--UIDevice-uniqueIdentifier:hook successful!!!");
            return (id)MGCopyAnswer(CFSTR("UniqueDeviceID"));
        }
        else
        {
            NSLog(@"--UIDevice-uniqueIdentifier:dlopen libMobileGestalt.dylib error");
            return @"FFFFFFFFFFFFFFFFFFFFFFFFF";
        }
---------*/

//hook的时候需用下面这种方法:
        void *gestalt(dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY));
        MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
        return (id)MGCopyAnswer(CFSTR("UniqueDeviceID"));
    }
    else
    {
        NSLog(@"------------UIDevice-uniqueIdentifier:version is <iOS8");
        return %orig;
    }
}
%end

