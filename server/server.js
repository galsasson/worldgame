
function Event(id, key, pressed)
{
	this.id = id;
	this.key = key;
	this.pressed = pressed;
}

function ChunkOfWords(_cid, _string, _x, _y)
{
	this.cid = _cid;
	this.string = _string;
	this.x = _x;
	this.y = _y;
}

function Creature()
{
	this.socket = null;
	this.id = -1;
	this.type = -1;
	this.x = 0;
	this.y = 0;
	this.rotation = 0;
	this.size = 0;
	this.arms = 0;
	this.r = 0;
	this.g = 0;
	this.b = 0;

	this.init = function(id, socket, type, x, y, rotation, size, arms, r, g, b)
	{
		this.id = id;
		this.socket = socket;
		this.type = type;
		this.x = x;
		this.y = y;
		this.rotation = rotation;
		this.size = size;
		this.arms = arms;
		this.r = r;
		this.g = g;
		this.b = b;
	}
}

var app = require('http').createServer(httpHandler),
	io = require('socket.io').listen(app),
	fs = require('fs');

function httpHandler(req, res) {
	console.log(req.url);

	var file;

	if (req.url == '/')
		file = __dirname + '/client/index.html';
	else
		file = __dirname + '/client' + req.url;

	fs.readFile(file, function(err, data) {
		if (err) {
			res.writeHead(500);
			return res.end('Error loading index.html');
		}

		res.writeHead(200);
		res.end(data);
	});
}

var creatures = {};
var words = [];
//var events = {};
var clientsNum = 0;
var frameNum = 0;

words.push(new ChunkOfWords(0, "hello from server", 0, 0));

app.listen(80);

io.sockets.on('connection', function(socket) {

	var id = clientsNum++;

	var newC = new Creature();
	newC.init(id, 
		socket, 
		Math.floor(Math.random()*2), 
		0, 0, 0,
		Math.random()*5+5, 
		Math.random()*20+5,
		230, 20, 50);

	socket.emit('init', { 
		'cid' : newC.id,
		'type' : newC.type,
		'x' : newC.x,
		'y' : newC.y,
		'size' : newC.size,
		'arms' : newC.arms,
		'r' : newC.r,
		'g' : newC.g,
		'b' : newC.b
	});

	console.log("new client with ID:" + newC.id);

	// send all existing creatures
	for (var c in creatures)
	{
		var cr = creatures[c];
		socket.emit('new_creature', 
			{'cid':cr.id, 'type':cr.type, 'x':cr.x, 'y':cr.y, 'size':cr.size, 'arms':cr.arms, 'r':cr.r, 'g':cr.g, 'b':cr.b});		
	}

	// add current creature
	creatures[id] = newC;

	socket.on('disconnect', function() {
		console.log("connection terminated");
		var delCreature;

		// find out what creature to delete
		for (var c in creatures)
		{
			if (creatures[c].socket == socket)
			{
				delCreature = c;
				break;
			}
		}

		delete creatures[delCreature];

		// tell all others that the creature is gone
		for (var c in creatures)
		{
			console.log("sending del_creature to creature: " + c);
			
			creatures[c].socket.emit('del_creature', {'cid':delCreature});
		}
	});

	socket.on('key_press', function(data) {
		console.log("got key press: " + data.cid + " data: " + data.key);
		for (var c in creatures)
		{
			creatures[c].socket.emit('key_press', data);
		}
	});

	socket.on('key_release', function(data) {
		console.log("got key release: " + data.cid + " data: " + data.key);
		for (var c in creatures)
		{
			creatures[c].socket.emit('key_release', data);
		}
	});

	socket.on('new_creature', function(data) {
		console.log("got new creature");
		for (var c in creatures)
		{
			if (creatures[c].socket != socket)
				creatures[c].socket.emit('new_creature', data);
		}
	});

	socket.on('set_position', function(data) {
		creatures[data.cid].x = data.x;
		creatures[data.cid].y = data.y;
		creatures[data.cid].rotation = data.rotation;

		for (var c in creatures)
		{
			creatures[c].socket.emit('update_pos', data);
		}
	});

	socket.on('new_word', function(data) {
//		var chunk = new ChunkOfWords(data.chunk.cid, data.chunk.string, data.x, data.y);
		words.push(data.chunk);

		for (var c in creatures)
		{
			creatures[c].socket.emit('take_word', {'chunk':data.chunk});
		}
	});

	socket.on('get_all_words', function(data) {
		creatures[data.cid].socket.emit('take_words', {'chunks':words});
	});

});

/*
setInterval(function() {
	if (creatures.length > 0)
	{
		frameNum++;
		for (var c in creatures)
		{
			creatures[c].socket.emit('next_frame', {'frame':frameNum});
		}
	}
}, 30);
*/




