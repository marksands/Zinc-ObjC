//
//  AppDelegate.m
//  ZincBundleTest
//
//  Created by Andy Mroczkowski on 12/2/11.
//  Copyright (c) 2011 MindSnacks. All rights reserved.
//

#import "AppDelegate.h"

//#import "ViewController.h"
#import "BundleListViewController.h"
#import "ZincRepo.h"
#import "ZincRepo+Private.h"
#import "ZincEvent.h"
#import "ZincUtils.h"
#import "UIImage+Zinc.h"

@interface AppDelegate()
@property (strong, nonatomic) BundleListViewController *viewController;
@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void) zincRepo:(ZincRepo*)repo didReceiveEvent:(ZincEvent*)event
{   
    NSLog(@"%@", event);
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (void) testBundleImageLoading
{
    // NOTE: this should be a unit test, but they don't execute in the same 
    // evironment so I'm adding a little something here
    
    NSError* error = nil;
    
    NSString* dstDir = [ZincGetApplicationDocumentsDirectory() stringByAppendingPathComponent:@"testimages"];
    [[NSFileManager defaultManager] removeItemAtPath:dstDir error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert(error==nil, @"failed to create dir");
    
    for (NSString* file in [NSArray arrayWithObjects:@"sphalerite.jpg", @"sphalerite@2x.jpg", nil]) {
        if (![[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:file ofType:nil] toPath:[dstDir stringByAppendingPathComponent:file] error:&error]) {
            NSLog(@"error: %@", error);
            abort();
        }
    }
         
    NSBundle* bundle = [NSBundle bundleWithPath:dstDir];
    UIImage* image1 = [UIImage imageNamed:@"sphalerite.jpg" inBundle:bundle];
    NSAssert(image1, @"image1 is nil");
    NSLog(@"image1: %@", NSStringFromCGSize(image1.size));
    
    UIImage* image2 = [UIImage imageNamed:@"sphalerite@2x.jpg" inBundle:bundle];
    NSAssert(image2, @"image1 is nil");
    NSLog(@"image2: %@", NSStringFromCGSize(image2.size));

    if ([UIScreen mainScreen].scale == 2.0f) {
        NSAssert(image1.size.width == image2.size.width, @"retina wrong");
        
    } else {
        NSAssert(image1.size.width*2 == image2.size.width, @"non-retina wrong");
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    [self testBundleImageLoading];
    
    NSError* error = nil;
    
    NSURL* repoURL = [NSURL fileURLWithPath:
                      [AMGetApplicationDocumentsDirectory()
                       stringByAppendingPathComponent:@"zinc"]];
    
    NSLog(@"repo path: %@", [repoURL path]);
    
    ZincRepo* repo = [[ZincRepo repoWithURL:repoURL error:&error] retain];
    repo.delegate = self;
    
    [repo resumeAllTasks];

    [repo bootstrapBundleWithId:@"com.mindsnacks.demo1.cats" fromDir:[[NSBundle mainBundle] resourcePath] andTrack:@"master" waitUntilDone:YES];
    [repo bootstrapBundleWithId:@"com.mindsnacks.demo1.sphalerites" fromDir:[[NSBundle mainBundle] resourcePath] andTrack:@"master" waitUntilDone:YES];

    [repo addSourceURL:[NSURL URLWithString:@"https://s3.amazonaws.com/zinc-demo/com.mindsnacks.demo1/"]];

    BundleListViewController* bundleListViewController = [[[BundleListViewController alloc] initWithRepo:repo] autorelease];
    
    UINavigationController* nc = [[[UINavigationController alloc] initWithRootViewController:bundleListViewController] autorelease];
    
    self.viewController = bundleListViewController;
    self.window.rootViewController = nc;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
