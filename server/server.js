
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

function Creature(id, socket, type, xPos, yPos, xVel, yVel, rotation, size, arms, h, s, b)
{
	this.socket = socket;
	this.id = id;
	this.type = type;
	this.x = xPos;
	this.y = yPos;
	this.xVel = xVel;
	this.yVel = yVel;
	this.rotation = rotation;
	this.size = size;
	this.arms = arms;
	this.h = h;
	this.s = s;
	this.b = b;
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

	var cY;
	var arms, mass;
	var cType = clientsNum%3;

	if (cType == 0 || cType == 1) {
		mass = Math.random()*20+5;
		arms = Math.floor(Math.random()*20)+5;		
		cY = 2500;
	}
	else {
		mass = 9;
		arms = Math.floor(Math.random()*11)+4;
		cY = 1000;
	}

	var newC = new Creature(id, socket, cType, 1450+Math.random()*100, cY, 0, 0, 0, mass, arms, 
						Math.floor(Math.random()*360),
						50, 100);


	socket.emit('init', { 
		'cid' : newC.id,
		'type' : newC.type,
		'x' : newC.x,
		'y' : newC.y,
		'size' : newC.size,
		'arms' : newC.arms,
		'h' : newC.h,
		's' : newC.s,
		'b' : newC.b
	});

	console.log("new client with ID:" + newC.id);

	// send all existing creatures
	for (var c in creatures)
	{
		var cr = creatures[c];
		socket.emit('new_creature', 
			{'cid':cr.id, 'type':cr.type, 'x':cr.x, 'y':cr.y, 'size':cr.size, 'arms':cr.arms, 'h':cr.h, 's':cr.s, 'b':cr.b});		
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

	socket.on('set_params', function(data) {
		creatures[data.cid].x = data.xPos;
		creatures[data.cid].y = data.yPos;
		creatures[data.cid].xVel = data.xVel;
		creatures[data.cid].yVel = data.yVel;
		creatures[data.cid].rotation = data.rotation;

		for (var c in creatures)
		{
			creatures[c].socket.emit('update_params', data);
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




