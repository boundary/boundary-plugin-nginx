# nginx Graphdat Plugin

### Tracks the following metrics for [nginx](http://nginx.org) (from the [nginx HttpStubStatusModule](http://wiki.nginx.org/HttpStubStatusModule)):

	* active connections
		* proc - Connections with Nginx reading request body, processing request or writing response to client.
		* read - Connections with Nginx reading request headers.
		* wait - Keep-alive connections with Nginx in wait state
		* active - Total active connections
	* connections per second
		* handled - Connections handled by Nginx per second
		* not-handled - Connections accepted, but not handled by Nginx per second.
	* requests per second
		* requests - Requests handled by Nginx per second.
	* requests per connection
		* requests - Average number of requests per connections handled by Nginx.

### Pre Reqs

To get statistics from nginx, it needs to built with the [nginx HttpStubStatusModule](http://wiki.nginx.org/HttpStubStatusModule).  If you used a package manager to install nginx, it should be compiled by default, if you built nginx yourself, you may need to recompile it.  To check if your nginx has been build with the [nginx HttpStubStatusModule](http://wiki.nginx.org/HttpStubStatusModule), you need to run:

	nginx -V    # this wil display the modules that are compiled in your version of nginx

If the string `--with-http_stub_status_module` is in the output, you are good to go.  If the string is not there, you will need to [recompile nginx](http://wiki.nginx.org/Install) and add the module in.

Next you need to tell nginx where to host the statistics page.  Edit your default vhost file (or whatever .conf file you are using) and add in the folling configuration in your server {} block:

	location /nginx_status {
		stub_status on;    # activate stub_status module
		access_log off;    # do not log graphdat polling the endpoint
		allow 127.0.0.1;   # restrict access to local only
		deny all;
	}

Once you make the update, reload your nginx configuration
	`sudo service nginx reload`

### Installation & Configuration

	* The URL endpoint of the nginx statistics module, the default is `http://127.0.0.1/nginx_status`.
	* The username for the endpoint if password protected
	* The password for the endpoint if password protected