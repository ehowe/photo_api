Upload photos using a simple Sinatra application.

* Attributes are sent in the request body, and a JSON response is returned.  
* Errors will be returned if
  * the image size exceeds 5000 pixels in either direction
  * the image size is under 350 pixels in either direction
  * the image is not a JPEG or PNG
  * the specified image name is not unique
  * name or upa_id are not specified
* Endpoints exist for retrieving all images, or a single image
  * Pagination exists for the `all` endpoint via `page` and `per_page` params
  * Link header is set per RFC
