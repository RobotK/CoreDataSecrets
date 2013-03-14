To get this working you need to init an update the submodules.

	 git submodule update --init --recursive
	 
Brief descriptions of each group:

 * Core - The shared Core Data (and networking) code used by the other projects.
 * Preloading - Creating a pre-populated data store using a command line app.
 * Deleting - Deleting the data store while the app is running.