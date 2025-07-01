extends Node

func _ready():
    var http_server = HTTPRequest.new()
    add_child(http_server)
    http_server.connect("request_completed", self, "_on_request_completed")
    print("Server ready to handle multi-language compilation requests")

func _on_request_completed(result, response_code, headers, body):
    var json = JSON.parse(body.get_string_from_utf8())
    if json.error == OK:
        print("Compilation result: ", json.result)
    else:
        print("Error parsing response")
