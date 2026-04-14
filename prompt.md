**Backend requirments:**

Intension of this application is to visualize the backend achitecture and analyize and identify failure points, understand the archtechture, simulate the high traffic senarios exprement various topology.

Every project may have many topologies

Every topology may have multiple Components

Components type:
servers(standalone server, VM from kuberneties)
nodes(kuberneties)
queues
Database
cache
CDN
etc (suggest me other components that can be in the backend setup)

Servers component has infra configration and API level configration, all the endpoints in the codebase will be feed into the server component when server is clicked and opened it will give me the list of endpoints . each endpoint has the db and cache calls happening in that endpoint, this details on the database call and cache calls are feed by the mcp server from the developers IDE to our system. this must have the details on the cache tts and help to simulate high traffic senarios. each endpoint will hold the details on what all services it uses and what all data model it intracts with

Database component has the metadata on the data models in the code base which is fetched and uploaded with help of mcp. with this when used clicks on the database he will be taken to a page like models page in power bi where the models are visualized and its connections are established. this will be a view only page where the current datamodel of the system is visualized and details on each field is provided. the models are connected with ratios like user:post 1:200. with this data the cost that will be happening to the database storage cost can be simulated.

Cache component should have the details on what all type of cache keys are there and where it is used in which endpoints with its tts and other details

queue component will have the details on which endpoint uses as producers and which consumer listens to it. and it should have the detail on the partition and queuing strategy.


