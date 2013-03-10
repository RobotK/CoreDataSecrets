//
//  main.m
//  XcodePicsDataLoader
//
//  Created by Kris Markel on 3/5/13.
//  Copyright (c) 2013 Kris Markel. See License.txt for details.
//

#import "ROBKDatabaseUpdater.h"

int main(int argc, const char * argv[])
{

	@autoreleasepool {

		ROBKDatabaseUpdater *databaseUpdater = [ROBKDatabaseUpdater new];
		NSURL *XcodePicsURL = [NSURL URLWithString:@"http://picasaweb.google.com/data/feed/api/all?kind=photo&q=xcode&alt=json"];
		[databaseUpdater synchronousLoadJSONFromURL:XcodePicsURL];

	}
    return 0;
}

