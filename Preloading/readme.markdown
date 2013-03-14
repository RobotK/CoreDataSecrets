# Overview

The project demonstrates how to create a command line Mac application to provide a pre-populated data store for an iPhone app.

# Assumptions

 * All projects live in the same workspace.
 * You have an existing iPhone app with code to update the database.
 * You're using Xcode 4.6. These ideas should work in other versions of Xcode, but the details may vary.
 
# The Approach

 1. Create a new static library project to host the code shared between the apps.
 1. This project will have three targets:
	1. The iOS library
 	1. The models bundle
	1. The Mac library
 1. Create a new project for the command line app that builds a preloaded data store.
 1. Update the iOS app to pull the data store into its app bundle.
 
# The Library Project
 
This project holds three targets, two libraries and an application bundle.
 
## The Core Data Library
 
 1. Create a new iOS / Framework & Library / Cocoa Touch Static Library project in your workspace.
 1. Move over any files that are part of loading the database into the static library.
 	* If there are any files that are necessary, but aren't directly related to Core Data operations, it's a good idea to put them in their own library project. (Networking, for example.)
	* Make sure the files you need are included in the compile sources build phase.
 1. Add any necessary headers to the copy files build phase.
 	* Destination: Products Directory
 	* Subpath: include/${PRODUCT_NAME}
	* You may not know exactly which headers you need to export at this point. Don't worry, it's easy to change this list as needed.
 1. Build the static library scheme.
 
## The Models Bundle

Adapted from [this Stack Overflow answer](http://stackoverflow.com/a/4610584/458922). Mostly unchanged, except for changes needed to make it work with Xcode 4.6.

 1. Add a new OS X / Framework & Library / Bundle target to your project.
 1. Move your xcdatamodel file into the project and add it to the compile sources build phase.
 1. In your static library build scheme (which should have been created as part of setting up the static library), add the models target to the build action. 
 	* This technically isn't necessary, but but it helps ensure that the model file gets rebuilt as part of building the static library.
 	<img src="http://cl.ly/image/3O2n1l0r3d1k/Screen%20Shot%202013-03-14%20at%206.17.46%20.png">
 1. Build the bundle scheme.
 
### Loading the Models File

To initialize your Core Data stack, you'll need to load instantiate an NSManagedObjectModel from the model file. This code now probably lives in your Core Data library.
 
Here's the code to get the URL of the model file. This works for both you're iPhone app and the command line app we'll be building later.
 
 	NSURL *modelBundleURL = [[NSBundle mainBundle] URLForResource:@"XcodePicsModels" withExtension:@"bundle"];
	NSBundle *modelBundle = [NSBundle bundleWithURL:modelBundleURL];
	NSURL *modelURL = [modelBundle URLForResource:@"XcodePics" withExtension:@"momd"];
 
Adjust the code in your Core Data stack that locates the model file appropriately.
 
## The Mac Library

 1. Add a new OS X / Framework & Library / Cocoa Framework target. 
 1. Duplicate the compile sources build phase from the static library project.
 	* It is not necessary to add any headers to the copy headers build phase.
 1. In the build scheme, add the models target to the build action.
 	* (See the note regarding this analogous step in the section above.)
 1. Build the framework scheme.
 	
# Getting Your App Running Again

Now that we've ripped a bunch of code from your app, it's important to make sure we can get the original application back into a working state. Here are the steps to wiring things back up.
 
 1. Add the static library to the link binary with libraries build phase for your app.
 1. In the build action for your app's scheme, add both the static library and the bundle targets.
 	<img src="http://f.cl.ly/items/3o1I1F272M3t282H1r0P/Screen%20Shot%202013-03-14%20at%206.36.02%20.png">
 1. Find your app's derived data folder
 	* Look in the Locations tab in preferences.
 1. Go to the Build/Products/Debug folder and find the bundle file.
 	* The bundle should be the same whether you're doing a debug or release build, but if you're paranoid, choose the bundle file from the release folder. (You'll have to have done a release build of the bundle scheme or something that depends on it first.)
 1. Drag the bundle file into your app's project.
 	* **Do not** select the "Copy items into destination group's folder" checkbox!
 	* **Do** add the bundle to your app's target.
 1. Select the bundle file in the project navigator, and in the file inspector (in the utilities pane), change the location to "Relative to Build Products". <br>
 	<img src="http://f.cl.ly/items/04281u321e3e1m0a400R/Screen%20Shot%202013-03-14%20at%206.49.13%20.png">
 1. Build and run the app and make sure everything is working properly.
 
# Building The Command Line App

The command line application will build a populated data store for your main application to ship with. I'll be referring to this app as the "data loader" app below.

 1. Create a new OS X / Application / Command Line Tool project in your workspace.
 1. Choose a type of Core Foundation rather than Core Data.
 1. Once the project is ready, add the framework target (the dylib from the library project) to the link binary with libraries build phase.
 1. Add the models bundle as a resource using the same steps as adding it to your main application.
 1. Update the data loader app's scheme's build action to include the library framework and the models bundle targets.
 	* This is nearly identical to how it was done in the main application, but you'll chose the OS X framework target instead of the static library one.
 1. Update the user header search paths build setting to include the framework headers.
 	* ${BUILT\_PRODUCTS\_DIR}/usr/local/include
 1. Add code to the data loader app's main function to populate the data store using your preferred source.
 1. Build and run the app.
 	* At this point, the app should build, but doesn't run successfully. 

## Modifications to the Core Data library

You'll almost certainly need to update your core data library to make it run properly with the command line app. Here are the changes you'll likely need.
 
### The Data Store file

You don't want to put the data store in the documents or library file. Instead, it needs to live alongside the application. This is necessary so we can include it as a resource in the main application's bundle. Instead of using URLsForDirectory or an analogous method, use NSFileManager's currentDirectoryPath method.
 
The TARGET\_OS\_IPHONE is a useful macro for separating out the code that needs to be different for the command line app. (Note that this gets set to 0 for OS X builds, so using #ifdef doesn't work as you'd expect. Use #if instead.)
 
	+ (NSURL *)databaseURL
	{
	#if TARGET_OS_IPHONE
		NSArray *libraryDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
		NSAssert([libraryDirectories count] > 0, @"There should be at least one library directory!");
		NSURL *libraryURL = libraryDirectories[0];
	#else
		NSString *currentDirectoryPath = [[NSFileManager defaultManager] currentDirectoryPath];
		NSURL *libraryURL = [NSURL fileURLWithPath:currentDirectoryPath];
	#endif

		NSURL *dataDirectoryURL = [libraryURL URLByAppendingPathComponent:@"data"];
		NSError __autoreleasing *dataDirectoryCreationError;
		BOOL dataDirectoryCreated = [[NSFileManager defaultManager] createDirectoryAtURL:dataDirectoryURL withIntermediateDirectories:YES attributes:nil error:&dataDirectoryCreationError];
		if (!dataDirectoryCreated) {
			NSLog(@"Could not create the data directory. %@", dataDirectoryCreationError);
		}
		NSURL *databaseURL = [dataDirectoryURL URLByAppendingPathComponent:@"XcodePics.sqlite"];

		return databaseURL;
	}

### Adding Data Synchronously

Your app probably populates the database asynchronously, which is a great thing. However, asynchronous operations and command line apps don't play well together. My general approach for this is to refactor the data loading code so it can operate synchronously or asynchronously and then provide methods for doing both.

Precisely how you go about this depends on the details of your app, but you probably need to replace asynchronous network operations with synchronous ones. Also, any code that operates in a block that's run asynchronously needs to be refactored into a method and sync and async calls provided. (One of the nice things about command line apps is that it's okay, in fact it's _necessary_, to block on the main thread.)

# Using the Pre-populated Data Store

Now that your command line app is running smoothly, it should be adding a data store file parallel to the executable. If you use the code above it will place it within a data subdirectory. The final steps are to include the data store as a resource in your main application's bundle, and then use it at the appropriate time.
 
## Including the Data store

This is just like adding the models bundle to your main app. Drag the data store file from its place within the derived data folder into your app's project. Do not select the checkbox to copy the file, but do select the checkbox to include it in the app's target.
 
Then select the file in the project navigator, and in the file inspector change the location to "Relative to Build Products".
 
## Using the Data Store

The final step is to copy the data store from your application's bundle to its appropriate location in the sandbox, if necessary.
 
Before you initialize your Core Data stack, do the following.
 
 1. Check to see if the data store file already exists in the application's sandbox.
 2. If it does not, copy the file from the app bundle into the appropriate location.
 
In the didFinishLaunchingWithOptions method, include something like this:

	//If there's no database file in the data directory, copy the one from the bundle.
	NSURL *databaseURL = [DCTCoreDataStack databaseURL];
	// Intentionally ignoring the error info here.
	if (![databaseURL checkResourceIsReachableAndReturnError:NULL]) { 
		NSURL *includedDatabaseURL = [[NSBundle mainBundle] URLForResource:@"XcodePics" withExtension:@"sqlite"];
		NSError __autoreleasing *fileCopyError;
		BOOL fileCopied = [[NSFileManager defaultManager] copyItemAtURL:includedDatabaseURL toURL:databaseURL error:&fileCopyError];
		if (!fileCopied) {
			NSLog(@"Error copying file. %@", fileCopyError);
		}
	}

	self.coreDataStack = [DCTCoreDataStack sharedCoreDataStack];
	
# Updating the Data Store

Now, whenever you need or want to update your pre-populated data store, simply run the data loader scheme in the workspace. It should pick up any changes to your Core Data library and models, compile and run, and place the update data store file where the main application will pick it up to include in the app bundle.