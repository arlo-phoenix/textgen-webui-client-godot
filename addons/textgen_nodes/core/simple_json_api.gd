extends RefCounted
class_name SimpleJsonApi

var http: HTTPClient
var _host: String
var _port: int

const POLL_DELAY_START=50 #will multiply by 2 each attempt
const MAX_ATTEMPTS=5

func ensure_connected() -> Error:
	http.poll()
	if http.get_status()==HTTPClient.STATUS_CONNECTED:
		return OK

	var err := http.connect_to_host(_host, _port) # Connect to host/port.
	if err!=OK:
		return err

	# Wait until resolved and connected.
	var delay:=POLL_DELAY_START
	var attempt:=0
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		if attempt>=MAX_ATTEMPTS:
			return ERR_CANT_CONNECT
		http.poll()
		OS.delay_msec(delay)
		delay*=2
		attempt+=1

	return OK if http.get_status() == HTTPClient.STATUS_CONNECTED else ERR_CANT_CONNECT

func _disconnect_host():
	http.close()

func _init(host: String, port: int):
	_host=host
	_port=port
	http = HTTPClient.new()

## called in all method right after sending request to collect and decode chunks
func _handle_response(dont_handle_response: bool=false):
	var delay:=POLL_DELAY_START
	var attempt:=0
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		if attempt>=MAX_ATTEMPTS:
			printerr("No response after ", pow(POLL_DELAY_START, MAX_ATTEMPTS+1)-1, "ms. Returning empty json")
			return {}
		OS.delay_msec(delay)
		http.poll()
		delay*=2
		attempt+=1

	if http.get_status() not in [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]:
		return ERR_QUERY_FAILED

	if http.has_response():
		var response_headers := http.get_response_headers_as_dictionary() # Get response headers.
		var rb := PackedByteArray() # Array that will hold the data.
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			var chunk := http.read_response_body_chunk()
			if chunk.size() == 0:
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer.

		_disconnect_host()
		if dont_handle_response:
			return
		var text := rb.get_string_from_utf8()
		var json := JSON.new()
		json.parse(text)
		if json.data:
			return json.data
		else:
			printerr("Empty response")
			return {}

	else:
		printerr("No response")
		_disconnect_host()
		return {}


func request(method: HTTPClient.Method, endpoint: String, headers: Array[String]=[], request_data: Dictionary={}, no_response: bool=false):
	var err:=ensure_connected()
	if err != OK:
		printerr("Error: %s Couldn't post, can't connect to %s" % [err, _host])
		if not no_response:
			return {}

	err = http.request(method, endpoint, headers, JSON.stringify(request_data))
	if err != OK:
		printerr("Error: %s Request failed for %s with %s" % [err, endpoint, request_data])
	if no_response:
		_handle_response(no_response)
	else:
		return _handle_response(no_response)
