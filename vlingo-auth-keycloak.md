# Vlingo-auth overkeycloak

## docker  
To set up your docker world, perform the follwoing steps:
- `docker-compose up --build --rm --detach --renew-anon-volumes`  
Baseline keycloak docker image
- `docker exec -i keycloak  /bin/bash  -c "cd /configure; ./vlingo-auth-setup.sh"`   
Sets up the `vlingo-internal` realm to support vlingo-auth scenarios
- `./join.sh` (`docker exec -it keycloak  bash $*`)  
To access the running container  

## keycloak
- login to keycloak  
http://localhost:8080/auth  
`admin` / `kalele#luna`


## Under the hood
In addition to the default `master` realm inherit with any keycloak docker container, the `docker exec` sets up the following:
1. A realm, 'vlingo-internal'   
This realm supports the authentication use cases for vlingo-auth. 
   * A user for the realm  
    `system@kalele.io.com` / `Limahana#Kalele`  

## Docker cleanup
Sometimes your docker world needs to be reset.  
1.  `docker ps -a |grep "keycloak" | awk '{print $1}' |xargs docker stop`  
Acquire the container ID's and `docker stop`
1. `docker ps -a |grep "keycloak" | awk '{print $1}' |xargs docker rm`  
Acquire the container ID's and `docker rm`
1. `docker rm <container-id>`