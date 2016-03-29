#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "localhost";
    .port = "8080";

    .connect_timeout = 600s;        # Wait a maximum of 600s for response from web-server backend
    .first_byte_timeout = 600s;     # Wait a maximum of 600s TTFB from web-server backend
    .between_bytes_timeout = 600s;  # Wait a maximum of 600s between each bytes sent from web-server backend
}

acl purge {
    "localhost";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.
    
    # This is here to avoid an "Unused acl purge" error on initial start (before other vcl files using it exist)
    if (client.ip !~ purge) {}
    
    if (! req.http.Host) {
      return (synth(405, "Varnish needs a host header in the request for vhost processing rules."));
    }
}

# load list of includes used to include site specific vcl files
include "/etc/varnish/includes.vcl";

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
}
