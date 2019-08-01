Please note, this repo creates the current ohif viewer on ref.management.
It is a fork of the repo from 2018 which was fixed and changed for our needs.
As of 2019 the documentation is still online for version 1.0 however they 
have switched to react in version 2.0. There is also documentation within the repo.
In order to build for ref.management use the command: 
METEOR_PACKAGE_DIRS="../../Packages" meteor-build-client ../myOutputFolder -u localhost:3000

# Viewers
This repo contains the OHIF DICOM Viewer and Lesion Tracker, and various shared meteor packages.

Documentation is available here: http://docs.ohif.org/

### Demos
[OHIF Viewer](http://viewer.ohif.org/) - A general-purpose radiology viewer with a variety of tools exposed.

[Lesion Tracker](http://lesiontracker.ohif.org/) - A prototype viewer focused on oncology metrics.

Community
---------

Have questions?  Try posting on our [google groups forum](https://groups.google.com/forum/#!forum/cornerstone-platform).

### Docker usage
Following the instructions below, the docker image will listen for DICOM connections on port 4242, and for web traffic on port 8042. The default username for the web interface is `orthanc`, and the password is `orthanc`.
#### Temporary data storage
````
docker run --rm -p 4242:4242 -p 8042:8042 jodogne/orthanc-plugins
````

#### Persistent data storage
1. Create a persistant data volume for Orthanc to use

    ````
    docker create --name sampledata -v /sampledata jodogne/orthanc-plugins
    ````
    
    **Note: On Windows, you need to use an absolute path for the data volume, like so:**
    
    ````
    docker create --name sampledata -v '//C/Users/erik/sampledata' jodogne/orthanc-plugins
    ````

2. Run Orthanc from Docker with the data volume attached

    ````
    docker run --volumes-from sampledata -p 4242:4242 -p 8042:8042 jodogne/orthanc-plugins
    ````

3. Upload your data and it will be persisted
