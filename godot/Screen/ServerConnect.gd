extends Node2D
const KEY := "defaultkey"
onready var client := Nakama.create_client(KEY, "127.0.0.1", 7350, "http")
var session : NakamaSession
onready var socket := Nakama.create_socket_from(client)
var match_id

func _ready():
	var lobby := get_parent().get_node(".");
	var custom_id = lobby.moralis.User.current().get("ethAddress")
	session = yield(client.authenticate_custom_async(custom_id), "completed")
	if session.is_exception():
		print("An error occured: %s" % session)
		return
	print("Successfully authenticated: %s" % session)
	_connect_to_server_async()
	socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	socket.connect("received_match_state", self, "_on_match_state")


func _connect_to_server_async():
	print("_connect_to_server_async");
	var connected : NakamaAsyncResult = yield(socket.connect_async(session), "completed")
	if connected.is_exception():
		print("An error occured: %s" % connected)
		return
	print("Socket connected.")
	


func _on_PlayGame_pressed():
	var query = "*"
	var min_count = 2
	var max_count = 2
	var matchmaker_ticket : NakamaRTAPI.MatchmakerTicket = yield(
	  socket.add_matchmaker_async(query, min_count, max_count),
	  "completed"
	)
	if matchmaker_ticket.is_exception():
		print("An error occured: %s" % matchmaker_ticket)
		return
	print("Got ticket: %s" % [matchmaker_ticket])


func _on_matchmaker_matched(p_matched : NakamaRTAPI.MatchmakerMatched):
	print("Received MatchmakerMatched message: %s" % [p_matched])
	var joined_match : NakamaRTAPI.Match = yield(socket.join_matched_async(p_matched), "completed")
	if joined_match.is_exception():
		print("An error occured: %s" % joined_match)
		return
	print("Joined match: %s" % [joined_match])
	match_id = joined_match.match_id

func _on_match_state(p_state : NakamaRTAPI.MatchData):
	print("Received match state with opcode %s, data %s" % [p_state.op_code, parse_json(p_state.data)])


func _on_Button_pressed():
	var op_code = 1
	var new_state = {"hello": "world"}
	socket.send_match_state_async(match_id, op_code, JSON.print(new_state))
