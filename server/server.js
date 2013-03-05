
function Creature()
{
	this.socket = null;
	this.id = -1;
	this.x = 0;
	this.y = 0;
	this.size = 0;
	this.legs = 0;

	this.init = function(id, socket)
	{
		this.id = id;
		this.socket = socket;
		this.position = {'x':0, 'y':0};
		this.size = 5;
		this.legs = 10;
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
var clientsNum = 0;

app.listen(80);

io.sockets.on('connection', function(socket) {
	console.log("new client");

	var id = clientsNum++;

	var newC = new Creature();
	newC.init(id, socket);



	socket.emit('init', { 'cid' : id});

	// send all existing creatures
	for (var c in creatures)
	{
		var cr = creatures[c];
		socket.emit('new_creature', 
			{'cid':c, 'x':cr.x, 'y':cr.y, 'size':cr.size, 'legs':cr.legs});		
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

		for (var c in creatures)
		{
			creatures[c].socket.emit('update_pos', data);
		}
	})

});




