
var socket;
console.log("sketch id: " + getProcessingSketchId());
var pjs;
var myCid;
var words;

function gimmeAllTheWords()
{
	socket.emit('get_all_words', 
	{
		'cid':mySid
	});

	console.log("sending data: " + words);
	pjs.serverTakeData(words);
};




function initClient()
{
	pjs = Processing.getInstanceById(getProcessingSketchId());
 	socket = io.connect('ws://localhost:80');

 	words = new pjs.ArrayList();
	words.add(new pjs.ChunkOfWords(new pjs.PVector(0,0), "h", -1));

 	socket.on('init', function(data) {
 		mySid = data.cid;
		console.log("client ID: " + mySid);
		pjs.initSelf(mySid, data.type, data.x, data.y, data.size, data.arms, data.r, data.g, data.b);
		pjs.setJavaScript(parent);
	});

	socket.on('key_press', function (data) {
  		pjs.serverKeyPressed(data.cid, data.key);
	});

	socket.on('key_release', function (data) {
  		pjs.serverKeyReleased(data.cid, data.key);
	});

	socket.on('new_creature', function (data) {
		pjs.serverAddNewCreature(data.cid, data.type, data.x, data.y, data.size, data.arms, data.r, data.g, data.b);
	});

	socket.on('del_creature', function (data) {
		console.log("got remove creature " + data.cid);
		pjs.serverRemoveCreature(data.cid);
	});

	socket.on('update_pos', function (data) {
		pjs.serverUpdateCreaturePos(data.cid, data.x, data.y, data.rotation);
	});

	socket.on('next_frame', function (data) {
		pjs.serverNextFrame();
	});

	socket.on('take_words', function (data) {
		pjs.serverTakeData(data);
	});

	setInterval(function() {
		pjs.serverGimmeYourPosition();
	}, 200);
}

function keyPress(cid, key)
{
	//console.log("key pressed["+cid+"]: " + key);
	socket.emit('key_press', {'cid':cid, 'key' : key });
}

function keyRelease(cid, key)
{
	//console.log("key released["+cid+"]: " + key);
	socket.emit('key_release', {'cid':cid, 'key' : key} );
}

function updateSelfPosition(cid, x, y, rotation)
{
	socket.emit('set_position', {'cid':cid, 'x':x, 'y':y, 'rotation':rotation});
};

function addNewCreature(cid, type, x, y, size, arms, r, g, b)
{
	socket.emit('new_creature',
		{
			'cid':cid,
			'type':type,
			'x':x,
			'y':y,
			'size':size,
			'arms':arms,
			'r':r,
			'g':g,
			'b':b
		});
};

function takeChunkOfWords(chunk)
{
	socket.emit('new_word', {'cid':mySid, 'x':chunk.pos.x, 'y':chunk.pos.y, "str": chunk.str});
}

window.onload = function() {
	setTimeout(initClient, 2000);
};


