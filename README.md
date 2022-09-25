Docker image having hdfs, yarn, Spark for testing on local laptop. 
Spark is configured to work with Yarn.
Please use below command to start the container 

If Using Only On Local
========================
- To create image -> docker build . 
- Get image is from this command -> docker image ls 
- To start container -> docker run -p 9870:9870  -p 8088:8088  -p 4040:4040 -p 18080:18080  -d  <imageId>    tail -f /dev/null
- Get continer id -> docker ps 
- Log in to container -> docker exec -it <containerId> bash 
- Chech UIs from local laptop ->  localhost:9870 (name mode UI) , localhost:8088 (yarn UI) 

