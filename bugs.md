Caddy still not passing the containers across over the reverse proxy. 
it is reachable internally, it returns the html page. 
- docker exec observability-caddy wget -qO- http://observability-grafana:3000 
